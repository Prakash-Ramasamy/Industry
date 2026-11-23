The central design change is:
- investigations becomes the parent entity.
- incidents continues to represent actual disruptions.
- Existing purchase orders and shipments remain unchanged.
- All three investigation types use the same workflow and seven AI agents.
1. Download the complete package
2. What has changed?

<img width="325" height="131" alt="image" src="https://github.com/user-attachments/assets/6bae8797-3e1a-4636-aad5-f8f297ac3613" />

Existing workflow, agent, assessment, recovery and simulation records now gain an investigation_id.

<img width="665" height="319" alt="image" src="https://github.com/user-attachments/assets/8e38bcf3-8b17-4f45-a7ee-41af8ed76d26" />

The package also includes:
- Database relationship diagram.
- Proposed API contracts.
- Updated README and installation instructions.
- Fresh-install convenience script.
- v2.4 validation SQL.
- Investigation summary views.
- Updated dataset manifest.
4. How to apply the migration
For your Azure Database for PostgreSQL Flexible Server, use this order:
1. Back up your existing database.
2. Test on a development database.
3. Apply the v2.3 baseline schema and seed if creating a fresh database.
4. Execute the v2.4 migration.
5. Execute the v2.4 seed update.
6. Create the optional read-model views.
7. Execute the validation script.
The package includes sql/install_fresh_v2_4.sql for a fresh development installation.

Important: The migration backfills one investigation for every existing incident, including INV-INC-2026-001 for the SCX-04 flagship. It does not duplicate or rewrite the operational PO, shipment or inventory data.

5. Three things to verify before backend development
- [x] All existing incidents have a corresponding investigation.
- [x] INV-INC-2026-001 correctly links to SCX-04, PO-1007 and SHIP-209.
- [x] Workflow runs and recovery plans can be created for an investigation with no incident_id.
One additional point: the previously identified shipment quantity inconsistencies are not silently corrected by this migration. Keep the shipment fulfilment data-quality fix as a separate task.

The SQL and migration package have been generated, but I have not run them against your Azure PostgreSQL server. Please test on a development copy first.

My recommendation: Freeze the v2.4 data model after these validation checks pass. Then update the backend API contracts and Replit UI to use investigation_id as the common identifier. This will prevent us from having to redesign the database again when we add existing-order and proactive-scenario workflows.
