# Delivery Statistics & Performance Analytics

## Introduction & Project Overview
This project processes raw, event-driven staging data (`2026201061_delivery_data_pins_stg`) and transforms it into structured analytical tables (`2026201061_deliverystatistics` and `2026201061_requestorstatistics`) using MySQL stored procedures. 

The primary goal is to aggregate delivery lifecycle events into key performance indicators (KPIs) across two key operational dimensions:
1. **Delivery Partner Metrics:** Evaluating partner efficiency, status counts, and sequential durations (e.g., time to accept, pick up, and deliver) per PIN code and monthly time bucket.
2. **Order Requestor Insights:** Analyzing merchant/requestor behavior, order volumes, cancellation/failure rates, and dispatch preferences to optimize logistics operations.

---

## Assumptions & Attribution Rules
* **Final Partner Attribution:** For reassigned or dropped orders, all metrics and sequential time calculations are attributed exclusively to the **final delivery partner** who successfully completed the fulfillment. Intermediate `Dropped` events are isolated so they do not artificially distort operational efficiency SLAs or time metrics for partners who did not complete the delivery sequence.
* **Pending Assignment State:** During the `PendingAssignment` status, `PartnerID` values are represented as empty strings (`''`) rather than standard SQL `NULL` values.
* **Fallback Date Resolution:** If an order record lacks an explicit `PendingAssignment` status event, the grouping attributes (`MonthofOrder` and `YearofOrder`) fall back to the earliest recorded timestamp available for that specific order.

---

## Requestor Statistics KPI Rationale
* **TotalOrdersPlaced & CancellationRate:** Tracks order volume per merchant location while identifying operational friction and potential merchant churn risks.
* **FailureRate:** Highlights logistics breakdowns (e.g., unreachable recipients or address errors) specific to a requestor's venue.
* **MostUsedPIN & MostFrequentPartnerID:** Maps regional demand density and identifies strong merchant-to-driver affinity patterns for dispatch optimization.

---

## Cursor vs. Set-Based Processing
The `TimetoAccept` metric was processed using an explicit cursor iteration, but it could easily be implemented using set-based SQL via conditional aggregations, self-joins, or window functions such as `LEAD()`. 

Transitioning to a set-based approach yields massive execution performance improvements, parallel processing optimization by the database query engine, and cleaner, far more readable code. What is lost is the ability to easily perform complex sequential, row-by-row state-machine validations or fine-grained custom exception handling. However, for standard timestamp calculations, set-based processing remains strictly superior to procedural cursor loops in relational database engines like MySQL.

---

## GitHub Repository
https://github.com/kushlalve07/ssd_lab2