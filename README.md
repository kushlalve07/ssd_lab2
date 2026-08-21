# Delivery Statistics & Performance Analytics

## 1. Reassigned & Dropped Orders Attribution Rule
When an order is dropped by an initial delivery partner and reassigned to another, metrics are attributed according to the following logic:
* **Attribution Strategy:** Final Partner Attribution.
* **Logic & Rationale:** All aggregated status counts (`TotalOrders`, `TotalDelivered`, etc.) and duration averages (`TimetoAccept`, `TimetoDeliver`) are credited exclusively to the final delivery partner who completed the fulfillment. Intermediate `Dropped` events logged by prior partners are isolated to avoid distorting efficiency SLAs or time metrics for partners who did not complete the delivery sequence.

---

## 2. Requestor Statistics KPI Rationale
* **TotalOrdersPlaced & CancellationRate:** Tracks order volume per merchant/store location while identifying potential churn risks and merchant-side operational friction.
* **FailureRate:** Highlights logistics breakdowns (e.g., recipient unreachable or address errors) specific to a requestor's venue.
* **MostUsedPIN & MostFrequentPartnerID:** Maps regional demand density and identifies strong merchant-to-driver affinity patterns for dispatch optimization.

---

## 3. Cursor vs. Set-Based Processing
The `TimetoAccept` metric was processed using an explicit cursor iteration, but it could easily be implemented using set-based SQL via conditional aggregations, self-joins, or window functions such as `LEAD()`. Transitioning to a set-based approach gains massive execution performance improvements, parallel processing optimization by the query engine, and cleaner, far more readable code. What is lost is the ability to easily perform complex sequential, row-by-row state-machine validations or fine-grained custom exception handling. However, for standard timestamp calculations, set-based processing remains strictly superior to procedural cursor loops in relational database engines like MySQL.