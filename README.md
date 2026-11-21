1. Critical issues – decisions and corrections
#	Review finding	My recommended correction
1	Scenario IDs conflict across documents	Standardize all scenario IDs and explicitly link INC-2026-001 to its flagship scenario.
2	Workflow does not match backend	Add Executive Summary as stage 11; correct ownership and parallel execution.
3	Stage status API has no payload	Define the complete workflow status response and add PENDING / WAITING_FOR_HUMAN agent states.
4	Main screens lack typed payloads	Define TypeScript interfaces for RecoveryPlan, ValidationResult, DependencyGraph, ImpactResponse, EvidenceRecord, AuditEvent, ExecutiveSummary, Agent outputs and dashboard.
5	NEEDS_REVIEW approval is ambiguous	Define explicit review acknowledgements, persist them, and allow approval only after all required acknowledgements. BLOCK can never be approved.
6	Relationship enum differs from backend	Align relationship types and define one consistent upstream-to-downstream direction.
7	Master entity contract is incomplete	Add Warehouse, Facility, Country, Industry, Carrier, AuditEvent and EvidenceSource.
8	Replit prompt is cut off	Supply the complete master prompt separately as a TXT file.

2. Correct workflow
The reviewer has identified a significant issue: supplier, logistics and risk assessments should execute in parallel.

I recommend this 11-stage workflow:
1. Intake – Python workflow
2. Evidence collection – Python evidence services
3. Impact investigation – Python graph traversal, then Investigator Agent
4. Parallel assessments
   Supplier Assessor
   
   Logistics Assessor
   
   Risk Assessor
5. Recovery planning – Recovery Planner Agent
6. Deterministic evaluation + assurance – Python calculates, ranks and validates; Plan Assurance Agent explains
7. Human approval – Authorized approver
8. Re-simulation – Python simulation engine
9. Executive summary – Executive Explainer Agent

The stage tracker must show parallel execution, not three sequential steps.
3. Other important corrections
I would also include these changes:
- Add an Executive Summary tab to the incident workspace.
- Add EVALUATING, SIMULATING and CLOSED to IncidentStatus.
- Define request-changes behavior: rerun Planner and evaluation, create plan version 2, and require approval again.
- Add a distinction between Renewable Energy, Solar Energy and EV & Batteries to avoid duplicate industry exposure.
- Make only the flagship scenario backend-connected initially; label the remaining scenarios as synthetic mock fixtures.
- Add workflow progress persistence so users can leave and return during a 1–3 minute agent run.
- Add an optional Demo Replay Mode using recorded fixture runs.
- Make Playwright testing optional for Replit, while retaining essential unit and integration checks.
4. Backend integration needs to be explicit
The new specification should classify every endpoint as LIVE or MOCK.

It should also define:
- VITE_API_BASE_URL for the frontend API base URL.
- FastAPI CORS configuration for the Replit frontend domain.
- Demo-user authentication/token behavior.
- POST /investigate returning HTTP 202, a workflow_run_id and idempotency handling.
- A supplied JSON fixture file as the only source of mock costs, lead times, budgets and transit days.
- A replay adapter that can reproduce the same workflow when live Foundry calls are slow or unavailable.
Important: Replit must not invent its own fixture quantities or costs. The frontend and backend must consume the same fixture definitions.
5. One important clarification before v2.2
There is a flagship conflict in the first review:
- v2.1 calls Renewable Energy (Solar + Wind + BESS) the flagship.
- The new reviewer explicitly says to keep SCX-04 as the flagship because it is the scenario associated with INC-2026-001.
- The reviewer describes SCX-04 as a solar module disruption, while the existing incident is the BESS battery-module disruption.
I don't want to silently change the project identity or create another mismatch across your leadership blueprint, database fixtures and UI.

Which flagship should we standardize across all project documents?

A. Renewable Energy (Solar + Wind + BESS)

Keep INC-2026-001 as the BESS battery-module disruption and assign it one consistent flagship scenario ID.


B. Solar Energy

Make the solar module disruption SCX-04 the flagship and change the main incident fixture accordingly.


C. Renewable Energy portfolio

Keep both solar and BESS in the flagship portfolio, with separate scenario IDs and a clearly identified primary incident.


Confirm flagship direction
