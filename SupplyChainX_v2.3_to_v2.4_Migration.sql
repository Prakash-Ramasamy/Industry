-- SupplyChain X v2.3 -> v2.4
-- Option A: investigations are the parent work item; incidents remain actual disruption records.
-- Run AFTER v2.3 schema + seed/load_all.sql. Tested for idempotent DDL intent, but execute on a DEV copy first.
BEGIN;
SET search_path TO scx, public;

CREATE TABLE IF NOT EXISTS investigations (
    investigation_id TEXT PRIMARY KEY,
    investigation_type TEXT NOT NULL CHECK (investigation_type IN
      ('NEW_DISRUPTION','EXISTING_ORDER','EXISTING_SHIPMENT','PROACTIVE_SCENARIO')),
    title TEXT NOT NULL,
    description TEXT,
    industry_id TEXT REFERENCES industries(industry_id),
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN
      ('DRAFT','IDENTIFYING_ENTITIES','READY_TO_START','IN_PROGRESS','AWAITING_APPROVAL',
       'CHANGES_REQUESTED','SIMULATED','CLOSED','FAILED','CANCELLED')),
    severity TEXT CHECK (severity IS NULL OR severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    provenance TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO' CHECK (provenance IN ('LIVE','SYNTHETIC_DEMO','SIMULATED','PUBLIC_SOURCE','UNKNOWN')),
    requested_by TEXT,
    source_description JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ
);

-- An investigation can link to multiple existing business records.
CREATE TABLE IF NOT EXISTS investigation_incidents (
    investigation_id TEXT NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    incident_id TEXT NOT NULL REFERENCES incidents(incident_id),
    relationship_type TEXT NOT NULL DEFAULT 'PRIMARY_DISRUPTION',
    PRIMARY KEY (investigation_id, incident_id, relationship_type)
);
CREATE TABLE IF NOT EXISTS investigation_purchase_orders (
    investigation_id TEXT NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    po_id TEXT NOT NULL REFERENCES purchase_orders(po_id),
    relationship_type TEXT NOT NULL DEFAULT 'AFFECTED_ORDER',
    PRIMARY KEY (investigation_id, po_id, relationship_type)
);
CREATE TABLE IF NOT EXISTS investigation_shipments (
    investigation_id TEXT NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    shipment_id TEXT NOT NULL REFERENCES shipments(shipment_id),
    relationship_type TEXT NOT NULL DEFAULT 'AFFECTED_SHIPMENT',
    PRIMARY KEY (investigation_id, shipment_id, relationship_type)
);
CREATE TABLE IF NOT EXISTS investigation_scenarios (
    investigation_id TEXT NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    scenario_id TEXT NOT NULL REFERENCES scenario_definitions(scenario_id),
    relationship_type TEXT NOT NULL DEFAULT 'BASED_ON_SCENARIO',
    PRIMARY KEY (investigation_id, scenario_id, relationship_type)
);

-- Generic entity bridge supports all entity types without pretending a polymorphic FK is enforceable.
-- Typed anchor tables above provide real FKs for common investigation entry points.
CREATE TABLE IF NOT EXISTS investigation_entity_links (
    investigation_entity_link_id TEXT PRIMARY KEY,
    investigation_id TEXT NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN
      ('SUPPLIER','COMPONENT','MATERIAL','FACILITY','PORT','WAREHOUSE','CARRIER',
       'PURCHASE_ORDER','PURCHASE_ORDER_LINE','SHIPMENT','PROJECT','MILESTONE',
       'INCIDENT','ROUTE','TRADE_EVENT')),
    entity_id TEXT NOT NULL,
    relationship_type TEXT NOT NULL,
    match_method TEXT NOT NULL DEFAULT 'DATABASE_RELATIONSHIP' CHECK (match_method IN
      ('EXACT_IDENTIFIER','ATTRIBUTE_MATCH','DATABASE_RELATIONSHIP','USER_ADDED','SCENARIO_INPUT')),
    match_confidence NUMERIC(5,4) CHECK (match_confidence IS NULL OR match_confidence BETWEEN 0 AND 1),
    confirmation_status TEXT NOT NULL DEFAULT 'SUGGESTED' CHECK (confirmation_status IN
      ('SUGGESTED','CONFIRMED','EXCLUDED','NEEDS_REVIEW')),
    evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    confirmed_by TEXT,
    confirmed_at TIMESTAMPTZ,
    UNIQUE (investigation_id, entity_type, entity_id, relationship_type)
);

CREATE TABLE IF NOT EXISTS investigation_evidence (
    investigation_id TEXT NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    evidence_id TEXT NOT NULL REFERENCES evidence_records(evidence_id),
    relationship_type TEXT NOT NULL DEFAULT 'SUPPORTING_EVIDENCE',
    PRIMARY KEY (investigation_id, evidence_id, relationship_type)
);

-- One execution record per proactive scenario run; inputs/results are immutable snapshots.
CREATE TABLE IF NOT EXISTS scenario_runs (
    scenario_run_id TEXT PRIMARY KEY,
    investigation_id TEXT NOT NULL UNIQUE REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    scenario_id TEXT REFERENCES scenario_definitions(scenario_id),
    event_type TEXT NOT NULL,
    affected_country_codes TEXT[] NOT NULL DEFAULT '{}',
    affected_hs_codes TEXT[] NOT NULL DEFAULT '{}',
    affected_industry_ids TEXT[] NOT NULL DEFAULT '{}',
    duration_days INTEGER CHECK (duration_days IS NULL OR duration_days > 0),
    severity TEXT CHECK (severity IS NULL OR severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    input_parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    resolved_entity_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
    result_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (result_status IN
      ('PENDING','RUNNING','COMPLETED','FAILED','CANCELLED')),
    result_summary JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

-- Add investigation ownership to existing workflow, agent, assessment and result records.
ALTER TABLE workflow_runs ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE supplier_assessments ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE logistics_assessments ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE risk_assessments ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE incident_impact_snapshots ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE dependency_graph_snapshots ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);
ALTER TABLE audit_events ADD COLUMN IF NOT EXISTS investigation_id TEXT REFERENCES investigations(investigation_id);

-- Backfill one parent investigation for every existing incident. Deterministic IDs make reruns safe.
INSERT INTO investigations (
  investigation_id, investigation_type, title, description, status, severity, provenance, source_description, created_at
)
SELECT
  'INV-' || i.incident_id,
  'NEW_DISRUPTION',
  COALESCE(NULLIF(i.description,''), i.incident_type),
  i.description,
  CASE
    WHEN UPPER(i.status) IN ('CLOSED','RESOLVED') THEN 'CLOSED'
    WHEN UPPER(i.status) IN ('FAILED') THEN 'FAILED'
    ELSE 'READY_TO_START'
  END,
  CASE WHEN UPPER(i.severity) IN ('LOW','MEDIUM','HIGH','CRITICAL') THEN UPPER(i.severity) ELSE NULL END,
  CASE WHEN UPPER(i.provenance) IN ('LIVE','SYNTHETIC_DEMO','SIMULATED','PUBLIC_SOURCE','UNKNOWN') THEN UPPER(i.provenance) ELSE 'SYNTHETIC_DEMO' END,
  jsonb_build_object('migration_source','v2.3 incidents','incident_type',i.incident_type,'start_date',i.start_date),
  COALESCE(i.start_date::timestamptz, now())
FROM incidents i
ON CONFLICT (investigation_id) DO NOTHING;

INSERT INTO investigation_incidents (investigation_id, incident_id)
SELECT 'INV-' || incident_id, incident_id FROM incidents
ON CONFLICT DO NOTHING;

-- Copy existing polymorphic incident entity references into the investigation entity bridge.
INSERT INTO investigation_entity_links (
  investigation_entity_link_id, investigation_id, entity_type, entity_id, relationship_type,
  match_method, confirmation_status, attributes
)
SELECT
  'IEL-' || ie.incident_entity_id,
  'INV-' || ie.incident_id,
  CASE UPPER(ie.entity_type)
    WHEN 'PO' THEN 'PURCHASE_ORDER'
    WHEN 'PO_LINE' THEN 'PURCHASE_ORDER_LINE'
    WHEN 'MILESTONE' THEN 'MILESTONE'
    ELSE UPPER(ie.entity_type)
  END,
  ie.entity_id,
  ie.relationship_type,
  'DATABASE_RELATIONSHIP',
  'CONFIRMED',
  jsonb_build_object('migrated_from','incident_entities')
FROM incident_entities ie
WHERE UPPER(ie.entity_type) IN
 ('SUPPLIER','COMPONENT','MATERIAL','FACILITY','PORT','WAREHOUSE','CARRIER',
  'PURCHASE_ORDER','PO','PURCHASE_ORDER_LINE','PO_LINE','SHIPMENT','PROJECT','MILESTONE',
  'INCIDENT','ROUTE','TRADE_EVENT')
ON CONFLICT DO NOTHING;

-- Create typed purchase-order and shipment links from legacy incident entity references.
INSERT INTO investigation_purchase_orders (investigation_id, po_id)
SELECT DISTINCT 'INV-' || incident_id, entity_id
FROM incident_entities
WHERE UPPER(entity_type) IN ('PURCHASE_ORDER','PO')
  AND EXISTS (SELECT 1 FROM purchase_orders p WHERE p.po_id=incident_entities.entity_id)
ON CONFLICT DO NOTHING;

INSERT INTO investigation_shipments (investigation_id, shipment_id)
SELECT DISTINCT 'INV-' || incident_id, entity_id
FROM incident_entities
WHERE UPPER(entity_type)='SHIPMENT'
  AND EXISTS (SELECT 1 FROM shipments s WHERE s.shipment_id=incident_entities.entity_id)
ON CONFLICT DO NOTHING;

-- Link canonical scenario definitions to the migrated flagship investigation.
INSERT INTO investigation_scenarios (investigation_id, scenario_id)
SELECT 'INV-' || linked_incident_id, scenario_id
FROM scenario_definitions
WHERE linked_incident_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Backfill investigation_id on all incident-owned runtime records.
UPDATE workflow_runs wr
SET investigation_id='INV-' || wr.incident_id
WHERE wr.investigation_id IS NULL AND wr.incident_id IS NOT NULL;

UPDATE agent_runs ar
SET investigation_id='INV-' || ar.incident_id
WHERE ar.investigation_id IS NULL AND ar.incident_id IS NOT NULL;

UPDATE recovery_plans rp
SET investigation_id='INV-' || rp.incident_id
WHERE rp.investigation_id IS NULL AND rp.incident_id IS NOT NULL;

UPDATE supplier_assessments sa
SET investigation_id='INV-' || sa.incident_id
WHERE sa.investigation_id IS NULL AND sa.incident_id IS NOT NULL;

UPDATE logistics_assessments la
SET investigation_id='INV-' || la.incident_id
WHERE la.investigation_id IS NULL AND la.incident_id IS NOT NULL;

UPDATE risk_assessments ra
SET investigation_id='INV-' || ra.incident_id
WHERE ra.investigation_id IS NULL AND ra.incident_id IS NOT NULL;

UPDATE simulation_runs sr
SET investigation_id='INV-' || sr.incident_id
WHERE sr.investigation_id IS NULL AND sr.incident_id IS NOT NULL;

UPDATE incident_impact_snapshots s
SET investigation_id='INV-' || s.incident_id
WHERE s.investigation_id IS NULL;

UPDATE dependency_graph_snapshots s
SET investigation_id='INV-' || s.incident_id
WHERE s.investigation_id IS NULL;

UPDATE audit_events ae
SET investigation_id='INV-' || ae.incident_id
WHERE ae.investigation_id IS NULL AND ae.incident_id IS NOT NULL;

-- Existing records now have parent ownership. New non-incident investigations may leave incident_id NULL.
ALTER TABLE workflow_runs ALTER COLUMN incident_id DROP NOT NULL;
ALTER TABLE workflow_runs ALTER COLUMN investigation_id SET NOT NULL;
ALTER TABLE agent_runs ALTER COLUMN incident_id DROP NOT NULL;
ALTER TABLE agent_runs ALTER COLUMN investigation_id SET NOT NULL;
ALTER TABLE recovery_plans ALTER COLUMN incident_id DROP NOT NULL;
ALTER TABLE recovery_plans ALTER COLUMN investigation_id SET NOT NULL;
ALTER TABLE supplier_assessments ALTER COLUMN incident_id DROP NOT NULL;
ALTER TABLE supplier_assessments ALTER COLUMN investigation_id SET NOT NULL;
ALTER TABLE logistics_assessments ALTER COLUMN incident_id DROP NOT NULL;
ALTER TABLE logistics_assessments ALTER COLUMN investigation_id SET NOT NULL;
ALTER TABLE risk_assessments ALTER COLUMN incident_id DROP NOT NULL;
ALTER TABLE risk_assessments ALTER COLUMN investigation_id SET NOT NULL;

-- Add indexes for the new access paths.
CREATE INDEX IF NOT EXISTS ix_investigations_type_status ON investigations(investigation_type,status,created_at DESC);
CREATE INDEX IF NOT EXISTS ix_inv_entity_lookup ON investigation_entity_links(investigation_id,entity_type,entity_id);
CREATE INDEX IF NOT EXISTS ix_inv_entity_confirmation ON investigation_entity_links(investigation_id,confirmation_status);
CREATE INDEX IF NOT EXISTS ix_inv_po_po ON investigation_purchase_orders(po_id);
CREATE INDEX IF NOT EXISTS ix_inv_ship_shipment ON investigation_shipments(shipment_id);
CREATE INDEX IF NOT EXISTS ix_workflow_investigation_started ON workflow_runs(investigation_id,started_at DESC);
CREATE INDEX IF NOT EXISTS ix_agent_investigation ON agent_runs(investigation_id,started_at DESC);
CREATE INDEX IF NOT EXISTS ix_plan_investigation_status ON recovery_plans(investigation_id,status);
CREATE INDEX IF NOT EXISTS ix_scenario_runs_investigation ON scenario_runs(investigation_id,created_at DESC);
CREATE INDEX IF NOT EXISTS ix_audit_investigation_time ON audit_events(investigation_id,event_time DESC);

COMMIT;
