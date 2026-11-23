
Investigate the shipment quantity over-fulfilment discrepancy in the SupplyChain X database.

Context:

An earlier validation reported 38 out of 350 shipment rows with quantity over-fulfilment.
A subsequent re-run of the same validation reportedly returned zero rows.
We need to establish why these results differ.
Tasks:

Inspect the actual database schema, shipment data, purchase order lines and existing validation SQL.
Identify the exact SQL query used for the original 38-row result and the subsequent zero-row result.
Verify the individual shipment quantity rule: shipment item quantity must not exceed its associated PO line ordered quantity, unless an approved overdelivery allowance exists.
Verify the aggregate fulfilment rule: SUM of quantities across all shipments for a PO line must not exceed the ordered quantity, unless an approved allowance exists.
Check joins, filters, data types, units of measurement, NULL values and shipment-to-PO relationships.
Reproduce both results against the same database snapshot.
Generate a report containing:
PO ID and PO line ID
Ordered quantity
Individual shipment quantities
Aggregate shipped quantity
Over-fulfilment amount
Shipment IDs
Validation result
Important restrictions:

Do not modify, delete or cap any shipment quantities.
Do not change PO quantities.
Do not modify the SCX-04 flagship scenario.
Do not change the v2.4 migration.
Do not report the issue as resolved until the results are reproducible.
Deliver the root cause, corrected validation SQL, and a before/after data-quality report. If there are no violations, explain why the earlier 38-row result was different.

Step 2 – Decide based on the result Investigation result : What to do 38 violations confirmed : Correct the affected synthetic seed data with an auditable correction script Aggregate violations only : Correct shipment allocations across multiple shipments No violations found : Document the earlier result as an incorrect or outdated validation finding Different database snapshots : Identify the authoritative dataset and rerun all validations

Step 3 – Protect the v2.4 migration For now:

Keep the v2.4 migration unchanged.
Don't manually update the 38 shipment records.
Don't discard the existing validation warning without evidence.
Run the complete database validation after resolving the discrepancy. My recommendation Treat this as a data-quality investigation separate from the v2.4 schema migration. This keeps the migration focused on its purpose: introducing investigations as the parent entity.
Once you receive the SQL results from your coding assistant, share them here. I'll help determine whether the data needs correction and provide the appropriate SQL correction script.
