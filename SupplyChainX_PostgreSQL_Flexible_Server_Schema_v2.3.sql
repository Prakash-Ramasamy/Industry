CREATE SCHEMA IF NOT EXISTS scx;
SET search_path TO scx, public;
CREATE TABLE countries(country_id TEXT PRIMARY KEY,country_name TEXT NOT NULL,iso_code TEXT UNIQUE NOT NULL,region TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE suppliers(supplier_id TEXT PRIMARY KEY,supplier_name TEXT NOT NULL,country_id TEXT NOT NULL REFERENCES countries,status TEXT NOT NULL,risk_tier TEXT NOT NULL,synthetic_record BOOLEAN NOT NULL);

CREATE TABLE components(component_id TEXT PRIMARY KEY,component_name TEXT NOT NULL,category TEXT NOT NULL,criticality TEXT NOT NULL,specifications_json JSONB NOT NULL,unit_of_measure TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE ports(port_id TEXT PRIMARY KEY,port_name TEXT NOT NULL,country_id TEXT NOT NULL REFERENCES countries,status TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE warehouses(warehouse_id TEXT PRIMARY KEY,warehouse_name TEXT NOT NULL,country_id TEXT NOT NULL REFERENCES countries,location TEXT NOT NULL,status TEXT NOT NULL);
CREATE TABLE carriers(carrier_id TEXT PRIMARY KEY,carrier_name TEXT NOT NULL,service_type TEXT NOT NULL,status TEXT NOT NULL);
CREATE TABLE supplier_components(supplier_component_id TEXT PRIMARY KEY,supplier_id TEXT NOT NULL REFERENCES suppliers,component_id TEXT NOT NULL REFERENCES components,capability_status TEXT NOT NULL,stated_capacity INT NOT NULL CHECK(stated_capacity>=0),lead_time_days INT NOT NULL,currency TEXT NOT NULL,provenance TEXT NOT NULL,UNIQUE(supplier_id,component_id));
CREATE TABLE supplier_qualifications(qualification_id TEXT PRIMARY KEY,supplier_id TEXT NOT NULL REFERENCES suppliers,component_id TEXT NOT NULL REFERENCES components,status TEXT NOT NULL,valid_from DATE NOT NULL,valid_until DATE NOT NULL,evidence_status TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE supplier_certifications(certification_id TEXT PRIMARY KEY,supplier_id TEXT NOT NULL REFERENCES suppliers,certification_type TEXT NOT NULL,status TEXT NOT NULL,expiry_date DATE NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE supplier_capacity_snapshots(capacity_snapshot_id TEXT PRIMARY KEY,supplier_id TEXT NOT NULL REFERENCES suppliers,component_id TEXT NOT NULL REFERENCES components,available_capacity INT NOT NULL,snapshot_date DATE NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE routes(route_id TEXT PRIMARY KEY,origin_port_id TEXT NOT NULL REFERENCES ports,destination_port_id TEXT NOT NULL REFERENCES ports,estimated_transit_days INT NOT NULL,estimated_cost NUMERIC(14,2) NOT NULL,currency TEXT NOT NULL,status TEXT NOT NULL,provenance TEXT NOT NULL,CHECK(origin_port_id<>destination_port_id));
CREATE TABLE route_port_stops(route_id TEXT NOT NULL REFERENCES routes ON DELETE CASCADE,sequence_number INT NOT NULL,port_id TEXT NOT NULL REFERENCES ports,PRIMARY KEY(route_id,sequence_number));
CREATE TABLE projects(project_id TEXT PRIMARY KEY,project_name TEXT NOT NULL,project_type TEXT NOT NULL,status TEXT NOT NULL,priority TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE project_component_requirements(requirement_id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects,component_id TEXT NOT NULL REFERENCES components,required_qty INT NOT NULL,required_by_date DATE NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE project_milestones(milestone_id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects,milestone_name TEXT NOT NULL,planned_date DATE NOT NULL,status TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE milestone_component_requirements(milestone_requirement_id TEXT PRIMARY KEY,milestone_id TEXT NOT NULL REFERENCES project_milestones,component_id TEXT NOT NULL REFERENCES components,required_qty INT NOT NULL);
CREATE TABLE purchase_orders(po_id TEXT PRIMARY KEY,supplier_id TEXT NOT NULL REFERENCES suppliers,po_date DATE NOT NULL,expected_delivery_date DATE NOT NULL,status TEXT NOT NULL,currency TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE purchase_order_lines(po_line_id TEXT PRIMARY KEY,po_id TEXT NOT NULL REFERENCES purchase_orders ON DELETE CASCADE,component_id TEXT NOT NULL REFERENCES components,ordered_qty INT NOT NULL,received_qty INT NOT NULL CHECK(received_qty<=ordered_qty),unit_price NUMERIC(14,2) NOT NULL);
CREATE TABLE shipments(shipment_id TEXT PRIMARY KEY,po_line_id TEXT NOT NULL REFERENCES purchase_order_lines,carrier_id TEXT NOT NULL REFERENCES carriers,origin_port_id TEXT NOT NULL REFERENCES ports,destination_port_id TEXT NOT NULL REFERENCES ports,status TEXT NOT NULL,estimated_arrival_date DATE NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE shipment_items(shipment_item_id TEXT PRIMARY KEY,shipment_id TEXT NOT NULL REFERENCES shipments ON DELETE CASCADE,component_id TEXT NOT NULL REFERENCES components,quantity INT NOT NULL);
CREATE TABLE inventory_snapshots(inventory_snapshot_id TEXT PRIMARY KEY,warehouse_id TEXT NOT NULL REFERENCES warehouses,component_id TEXT NOT NULL REFERENCES components,on_hand_qty INT NOT NULL,reserved_qty INT NOT NULL CHECK(reserved_qty<=on_hand_qty),snapshot_at TIMESTAMPTZ NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE inventory_reservations(reservation_id TEXT PRIMARY KEY,warehouse_id TEXT NOT NULL REFERENCES warehouses,component_id TEXT NOT NULL REFERENCES components,project_id TEXT NOT NULL REFERENCES projects,quantity INT NOT NULL,status TEXT NOT NULL,created_at TIMESTAMPTZ NOT NULL);
CREATE TABLE inventory_movements(movement_id TEXT PRIMARY KEY,warehouse_id TEXT NOT NULL REFERENCES warehouses,component_id TEXT NOT NULL REFERENCES components,movement_type TEXT NOT NULL,quantity INT NOT NULL,reference_id TEXT NOT NULL,movement_date DATE NOT NULL);
CREATE TABLE port_status_snapshots(port_snapshot_id TEXT PRIMARY KEY,port_id TEXT NOT NULL REFERENCES ports,congestion_level INT NOT NULL CHECK(congestion_level BETWEEN 0 AND 100),status TEXT NOT NULL,observed_at TIMESTAMPTZ NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE incidents(incident_id TEXT PRIMARY KEY,incident_type TEXT NOT NULL,severity TEXT NOT NULL,start_date DATE NOT NULL,expected_duration_days INT NOT NULL,status TEXT NOT NULL,description TEXT NOT NULL,provenance TEXT NOT NULL);
CREATE TABLE incident_entities(incident_entity_id TEXT PRIMARY KEY,incident_id TEXT NOT NULL REFERENCES incidents ON DELETE CASCADE,entity_type TEXT NOT NULL,entity_id TEXT NOT NULL,relationship_type TEXT NOT NULL,UNIQUE(incident_id,entity_type,entity_id,relationship_type));
CREATE TABLE incident_events(event_id TEXT PRIMARY KEY,incident_id TEXT NOT NULL REFERENCES incidents ON DELETE CASCADE,event_type TEXT NOT NULL,event_time TIMESTAMPTZ NOT NULL,description TEXT NOT NULL);
CREATE TABLE evidence_records(evidence_id TEXT PRIMARY KEY,evidence_type TEXT NOT NULL,source TEXT NOT NULL,source_date DATE NOT NULL,storage_uri TEXT NOT NULL,provenance TEXT NOT NULL,freshness_status TEXT NOT NULL);
CREATE TABLE entity_evidence(evidence_id TEXT NOT NULL REFERENCES evidence_records ON DELETE CASCADE,entity_type TEXT NOT NULL,entity_id TEXT NOT NULL,PRIMARY KEY(evidence_id,entity_type,entity_id));
CREATE TABLE recovery_plans(plan_id TEXT PRIMARY KEY,incident_id TEXT NOT NULL REFERENCES incidents,plan_version INT NOT NULL,status TEXT NOT NULL,plan_hash TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT now(),UNIQUE(plan_id,plan_version));
CREATE TABLE recovery_actions(action_id TEXT PRIMARY KEY,plan_id TEXT NOT NULL REFERENCES recovery_plans ON DELETE CASCADE,action_type TEXT NOT NULL,target_entity_id TEXT NOT NULL,parameters_json JSONB NOT NULL DEFAULT '{}'::jsonb);
CREATE TABLE plan_validation_runs(validation_id TEXT PRIMARY KEY,plan_id TEXT NOT NULL REFERENCES recovery_plans,plan_version INT NOT NULL,result TEXT NOT NULL CHECK(result IN ('PASS','BLOCK','NEEDS_REVIEW')),executed_at TIMESTAMPTZ NOT NULL);
CREATE TABLE plan_validation_findings(finding_id TEXT PRIMARY KEY,validation_id TEXT NOT NULL REFERENCES plan_validation_runs ON DELETE CASCADE,rule_code TEXT NOT NULL,status TEXT NOT NULL,explanation TEXT NOT NULL);
CREATE TABLE plan_approvals(approval_id TEXT PRIMARY KEY,plan_id TEXT NOT NULL REFERENCES recovery_plans,plan_version INT NOT NULL,plan_hash TEXT NOT NULL,approver TEXT NOT NULL,decision TEXT NOT NULL,decision_at TIMESTAMPTZ NOT NULL);
CREATE TABLE simulation_runs(simulation_id TEXT PRIMARY KEY,plan_id TEXT NOT NULL REFERENCES recovery_plans,simulation_type TEXT NOT NULL,metrics_json JSONB NOT NULL,created_at TIMESTAMPTZ NOT NULL);
CREATE TABLE agent_runs(agent_run_id TEXT PRIMARY KEY,incident_id TEXT NOT NULL REFERENCES incidents,agent_name TEXT NOT NULL,status TEXT NOT NULL,input_ref TEXT,output_ref TEXT,started_at TIMESTAMPTZ,completed_at TIMESTAMPTZ);
CREATE TABLE audit_events(audit_id TEXT PRIMARY KEY,actor TEXT NOT NULL,action TEXT NOT NULL,entity_type TEXT NOT NULL,entity_id TEXT NOT NULL,event_time TIMESTAMPTZ NOT NULL,details_json JSONB NOT NULL DEFAULT '{}'::jsonb);
CREATE INDEX ix_po_supplier ON purchase_orders(supplier_id);
CREATE INDEX ix_pol_component ON purchase_order_lines(component_id);
CREATE INDEX ix_ship_po_line ON shipments(po_line_id);
CREATE INDEX ix_inventory_component ON inventory_snapshots(component_id,warehouse_id);
CREATE INDEX ix_project_req_component ON project_component_requirements(component_id);
CREATE INDEX ix_incident_entity_lookup ON incident_entities(incident_id,entity_type,entity_id);
CREATE INDEX ix_supplier_component_component ON supplier_components(component_id);


-- ============================================================
-- SUPPLYCHAIN X v2.3 EXTENDED DATA MODEL
-- Adds industry taxonomy, facilities/materials, trade intelligence,
-- source provenance, workflow orchestration, agent outputs,
-- approval acknowledgements, simulation metrics and API idempotency.
-- Existing v2.2 operational seed tables remain compatible.
-- ============================================================
SET search_path TO scx, public;

-- Reference / industry configuration
CREATE TABLE IF NOT EXISTS industries (
  industry_id TEXT PRIMARY KEY,
  industry_name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  provenance TEXT NOT NULL DEFAULT 'CONFIGURATION'
);
CREATE TABLE IF NOT EXISTS scenario_definitions (
  scenario_id TEXT PRIMARY KEY,
  industry_id TEXT NOT NULL REFERENCES industries(industry_id),
  scenario_name TEXT NOT NULL,
  hypothetical_event TEXT NOT NULL,
  scenario_status TEXT NOT NULL CHECK (scenario_status IN ('FLAGSHIP_BACKEND_CONNECTED','MOCK')),
  linked_incident_id TEXT REFERENCES incidents(incident_id) DEFERRABLE INITIALLY DEFERRED,
  is_flagship BOOLEAN NOT NULL DEFAULT FALSE,
  provenance TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO',
  CHECK ((is_flagship AND scenario_status='FLAGSHIP_BACKEND_CONNECTED') OR NOT is_flagship)
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_one_flagship_scenario ON scenario_definitions(is_flagship) WHERE is_flagship;

CREATE TABLE IF NOT EXISTS facilities (
  facility_id TEXT PRIMARY KEY,
  facility_name TEXT NOT NULL,
  facility_type TEXT NOT NULL,
  country_id TEXT NOT NULL REFERENCES countries(country_id),
  latitude NUMERIC(9,6),
  longitude NUMERIC(9,6),
  coordinate_status TEXT NOT NULL DEFAULT 'UNKNOWN' CHECK (coordinate_status IN ('VERIFIED','APPROXIMATE','UNKNOWN')),
  address_text TEXT,
  provenance TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO',
  CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180))
);
CREATE TABLE IF NOT EXISTS supplier_facilities (
  supplier_id TEXT NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
  facility_id TEXT NOT NULL REFERENCES facilities(facility_id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL DEFAULT 'OPERATES',
  valid_from DATE,
  valid_to DATE,
  PRIMARY KEY (supplier_id, facility_id),
  CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);
CREATE TABLE IF NOT EXISTS industry_suppliers (
  supplier_id TEXT NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
  industry_id TEXT NOT NULL REFERENCES industries(industry_id),
  relevance_type TEXT NOT NULL DEFAULT 'SUPPLIES',
  PRIMARY KEY (supplier_id, industry_id)
);
CREATE TABLE IF NOT EXISTS industry_components (
  component_id TEXT NOT NULL REFERENCES components(component_id) ON DELETE CASCADE,
  industry_id TEXT NOT NULL REFERENCES industries(industry_id),
  applicability TEXT NOT NULL DEFAULT 'USED_IN',
  PRIMARY KEY (component_id, industry_id)
);
CREATE TABLE IF NOT EXISTS project_industries (
  project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
  industry_id TEXT NOT NULL REFERENCES industries(industry_id),
  PRIMARY KEY (project_id, industry_id)
);

-- Material and multi-tier product structure
CREATE TABLE IF NOT EXISTS materials (
  material_id TEXT PRIMARY KEY,
  material_name TEXT NOT NULL,
  material_category TEXT NOT NULL,
  hs_code TEXT,
  hs_code_version TEXT,
  unit_of_measure TEXT NOT NULL,
  criticality TEXT NOT NULL DEFAULT 'MEDIUM',
  provenance TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO',
  CHECK (hs_code IS NULL OR hs_code ~ '^[0-9]{6,10}$')
);
CREATE TABLE IF NOT EXISTS component_materials (
  component_id TEXT NOT NULL REFERENCES components(component_id) ON DELETE CASCADE,
  material_id TEXT NOT NULL REFERENCES materials(material_id),
  quantity_per_component NUMERIC(18,6) NOT NULL CHECK (quantity_per_component > 0),
  unit_of_measure TEXT NOT NULL,
  PRIMARY KEY (component_id, material_id)
);
CREATE TABLE IF NOT EXISTS component_bom (
  parent_component_id TEXT NOT NULL REFERENCES components(component_id) ON DELETE CASCADE,
  child_component_id TEXT NOT NULL REFERENCES components(component_id),
  quantity_per_parent NUMERIC(18,6) NOT NULL CHECK (quantity_per_parent > 0),
  effective_from DATE,
  effective_to DATE,
  provenance TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO',
  PRIMARY KEY (parent_component_id, child_component_id),
  CHECK (parent_component_id <> child_component_id),
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);

-- Route metadata and route-to-carrier availability
CREATE TABLE IF NOT EXISTS route_carriers (
  route_id TEXT NOT NULL REFERENCES routes(route_id) ON DELETE CASCADE,
  carrier_id TEXT NOT NULL REFERENCES carriers(carrier_id),
  service_level TEXT NOT NULL DEFAULT 'STANDARD',
  estimated_transit_days INTEGER NOT NULL CHECK (estimated_transit_days > 0),
  estimated_cost NUMERIC(16,2),
  currency CHAR(3),
  availability_status TEXT NOT NULL DEFAULT 'UNKNOWN',
  provenance TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO',
  PRIMARY KEY (route_id, carrier_id, service_level)
);
CREATE TABLE IF NOT EXISTS route_disruptions (
  route_disruption_id TEXT PRIMARY KEY,
  route_id TEXT NOT NULL REFERENCES routes(route_id),
  port_id TEXT REFERENCES ports(port_id),
  disruption_type TEXT NOT NULL,
  severity TEXT NOT NULL,
  delay_days INTEGER CHECK (delay_days IS NULL OR delay_days >= 0),
  observed_at TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ,
  evidence_id TEXT,
  provenance TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO'
);

-- Public / external trade intelligence and source provenance
CREATE TABLE IF NOT EXISTS evidence_sources (
  source_id TEXT PRIMARY KEY,
  source_name TEXT NOT NULL,
  publisher TEXT,
  source_type TEXT NOT NULL,
  source_url TEXT,
  license_or_terms TEXT,
  publication_frequency TEXT,
  trust_tier TEXT NOT NULL DEFAULT 'UNASSESSED',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS trade_events (
  trade_event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL CHECK (event_type IN ('TARIFF','SANCTION','EXPORT_CONTROL','CONFLICT','CHOKEPOINT')),
  issuing_authority TEXT NOT NULL,
  event_title TEXT NOT NULL,
  countries TEXT[] NOT NULL DEFAULT '{}',
  hs_codes TEXT[] NOT NULL DEFAULT '{}',
  hs_code_version TEXT,
  industry_ids TEXT[] NOT NULL DEFAULT '{}',
  effective_from DATE,
  effective_to DATE,
  review_date DATE,
  rate_or_value NUMERIC(18,6),
  currency CHAR(3),
  source_id TEXT REFERENCES evidence_sources(source_id),
  publication_date DATE,
  retrieved_at TIMESTAMPTZ NOT NULL,
  verification_status TEXT NOT NULL DEFAULT 'UNVERIFIED',
  classification TEXT NOT NULL DEFAULT 'PUBLIC_SOURCE',
  legal_status TEXT,
  source_url TEXT,
  provenance_note TEXT,
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);
CREATE TABLE IF NOT EXISTS trade_event_entities (
  trade_event_id TEXT NOT NULL REFERENCES trade_events(trade_event_id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  impact_type TEXT NOT NULL,
  PRIMARY KEY (trade_event_id, entity_type, entity_id, impact_type)
);
CREATE TABLE IF NOT EXISTS evidence_record_sources (
  evidence_id TEXT NOT NULL REFERENCES evidence_records(evidence_id) ON DELETE CASCADE,
  source_id TEXT NOT NULL REFERENCES evidence_sources(source_id),
  citation_text TEXT,
  PRIMARY KEY (evidence_id, source_id)
);
CREATE TABLE IF NOT EXISTS evidence_verification_events (
  verification_event_id TEXT PRIMARY KEY,
  evidence_id TEXT NOT NULL REFERENCES evidence_records(evidence_id) ON DELETE CASCADE,
  verifier_id TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  notes TEXT,
  verified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Incidents and graph snapshots (typed entity bridge tables avoid unsafe polymorphic FKs)
CREATE TABLE IF NOT EXISTS incident_supplier_links (
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  supplier_id TEXT NOT NULL REFERENCES suppliers(supplier_id),
  link_role TEXT NOT NULL,
  PRIMARY KEY (incident_id, supplier_id, link_role)
);
CREATE TABLE IF NOT EXISTS incident_component_links (
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  component_id TEXT NOT NULL REFERENCES components(component_id),
  link_role TEXT NOT NULL,
  PRIMARY KEY (incident_id, component_id, link_role)
);
CREATE TABLE IF NOT EXISTS incident_project_links (
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  project_id TEXT NOT NULL REFERENCES projects(project_id),
  link_role TEXT NOT NULL,
  PRIMARY KEY (incident_id, project_id, link_role)
);
CREATE TABLE IF NOT EXISTS incident_shipment_links (
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  shipment_id TEXT NOT NULL REFERENCES shipments(shipment_id),
  link_role TEXT NOT NULL,
  PRIMARY KEY (incident_id, shipment_id, link_role)
);
CREATE TABLE IF NOT EXISTS incident_impact_snapshots (
  impact_snapshot_id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  snapshot_version INTEGER NOT NULL,
  impacted_supplier_count INTEGER NOT NULL DEFAULT 0,
  impacted_component_count INTEGER NOT NULL DEFAULT 0,
  impacted_project_count INTEGER NOT NULL DEFAULT 0,
  uncovered_quantity NUMERIC(18,4),
  projected_slip_days NUMERIC(12,3),
  estimated_exposure_cost NUMERIC(18,2),
  currency CHAR(3),
  assumptions JSONB NOT NULL DEFAULT '[]'::jsonb,
  evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
  calculation_version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (incident_id, snapshot_version)
);
CREATE TABLE IF NOT EXISTS dependency_graph_snapshots (
  graph_snapshot_id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  direction TEXT NOT NULL DEFAULT 'UPSTREAM_TO_DOWNSTREAM' CHECK (direction='UPSTREAM_TO_DOWNSTREAM'),
  graph_version INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (incident_id, graph_version)
);
CREATE TABLE IF NOT EXISTS dependency_graph_nodes (
  graph_node_id TEXT PRIMARY KEY,
  graph_snapshot_id TEXT NOT NULL REFERENCES dependency_graph_snapshots(graph_snapshot_id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  node_label TEXT NOT NULL,
  tier TEXT,
  classification TEXT NOT NULL DEFAULT 'SYNTHETIC_DEMO',
  industry_ids TEXT[] NOT NULL DEFAULT '{}',
  UNIQUE (graph_snapshot_id, entity_type, entity_id)
);
CREATE TABLE IF NOT EXISTS dependency_graph_edges (
  graph_edge_id TEXT PRIMARY KEY,
  graph_snapshot_id TEXT NOT NULL REFERENCES dependency_graph_snapshots(graph_snapshot_id) ON DELETE CASCADE,
  from_node_id TEXT NOT NULL REFERENCES dependency_graph_nodes(graph_node_id) ON DELETE CASCADE,
  to_node_id TEXT NOT NULL REFERENCES dependency_graph_nodes(graph_node_id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL,
  evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
  CHECK (from_node_id <> to_node_id)
);

-- Workflow orchestration and stage tracker
CREATE TABLE IF NOT EXISTS workflow_runs (
  workflow_run_id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  run_status TEXT NOT NULL,
  current_stage_number SMALLINT CHECK (current_stage_number BETWEEN 1 AND 9),
  current_stage_key TEXT,
  overall_progress_percent NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (overall_progress_percent BETWEEN 0 AND 100),
  waiting_for_human BOOLEAN NOT NULL DEFAULT FALSE,
  replay_mode BOOLEAN NOT NULL DEFAULT FALSE,
  idempotency_key TEXT,
  requested_by TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  last_event_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  error_code TEXT,
  error_message TEXT,
  UNIQUE (requested_by, idempotency_key)
);
CREATE TABLE IF NOT EXISTS workflow_stages (
  workflow_stage_id TEXT PRIMARY KEY,
  workflow_run_id TEXT NOT NULL REFERENCES workflow_runs(workflow_run_id) ON DELETE CASCADE,
  stage_number SMALLINT NOT NULL CHECK (stage_number BETWEEN 1 AND 9),
  stage_key TEXT NOT NULL,
  stage_name TEXT NOT NULL,
  owner_type TEXT NOT NULL CHECK (owner_type IN ('PYTHON','AGENT','HUMAN')),
  owner_id TEXT,
  status TEXT NOT NULL,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  duration_ms BIGINT,
  output_ref TEXT,
  status_message TEXT,
  UNIQUE (workflow_run_id, stage_number)
);
CREATE TABLE IF NOT EXISTS workflow_parallel_lanes (
  lane_id TEXT PRIMARY KEY,
  workflow_run_id TEXT NOT NULL REFERENCES workflow_runs(workflow_run_id) ON DELETE CASCADE,
  stage_number SMALLINT NOT NULL DEFAULT 4 CHECK (stage_number=4),
  parallel_group_key TEXT NOT NULL DEFAULT 'ASSESSMENT',
  lane_key TEXT NOT NULL CHECK (lane_key IN ('SUPPLIER','LOGISTICS','RISK')),
  agent_run_id TEXT,
  status TEXT NOT NULL,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  output_ref TEXT,
  UNIQUE (workflow_run_id, parallel_group_key, lane_key)
);
CREATE TABLE IF NOT EXISTS workflow_events (
  workflow_event_id TEXT PRIMARY KEY,
  workflow_run_id TEXT NOT NULL REFERENCES workflow_runs(workflow_run_id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  stage_number SMALLINT,
  event_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Agent registry, prompt/model versioning and structured outputs
CREATE TABLE IF NOT EXISTS agent_definitions (
  agent_id TEXT PRIMARY KEY,
  agent_name TEXT NOT NULL,
  purpose TEXT NOT NULL,
  prompt_version TEXT NOT NULL,
  model_deployment TEXT NOT NULL,
  output_schema_version TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS workflow_run_id TEXT REFERENCES workflow_runs(workflow_run_id);
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS agent_id TEXT;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS model_deployment TEXT;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS prompt_version TEXT;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS input_hash TEXT;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS output_hash TEXT;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS input_payload JSONB;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS output_payload JSONB;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS error_payload JSONB;
ALTER TABLE agent_runs ADD COLUMN IF NOT EXISTS duration_ms BIGINT;
CREATE TABLE IF NOT EXISTS agent_output_records (
  agent_output_id TEXT PRIMARY KEY,
  agent_run_id TEXT NOT NULL REFERENCES agent_runs(agent_run_id) ON DELETE CASCADE,
  output_type TEXT NOT NULL,
  schema_version TEXT NOT NULL,
  structured_output JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Supplier/logistics/risk assessments, stored separately from agent text
CREATE TABLE IF NOT EXISTS supplier_assessments (
  supplier_assessment_id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  workflow_run_id TEXT REFERENCES workflow_runs(workflow_run_id),
  supplier_id TEXT NOT NULL REFERENCES suppliers(supplier_id),
  component_id TEXT NOT NULL REFERENCES components(component_id),
  qualification_status TEXT NOT NULL,
  spec_compatibility BOOLEAN,
  available_capacity NUMERIC(18,4),
  lead_time_days NUMERIC(12,3),
  evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
  assumptions JSONB NOT NULL DEFAULT '[]'::jsonb,
  assessed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS logistics_assessments (
  logistics_assessment_id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  workflow_run_id TEXT REFERENCES workflow_runs(workflow_run_id),
  route_id TEXT REFERENCES routes(route_id),
  shipment_id TEXT REFERENCES shipments(shipment_id),
  origin_port_id TEXT REFERENCES ports(port_id),
  destination_port_id TEXT REFERENCES ports(port_id),
  transit_days NUMERIC(12,3),
  feasibility_status TEXT NOT NULL,
  evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
  assessed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS risk_assessments (
  risk_assessment_id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  workflow_run_id TEXT REFERENCES workflow_runs(workflow_run_id),
  risk_category TEXT NOT NULL,
  risk_level TEXT NOT NULL,
  concentration_metric NUMERIC(18,6),
  narrative TEXT NOT NULL,
  evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
  assessed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Recovery plans, plan versions, action parameters and hard validation
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS plan_version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS currency CHAR(3);
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS allocated_qty NUMERIC(18,4);
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS quantity_unit TEXT;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS projected_slip_days NUMERIC(12,3);
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS incremental_cost NUMERIC(18,2);
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS co2e_kg NUMERIC(18,4);
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS rank_number INTEGER;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS feasibility TEXT;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS conditions JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS calculation_version TEXT;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS snapshot_id TEXT;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS supersedes_plan_id TEXT REFERENCES recovery_plans(plan_id);
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS created_by TEXT;
ALTER TABLE recovery_plans ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS action_sequence INTEGER;
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS quantity NUMERIC(18,4);
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS quantity_unit TEXT;
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS from_entity_type TEXT;
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS from_entity_id TEXT;
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS to_entity_type TEXT;
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS to_entity_id TEXT;
ALTER TABLE recovery_actions ADD COLUMN IF NOT EXISTS assumptions JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE plan_validation_runs ADD COLUMN IF NOT EXISTS validated_plan_hash TEXT;
ALTER TABLE plan_validation_runs ADD COLUMN IF NOT EXISTS calculation_version TEXT;
ALTER TABLE plan_validation_runs ADD COLUMN IF NOT EXISTS snapshot_id TEXT;
ALTER TABLE plan_validation_runs ADD COLUMN IF NOT EXISTS validator_version TEXT;
ALTER TABLE plan_validation_findings ADD COLUMN IF NOT EXISTS rule_name TEXT;
ALTER TABLE plan_validation_findings ADD COLUMN IF NOT EXISTS affected_action_ids JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE plan_validation_findings ADD COLUMN IF NOT EXISTS evidence_refs JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE plan_validation_findings ADD COLUMN IF NOT EXISTS acknowledgement_required BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS plan_versions (
  plan_version_id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL REFERENCES recovery_plans(plan_id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  plan_hash TEXT NOT NULL,
  plan_payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by TEXT,
  UNIQUE(plan_id, version_number),
  UNIQUE(plan_id, plan_hash)
);
CREATE TABLE IF NOT EXISTS plan_review_acknowledgements (
  acknowledgement_id TEXT PRIMARY KEY,
  approval_id TEXT,
  validation_id TEXT NOT NULL REFERENCES plan_validation_runs(validation_id),
  rule_code TEXT NOT NULL,
  acknowledged BOOLEAN NOT NULL,
  comment TEXT,
  acknowledged_by TEXT NOT NULL,
  acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE plan_approvals ADD COLUMN IF NOT EXISTS comment TEXT;
ALTER TABLE plan_approvals ADD COLUMN IF NOT EXISTS decision_payload JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE plan_approvals ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'RECORDED';
ALTER TABLE plan_approvals ADD COLUMN IF NOT EXISTS approver_role TEXT;

-- Simulation baseline/projected values are normalized and reproducible
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS incident_id TEXT REFERENCES incidents(incident_id);
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS plan_version INTEGER;
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS plan_hash TEXT;
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS approval_id TEXT REFERENCES plan_approvals(approval_id);
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS execution_status TEXT NOT NULL DEFAULT 'SIMULATED_NOT_EXECUTED';
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS calculation_version TEXT;
ALTER TABLE simulation_runs ADD COLUMN IF NOT EXISTS snapshot_id TEXT;
CREATE TABLE IF NOT EXISTS simulation_metrics (
  simulation_metric_id TEXT PRIMARY KEY,
  simulation_id TEXT NOT NULL REFERENCES simulation_runs(simulation_id) ON DELETE CASCADE,
  metric_name TEXT NOT NULL,
  baseline_value NUMERIC(20,6),
  projected_value NUMERIC(20,6),
  delta_value NUMERIC(20,6),
  unit TEXT NOT NULL,
  currency CHAR(3),
  UNIQUE(simulation_id, metric_name),
  CHECK (delta_value IS NULL OR baseline_value IS NOT NULL AND projected_value IS NOT NULL)
);

-- Audit, access and data ingestion controls
ALTER TABLE audit_events ADD COLUMN IF NOT EXISTS incident_id TEXT REFERENCES incidents(incident_id);
ALTER TABLE audit_events ADD COLUMN IF NOT EXISTS actor_type TEXT NOT NULL DEFAULT 'SYSTEM';
ALTER TABLE audit_events ADD COLUMN IF NOT EXISTS correlation_id TEXT;
ALTER TABLE audit_events ADD COLUMN IF NOT EXISTS before_payload JSONB;
ALTER TABLE audit_events ADD COLUMN IF NOT EXISTS after_payload JSONB;
CREATE TABLE IF NOT EXISTS app_users (
  user_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  email TEXT UNIQUE,
  identity_provider TEXT NOT NULL DEFAULT 'DEMO',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS app_roles (
  role_id TEXT PRIMARY KEY,
  role_name TEXT NOT NULL UNIQUE,
  description TEXT
);
CREATE TABLE IF NOT EXISTS user_role_assignments (
  user_id TEXT NOT NULL REFERENCES app_users(user_id) ON DELETE CASCADE,
  role_id TEXT NOT NULL REFERENCES app_roles(role_id),
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id, role_id)
);
CREATE TABLE IF NOT EXISTS data_ingestion_runs (
  ingestion_run_id TEXT PRIMARY KEY,
  source_id TEXT REFERENCES evidence_sources(source_id),
  dataset_name TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  status TEXT NOT NULL,
  rows_read BIGINT NOT NULL DEFAULT 0,
  rows_inserted BIGINT NOT NULL DEFAULT 0,
  rows_updated BIGINT NOT NULL DEFAULT 0,
  rows_rejected BIGINT NOT NULL DEFAULT 0,
  error_summary TEXT
);
CREATE TABLE IF NOT EXISTS data_quality_issues (
  quality_issue_id TEXT PRIMARY KEY,
  ingestion_run_id TEXT REFERENCES data_ingestion_runs(ingestion_run_id),
  table_name TEXT NOT NULL,
  record_key TEXT,
  severity TEXT NOT NULL,
  issue_code TEXT NOT NULL,
  issue_description TEXT NOT NULL,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ,
  resolution_note TEXT
);
CREATE TABLE IF NOT EXISTS api_idempotency_keys (
  idempotency_key TEXT PRIMARY KEY,
  requested_by TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_status INTEGER,
  response_payload JSONB,
  workflow_run_id TEXT REFERENCES workflow_runs(workflow_run_id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ
);

-- Indexes for common investigation, graph and workflow paths
CREATE INDEX IF NOT EXISTS ix_trade_events_effective ON trade_events(event_type,effective_from,effective_to);
CREATE INDEX IF NOT EXISTS ix_trade_events_hs_codes ON trade_events USING GIN(hs_codes);
CREATE INDEX IF NOT EXISTS ix_trade_events_countries ON trade_events USING GIN(countries);
CREATE INDEX IF NOT EXISTS ix_workflow_incident_started ON workflow_runs(incident_id,started_at DESC);
CREATE INDEX IF NOT EXISTS ix_workflow_stages_run_status ON workflow_stages(workflow_run_id,status);
CREATE INDEX IF NOT EXISTS ix_agent_runs_workflow ON agent_runs(workflow_run_id,agent_id);
CREATE INDEX IF NOT EXISTS ix_plan_incident_status ON recovery_plans(incident_id,status);
CREATE INDEX IF NOT EXISTS ix_audit_incident_time ON audit_events(incident_id,event_time DESC);
CREATE INDEX IF NOT EXISTS ix_evidence_provenance ON evidence_records(provenance,freshness_status);
CREATE INDEX IF NOT EXISTS ix_supplier_country_risk ON suppliers(country_id,risk_tier);
CREATE INDEX IF NOT EXISTS ix_facility_country ON facilities(country_id);
CREATE INDEX IF NOT EXISTS ix_graph_edges_from ON dependency_graph_edges(graph_snapshot_id,from_node_id);
CREATE INDEX IF NOT EXISTS ix_graph_edges_to ON dependency_graph_edges(graph_snapshot_id,to_node_id);
CREATE INDEX IF NOT EXISTS ix_inventory_latest ON inventory_snapshots(component_id,warehouse_id,snapshot_at DESC);
CREATE INDEX IF NOT EXISTS ix_shipments_status_eta ON shipments(status,estimated_arrival_date);

-- Common updated timestamp is managed by application/service layer.
