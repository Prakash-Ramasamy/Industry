Please fix the shipment quantity inconsistencies in the SupplyChain X synthetic seed dataset before proceeding with backend integration.

The review identified 38 shipments where shipment_items.quantity exceeds the corresponding purchase_order_lines.ordered_qty.

Important: Do not simply cap each shipment row individually. Multiple shipments can fulfil the same PO line.

Implement the following:

1. Identify all affected PO lines using the aggregate shipment quantity grouped by po_line_id.
2. Correct shipment quantities so that the SUM of shipment_items.quantity across all shipments linked to a PO line does not exceed its ordered_qty, unless an explicit approved over-delivery allowance exists.
3. Preserve realistic partial shipments and distribute quantities across multiple shipments where applicable.
4. Preserve original PO ordered quantities and shipment-to-PO relationships.
5. Do not change the canonical flagship incident SCX-04 / INC-2026-001 unless an independent validation identifies an issue.
6. Add both individual and aggregate shipment fulfilment checks to validation.sql and validation_v2_3.sql.
7. Add a data-quality report listing affected PO lines, old quantities, corrected quantities and the remediation performed.
8. Re-run all database validation scripts after correction.

Acceptance criteria:
- Zero unintended PO-line over-fulfilment cases.
- Zero invalid shipment-to-PO references.
- All existing foreign-key constraints pass.
- Flagship incident data remains unchanged.
- All seed CSV files and SQL loaders produce consistent results.

Please regenerate the complete ZIP package and update the dataset manifest with the corrected record counts and validation results. Do not claim successful validation until the scripts have actually been executed.
