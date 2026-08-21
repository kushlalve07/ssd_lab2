-- Create Database:
CREATE DATABASE 2026201061_delivery;

-- Using database
USE 2026201061_delivery

-- Creating Staging Table:
CREATE TABLE 2026201061_delivery_data_pins_stg

-- TASK 1:
-- Creating Target Table: 2026201061_deliverstatistics
CREATE TABLE 2026201061_deliverystatistics (
-- Grouping Keys
    PINCode VARCHAR(10),
    PartnerID VARCHAR(50),
    MonthofOrder INT,
    YearofOrder INT,

    -- Counts
    TotalOrders INT,
    TotalPendingAssignment INT,
    TotalAccepted INT,
    TotalHeadingforPickup INT,
    TotalArrivedatPickup INT,
    TotalPickedUp INT,
    TotalOutforDelivery INT,
    TotalArrivedatDoorStep INT,
    TotalDelivered INT,
    TotalDropped INT,
    TotalDelayedatPickup INT,
    TotalDeliveryFailed INT,
    TotalReturningtoStore INT,
    TotalReturned INT,
    TotalCancelled INT,

    -- Averages (in minutes)
    TimetoAccept DECIMAL(10, 2),
    TimetoPickup DECIMAL(10, 2),
    TimetoArriveatDoorStep DECIMAL(10, 2),
    TimetoDeliver DECIMAL(10, 2),
    
    -- Composite Primary Key
    PRIMARY KEY (PINCode, PartnerID, MonthofOrder, YearofOrder)
);

-- TASK 2:
-- Populate 2026201061_deliverystatistics using a stored procedure:
DROP PROCEDURE IF EXISTS 2026201061_PopulateDeliveryStatistics;

DELIMITER //

CREATE PROCEDURE 2026201061_PopulateDeliveryStatistics()
BEGIN
    -- Declarations for Cursor variables
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_pincode VARCHAR(10);
    DECLARE v_partner_id VARCHAR(50);
    DECLARE v_month INT;
    DECLARE v_year INT;
    DECLARE v_time_to_accept DECIMAL(10,2);
    DECLARE v_time_to_pickup DECIMAL(10,2);
    DECLARE v_time_to_doorstep DECIMAL(10,2);
    DECLARE v_time_to_deliver DECIMAL(10,2);

    -- Declare Explicit Cursor for sequence-dependent time metrics
    DECLARE cur_time_metrics CURSOR FOR
        SELECT 
            t_main.PINCode,
            t_main.PartnerID,
            MONTH(COALESCE(MIN(CASE WHEN t_main.Status = 'PendingAssignment' THEN t_main.Timestamp END), MIN(t_main.Timestamp))) AS MonthofOrder,
            YEAR(COALESCE(MIN(CASE WHEN t_main.Status = 'PendingAssignment' THEN t_main.Timestamp END), MIN(t_main.Timestamp))) AS YearofOrder,
            
            -- Time to Accept: PendingAssignment -> Accepted
            AVG(TIMESTAMPDIFF(MINUTE, 
                t_pending.Timestamp, 
                t_accepted.Timestamp)) AS TimetoAccept,
                
            -- Time to Pickup: Accepted -> PickedUp
            AVG(TIMESTAMPDIFF(MINUTE, 
                t_accepted.Timestamp, 
                t_pickup.Timestamp)) AS TimetoPickup,
                
            -- Time to Arrive at Doorstep: PickedUp -> ArrivedatDoorStep
            AVG(TIMESTAMPDIFF(MINUTE, 
                t_pickup.Timestamp, 
                t_doorstep.Timestamp)) AS TimetoArriveatDoorStep,
                
            -- Time to Deliver: First PendingAssignment -> Delivered
            AVG(TIMESTAMPDIFF(MINUTE, 
                t_pending.Timestamp, 
                t_delivered.Timestamp)) AS TimetoDeliver

        FROM `2026201061_delivery_data_pins_stg` t_main
        LEFT JOIN (
            SELECT OrderID, MIN(Timestamp) AS Timestamp 
            FROM `2026201061_delivery_data_pins_stg` 
            WHERE Status = 'PendingAssignment' 
            GROUP BY OrderID
        ) t_pending ON t_main.OrderID = t_pending.OrderID
        
        LEFT JOIN (
            SELECT OrderID, MIN(Timestamp) AS Timestamp 
            FROM `2026201061_delivery_data_pins_stg` 
            WHERE Status = 'Accepted' 
            GROUP BY OrderID
        ) t_accepted ON t_main.OrderID = t_accepted.OrderID
        
        LEFT JOIN (
            SELECT OrderID, MIN(Timestamp) AS Timestamp 
            FROM `2026201061_delivery_data_pins_stg` 
            WHERE Status = 'PickedUp' 
            GROUP BY OrderID
        ) t_pickup ON t_main.OrderID = t_pickup.OrderID
        
        LEFT JOIN (
            SELECT OrderID, MIN(Timestamp) AS Timestamp 
            FROM `2026201061_delivery_data_pins_stg` 
            WHERE Status = 'ArrivedatDoorStep' 
            GROUP BY OrderID
        ) t_doorstep ON t_main.OrderID = t_doorstep.OrderID
        
        LEFT JOIN (
            SELECT OrderID, MIN(Timestamp) AS Timestamp 
            FROM `2026201061_delivery_data_pins_stg` 
            WHERE Status = 'Delivered' 
            GROUP BY OrderID
        ) t_delivered ON t_main.OrderID = t_delivered.OrderID

        GROUP BY t_main.PINCode, t_main.PartnerID, MONTH(t_main.Timestamp), YEAR(t_main.Timestamp);

    -- Declare NOT FOUND handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- 1. Reset target table
    TRUNCATE TABLE `2026201061_deliverystatistics`;

    -- 2. Populate status counts via Set-Based SQL
    INSERT INTO `2026201061_deliverystatistics` (
        PINCode,
        PartnerID,
        MonthofOrder,
        YearofOrder,
        TotalOrders,
        TotalPendingAssignment,
        TotalAccepted,
        TotalHeadingforPickup,
        TotalArrivedatPickup,
        TotalPickedUp,
        TotalOutforDelivery,
        TotalArrivedatDoorStep,
        TotalDelivered,
        TotalDropped,
        TotalDelayedatPickup,
        TotalDeliveryFailed,
        TotalReturningtoStore,
        TotalReturned,
        TotalCancelled
    )
    SELECT 
        PINCode,
        PartnerID,
        MONTH(COALESCE(MIN(CASE WHEN Status = 'PendingAssignment' THEN Timestamp END), MIN(Timestamp))) AS MonthofOrder,
        YEAR(COALESCE(MIN(CASE WHEN Status = 'PendingAssignment' THEN Timestamp END), MIN(Timestamp))) AS YearofOrder,
        COUNT(DISTINCT OrderID) AS TotalOrders,
        COUNT(CASE WHEN Status = 'PendingAssignment' THEN 1 END) AS TotalPendingAssignment,
        COUNT(CASE WHEN Status = 'Accepted' THEN 1 END) AS TotalAccepted,
        COUNT(CASE WHEN Status = 'HeadingforPickup' THEN 1 END) AS TotalHeadingforPickup,
        COUNT(CASE WHEN Status = 'ArrivedatPickup' THEN 1 END) AS TotalArrivedatPickup,
        COUNT(CASE WHEN Status = 'PickedUp' THEN 1 END) AS TotalPickedUp,
        COUNT(CASE WHEN Status = 'OutforDelivery' THEN 1 END) AS TotalOutforDelivery,
        COUNT(CASE WHEN Status = 'ArrivedatDoorStep' THEN 1 END) AS TotalArrivedatDoorStep,
        COUNT(CASE WHEN Status = 'Delivered' THEN 1 END) AS TotalDelivered,
        COUNT(CASE WHEN Status = 'Dropped' THEN 1 END) AS TotalDropped,
        COUNT(CASE WHEN Status = 'DelayedatPickup' THEN 1 END) AS TotalDelayedatPickup,
        COUNT(CASE WHEN Status = 'DeliveryFailed' THEN 1 END) AS TotalDeliveryFailed,
        COUNT(CASE WHEN Status = 'ReturningtoStore' THEN 1 END) AS TotalReturningtoStore,
        COUNT(CASE WHEN Status = 'Returned' THEN 1 END) AS TotalReturned,
        COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END) AS TotalCancelled
    FROM `2026201061_delivery_data_pins_stg`
    GROUP BY PINCode, PartnerID, MONTH(Timestamp), YEAR(Timestamp);

    -- 3. Cursor Loop to update sequence time metrics
    OPEN cur_time_metrics;

    read_loop: LOOP
        FETCH cur_time_metrics INTO 
            v_pincode, v_partner_id, v_month, v_year, 
            v_time_to_accept, v_time_to_pickup, v_time_to_doorstep, v_time_to_deliver;

        IF done THEN
            LEAVE read_loop;
        END IF;

        UPDATE `2026201061_deliverystatistics`
        SET 
            TimetoAccept = v_time_to_accept,
            TimetoPickup = v_time_to_pickup,
            TimetoArriveatDoorStep = v_time_to_doorstep,
            TimetoDeliver = v_time_to_deliver
        WHERE PINCode = v_pincode
          AND PartnerID = v_partner_id
          AND MonthofOrder = v_month
          AND YearofOrder = v_year;

    END LOOP;

    CLOSE cur_time_metrics;

END //

DELIMITER ;

CALL 2026201061_PopulateDeliveryStatistics();

select count(*) from 2026201061_deliverystatistics;


-- TASK 3:

-- Creating Second Target Table: 2026201061_requestorstatistics:

CREATE TABLE 2026201061_requestorstatistics (
    -- Grouping Keys
    OrderRequestorID VARCHAR(50) NOT NULL,
    MonthofOrder INT NOT NULL,
    YearofOrder INT NOT NULL,

    -- Volume & Fulfillment KPIs
    TotalOrdersPlaced INT DEFAULT 0,
    TotalCancelled INT DEFAULT 0,
    TotalDeliveryFailed INT DEFAULT 0,

    -- Ratio & Performance KPIs
    CancellationRate DECIMAL(5, 2) DEFAULT 0.00,
    FailureRate DECIMAL(5, 2) DEFAULT 0.00,
    AvgTimeToDeliver DECIMAL(10, 2) DEFAULT 0.00,

    -- Behavior & Preference KPIs
    MostUsedPIN VARCHAR(10),
    MostFrequentPartnerID VARCHAR(50),

    -- Composite Primary Key
    PRIMARY KEY (OrderRequestorID, MonthofOrder, YearofOrder)
);

-- Populate the target table using a stored procedure:
DROP PROCEDURE IF EXISTS `2026201061_PopulateRequestorStatistics`;

DELIMITER //

CREATE PROCEDURE `2026201061_PopulateRequestorStatistics`()
BEGIN
    -- 1. Correctly reset target table
    TRUNCATE TABLE `2026201061_requestorstatistics`;

    -- 2. Populate basic aggregated metrics with unique grouping keys
    INSERT INTO `2026201061_requestorstatistics` (
        OrderRequestorID,
        MonthofOrder,
        YearofOrder,
        TotalOrdersPlaced,
        TotalCancelled,
        TotalDeliveryFailed,
        CancellationRate,
        FailureRate
    )
    SELECT 
        OrderRequestorID,
        m_calc AS MonthofOrder,
        y_calc AS YearofOrder,
        COUNT(DISTINCT OrderID) AS TotalOrdersPlaced,
        COUNT(DISTINCT CASE WHEN Status = 'Cancelled' THEN OrderID END) AS TotalCancelled,
        COUNT(DISTINCT CASE WHEN Status = 'DeliveryFailed' THEN OrderID END) AS TotalDeliveryFailed,
        ROUND((COUNT(DISTINCT CASE WHEN Status = 'Cancelled' THEN OrderID END) / NULLIF(COUNT(DISTINCT OrderID), 0)) * 100, 2) AS CancellationRate,
        ROUND((COUNT(DISTINCT CASE WHEN Status = 'DeliveryFailed' THEN OrderID END) / NULLIF(COUNT(DISTINCT OrderID), 0)) * 100, 2) AS FailureRate
    FROM (
        SELECT 
            OrderRequestorID,
            OrderID,
            Status,
            MONTH(COALESCE(MIN(CASE WHEN Status = 'PendingAssignment' THEN Timestamp END) OVER (PARTITION BY OrderRequestorID, OrderID), Timestamp)) AS m_calc,
            YEAR(COALESCE(MIN(CASE WHEN Status = 'PendingAssignment' THEN Timestamp END) OVER (PARTITION BY OrderRequestorID, OrderID), Timestamp)) AS y_calc
        FROM `2026201061_delivery_data_pins_stg`
    ) sub
    GROUP BY OrderRequestorID, m_calc, y_calc;

    -- 3. Update Most Used PIN
    UPDATE `2026201061_requestorstatistics` rs
    JOIN (
        SELECT OrderRequestorID, MONTH(Timestamp) AS m, YEAR(Timestamp) AS y, PINCode
        FROM (
            SELECT OrderRequestorID, Timestamp, PINCode,
                   ROW_NUMBER() OVER (PARTITION BY OrderRequestorID, MONTH(Timestamp), YEAR(Timestamp) ORDER BY COUNT(*) DESC) as rn
            FROM `2026201061_delivery_data_pins_stg`
            GROUP BY OrderRequestorID, MONTH(Timestamp), YEAR(Timestamp), PINCode
        ) sub_pin
        WHERE rn = 1
    ) pin_data ON rs.OrderRequestorID = pin_data.OrderRequestorID AND rs.MonthofOrder = pin_data.m AND rs.YearofOrder = pin_data.y
    SET rs.MostUsedPIN = pin_data.PINCode;

    -- 4. Update Most Frequent Partner
    UPDATE `2026201061_requestorstatistics` rs
    JOIN (
        SELECT OrderRequestorID, MONTH(Timestamp) AS m, YEAR(Timestamp) AS y, PartnerID
        FROM (
            SELECT OrderRequestorID, Timestamp, PartnerID,
                   ROW_NUMBER() OVER (PARTITION BY OrderRequestorID, MONTH(Timestamp), YEAR(Timestamp) ORDER BY COUNT(*) DESC) as rn
            FROM `2026201061_delivery_data_pins_stg`
            WHERE PartnerID IS NOT NULL AND PartnerID != ''
            GROUP BY OrderRequestorID, MONTH(Timestamp), YEAR(Timestamp), PartnerID
        ) sub_part
        WHERE rn = 1
    ) partner_data ON rs.OrderRequestorID = partner_data.OrderRequestorID AND rs.MonthofOrder = partner_data.m AND rs.YearofOrder = partner_data.y
    SET rs.MostFrequentPartnerID = partner_data.PartnerID;

END //

DELIMITER ;

-- Run procedure
CALL `2026201061_PopulateRequestorStatistics`();