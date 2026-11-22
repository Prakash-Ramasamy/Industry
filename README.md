I recommend one important design decision: Workflow and Agent Activity must be displayed together, but they must not look like two separate workflows.

The user should understand:
- Workflow = What is happening in the business process?
- Agent Activity = Which AI agent or system is doing the work, and what has it accomplished?
For example, the workflow stage is Parallel Assessments. Inside that stage, the user sees three agents working simultaneously: Supplier Assessor, Logistics Assessor and Risk Assessor.

This gives transparency into our seven agents without overwhelming the business user.

Below is the final consolidated prompt. It incorporates our earlier UX reviews, the nine-stage workflow, incident creation, entity identification, human approval, recovery planning and simulation.


# SupplyChain X – Replit Master UI/UX Design Prompt v3.0

## 1. Project objective

Redesign SupplyChain X as a simple, modern, enterprise-grade Supply Chain Resilience Decision Support Platform.

The application helps business users identify supply-chain disruptions, understand their impact, investigate dependencies, evaluate recovery options and make informed recovery decisions with AI assistance.

The current UI is too complex and exposes too many technical concepts directly to end users.

**The new design must be simple, intuitive, workflow-driven and business-user-friendly.**

Do not create a complex control tower with many menus, dashboards, charts and independent modules.

The entire application should revolve around three primary activities:

1. Create an incident.
2. View and investigate an incident.
3. Follow the incident workflow and make recovery decisions.

Preserve the existing backend architecture, PostgreSQL database model, seven specialist agents, deterministic Python services and multi-industry capabilities. Simplify only the user experience.

---

## 2. Most important UX principle: Workflow vs Agent Activity

This is the most important design requirement.

SupplyChain X has two related but different concepts:

### A. Business Workflow – What is happening?

The workflow represents the nine business/process stages through which an incident progresses.

Examples:
- Intake
- Evidence collection
- Impact investigation
- Parallel assessments
- Recovery planning
- Evaluation and assurance
- Human approval
- Re-simulation
- Executive summary

The workflow must be the PRIMARY visual element.

### B. AI Agent Activity – Who is doing the work?

Agent Activity explains which AI agent or deterministic system is executing a task inside a workflow stage.

Examples:
- Impact Investigator identifies affected suppliers and projects.
- Supplier Assessor evaluates supplier qualification and capacity.
- Logistics Assessor evaluates route and port feasibility.
- Risk Assessor evaluates concentration and disruption risks.
- Recovery Planner generates recovery options.
- Plan Assurance explains deterministic validation results.
- Executive Explainer prepares the executive summary.

Agent Activity must be displayed INSIDE the relevant workflow stage.

### Required presentation

Never display two independent timelines called Workflow and Agent Workflow.

Instead:

- Display one nine-stage workflow timeline.
- Every stage has its owner: Python, Agent, or Human.
- Completed stages can be expanded to see what happened.
- Running stages show live progress.
- Agent-owned stages show the agent name, task, status and concise output.
- Python-owned stages show the system operation being performed.
- Human approval shows a clear waiting-for-approval state.
- Agent execution details should be collapsible.

Example:

WORKFLOW STAGE 4: PARALLEL ASSESSMENTS

Status: In progress

Three activities execute simultaneously:

1. Supplier Assessor – Agent 2
   Evaluating supplier qualification, component compatibility and available capacity.

2. Logistics Assessor – Agent 3
   Evaluating port congestion, alternate routes and shipment feasibility.

3. Risk Assessor – Agent 4
   Evaluating supplier concentration, country exposure and disruption risks.

Show three compact activity cards within Stage 4, not three new workflow stages.

Each card should show:
- Agent name
- Agent number
- What it is evaluating
- Status: Queued / Running / Completed / Failed / Needs Review
- Short result
- Expandable details

The user should immediately understand that the business process is at Stage 4 and three AI agents are performing parallel assessments.

---

## 3. Main navigation – Keep it minimal

Use only the following primary navigation:

1. Incidents
2. Create Incident
3. Workflow

A small Admin section may contain:
- User roles
- Industry configuration
- Agent configuration
- System settings

Do not put the following as independent main navigation items:
- Suppliers
- Ports
- Warehouses
- Logistics
- Risk Register
- Trade Intelligence
- Recovery Plans
- Dependency Graph
- Evidence Library
- Agent Activity
- Audit Trail

These should appear contextually inside an incident detail page when required.

The application should have a clean sidebar, a simple header, clear page titles and consistent spacing.

Avoid unnecessary navigation and excessive cards.

---

## 4. Screen 1 – Incidents Home

This is the landing page after login.

Purpose: Help users understand which incidents exist and which ones require attention.

Display:

### Summary metrics
- Total incidents
- In progress
- Awaiting approval
- Completed

Keep these four metrics compact.

### Incident list

Each incident row/card must show:

- Incident ID
- Incident title
- Industry
- Severity
- Created date
- Current workflow stage
- Workflow progress
- Current status
- Last updated

Example:

INC-2026-001
BESS Battery Supplier Outage

Industry: Renewable Energy
Severity: High
Current stage: Parallel Assessments
Progress: Stage 4 of 9
Status: In Progress

Primary action: View Incident

Provide one prominent Create Incident button.

Allow basic filtering by:
- Status
- Severity
- Industry

Do not introduce complex dashboards, large charts, maps or visualizations on this landing page.

---

## 5. Screen 2 – Create Incident

Create a simple incident registration form.

Required fields:

- Incident title
- Industry
- Incident type
- Severity
- Incident description
- Expected disruption duration, if known
- Optional supporting document upload

Industry choices:

1. Renewable Energy (Solar + Wind + BESS)
2. Solar Energy
3. Semiconductors & Electronics
4. EV & Batteries
5. Automotive
6. Pharmaceuticals
7. Aerospace
8. Industrial Machinery

Keep the form short and clean.

Do not ask the user to enter supplier IDs, component IDs, shipment IDs, purchase order IDs or project IDs if these can be identified automatically.

After submitting the form, navigate to the next screen.

---

## 6. Screen 3 – Identify and Confirm Affected Entities

This is an important intermediate step between incident creation and workflow execution.

Page title: Confirm Affected Entities

Subtitle:
"We analysed your incident information and identified potentially affected supply-chain entities. Please review and confirm before starting the investigation."

### Identification process

The backend should:

1. Extract entity references from the incident description and uploaded documents.
2. Match extracted identifiers against PostgreSQL records.
3. Discover related entities through database relationships.
4. Return matched entities with confidence, evidence and source information.

The frontend must not invent entity matches or confidence values.

### Entity list

Display identified entities in a simple table:

- Entity type
- Entity ID
- Entity name
- Match confidence
- Source/evidence
- Confirmation status
- Edit action

Example flagship entities:

| Entity type | Entity ID |
|---|---|
| Supplier | SUP-014 |
| Component | BAT-MOD-480 |
| Purchase Order | PO-1007 |
| Shipment | SHIP-209 |
| Project | PRJ-SOLARWIND-02 |
| Milestone | MS-04 |

Allow the user to:
- Confirm an entity
- Exclude an incorrect entity
- Edit a matched entity
- Add another entity manually

Show confidence levels only when the backend supplies them.

Distinguish:
- Exact identifier match
- Strong relationship match
- Suggested match requiring review

Do not treat an LLM's self-reported confidence as verified matching confidence.

### Confirmation behavior

Do not allow the workflow to start when required entity references are unresolved.

Allow the user to save as draft and return later.

Primary button:
START WORKFLOW

Secondary actions:
- Back to Incident
- Save as Draft

When Start Workflow is clicked:
- Save the confirmed entity set.
- Save its version/snapshot.
- Create a workflow run.
- Generate a unique workflow_run_id.
- Start Stage 1.
- Navigate to the incident detail page.

Prevent duplicate workflow runs from repeated clicks using backend idempotency.

---

## 7. Screen 4 – Incident Detailed View

This is the MOST IMPORTANT screen.

All incident information and activities must be accessible from one page.

Page header:

INC-2026-001
BESS Battery Supplier Outage

Display:
- Severity
- Industry
- Incident status
- Creation date
- Current workflow stage
- Workflow progress

Use only four tabs:

1. Overview
2. Workflow
3. Recovery Plans
4. Evidence

Do not create more tabs unless there is a strong functional requirement.

### Tab 1: Overview

Display:

Incident description.

Affected entities:
- Supplier
- Component
- Purchase Order
- Shipment
- Port
- Warehouse
- Project
- Milestone

Impact summary:
- Affected order quantity
- Shipment quantity
- Available inventory
- Expected disruption duration
- Affected projects and milestones

Show only values supplied by the backend.

Include a compact dependency summary or expandable relationship view.

Do not make a complex interactive graph mandatory for the main experience.

### Tab 2: Workflow

This is the central operational screen.

At the top, show one clear nine-stage business workflow.

Use a horizontal stepper on desktop when readable and a vertical timeline where space is limited.

Stages:

1. Intake
   Owner: Python

2. Evidence collection
   Owner: Python

3. Impact investigation
   Owner: Python traversal, then Agent 1

4. Parallel assessments
   Owner: Agents 2, 3 and 4

5. Recovery planning
   Owner: Agent 5

6. Deterministic evaluation + assurance
   Owner: Python, then Agent 6

7. Human approval
   Owner: Human Approver

8. Re-simulation
   Owner: Python

9. Executive summary
   Owner: Agent 7

IMPORTANT:
Stage 4 has three parallel lanes but counts as one business workflow stage.

Do not change the stage numbering or create separate workflow stages for the three agents.

### Stage details

When a user selects a stage, show a details panel containing:

- Stage name
- Stage description
- Owner
- Status
- Start time
- Completion time
- Duration, when available
- Input summary
- Output summary
- Evidence references
- Related agent activity

For agent-owned stages, show the agent card inside the stage detail panel.

Example:

Impact Investigation

Executed by:
SCX-Impact-Investigator – Agent 1

Task:
Identify the downstream impact of the disrupted supplier.

Result:
- Identified affected component BAT-MOD-480.
- Found PO-1007.
- Identified shipment SHIP-209.
- Identified project PRJ-SOLARWIND-02.
- Identified milestone MS-04.

Show the actual backend output. Do not hardcode these results for other incidents.

### Agent Activity presentation

Inside relevant stages, show an expandable section titled:

"AI Agent Activity"

For each agent display:

- Agent name and number
- Purpose
- Status
- Started/completed time
- Short activity description
- Structured result
- Evidence references
- Model deployment
- Prompt version
- Input hash, where appropriate

Keep technical metadata collapsed under "Execution details".

Do not expose raw prompts, internal chain-of-thought or sensitive configuration.

For Python-owned stages, use a separate "System Activity" label rather than pretending an AI agent performed the task.

### Workflow status states

Show clear states:

- Queued
- Running
- Completed
- Failed
- Needs Review
- Waiting for Approval

The workflow must support:
- Polling GET /api/v1/incidents/{id}/status every 2–3 seconds while active, or server-sent events if implemented.
- Stop polling when the workflow reaches a terminal state or waits for human approval.
- Preserve progress when the user leaves the page and returns.
- Display meaningful errors and retry actions where safe.

Never show fake progress percentages or simulated agent completions.

---

## 8. Screen 5 – Recovery Plans

Show recovery options only after recovery planning and deterministic evaluation have completed.

Each recovery plan should display:

- Plan name and rank
- Proposed actions
- Allocated quantities
- Supplier and route choices
- Projected milestone slip days
- Incremental cost and currency, when supplied
- CO2e impact, when supplied
- Feasibility
- Conditions and assumptions
- Validation status

Possible action types:
- Alternate supplier
- Inventory transfer
- Reroute
- Expedite
- Split allocation
- Substitution

Show validation clearly:

PASS – All mandatory constraints satisfied.

BLOCK – A mandatory constraint failed. Approval must be disabled.

NEEDS_REVIEW – Additional human review is required.

For NEEDS_REVIEW:
- Show the exact review items.
- Require the approver to acknowledge each item.
- Persist acknowledgements.
- Permit approval only according to the configured policy.
- Never allow a BLOCK plan to be approved.

Allow users to compare recovery options without overwhelming them with technical details.

---

## 9. Screen 6 – Human Approval

Approval is a business decision, not an AI action.

Show:
- Selected recovery plan
- Plan version
- Plan hash
- Validation result
- Outstanding review items
- Cost and operational impact, when available
- Conditions and assumptions

Actions:
- Approve
- Reject
- Request Changes

Before sending approval:
- Show the plan hash and version in a confirmation dialog.
- Bind the decision to the exact plan ID, version and hash.
- Disable approval when validation is BLOCK.
- Return a conflict if the plan changes after review.
- Require a new approval for a changed plan version.

Request Changes should capture a comment and trigger a new planning/evaluation cycle, generating a new plan version.

Show an explicit approval status.

---

## 10. Screen 7 – Re-simulation and Executive Summary

After approval, execute the deterministic Python re-simulation.

Display a clear result screen:

"Recovery Simulation Result – SIMULATED / NOT EXECUTED"

Compare:

- Baseline milestone slip days
- Projected milestone slip days
- Baseline uncovered quantity
- Projected uncovered quantity
- Baseline cost
- Projected cost
- Cost delta
- CO2e, only when available

Define delta as:

Projected value minus baseline value.

Clearly show units and currency.

Do not present simulated outcomes as actual operational execution.

The Executive Explainer (Agent 7) prepares a concise business summary based on approved plan and simulation results.

Provide an on-screen report and PDF export/print view.

Include:
- Original disruption
- Business impact
- Approved recovery plan
- Before/after simulation
- Residual risks
- Approval record

---

## 11. Seven-agent architecture must remain intact

Use the existing seven specialist agents:

1. SCX-Impact-Investigator
2. SCX-Supplier-Assessor
3. SCX-Logistics-Assessor
4. SCX-Risk-Assessor
5. SCX-Recovery-Planner
6. SCX-Plan-Assurance
7. SCX-Executive-Explainer

The agents must be invoked through the existing backend orchestration architecture.

Do not implement agent orchestration in React.

Python and deterministic services own:
- Database matching
- Dependency traversal
- Impact calculations
- Candidate generation
- Optimization and ranking
- Hard-constraint validation
- Plan hashing
- Approval verification
- Re-simulation

LLMs must not invent numeric values or override deterministic validation.

Agent outputs must be structured and validated against backend schemas.

---

## 12. Flagship scenario – SCX-04

Use the existing canonical database fixture.

Scenario:
SCX-04 – Renewable Energy (Solar + Wind + BESS)

Incident:
INC-2026-001 – BESS Battery Supplier Outage

Connected synthetic entities:
- SUP-014
- BAT-MOD-480
- PO-1007
- SHIP-209
- PORT-07
- PORT-11
- WAREHOUSE-03
- PRJ-SOLARWIND-02
- MS-04

Use database CSV seed values as the source of truth.

Important known values:
- PO-1007: 600 units ordered.
- SHIP-209: 250 units in transit.
- WAREHOUSE-03: 220 on hand, 70 reserved, 150 available.
- SUP-022: capacity snapshot 400, qualification pending verification.
- SUP-031: capacity snapshot 300, qualification approved.
- PORT-07: congestion level 95.
- PORT-11: congestion level 46.
- ROUTE-0001: 12 days, USD 4,200.
- MS-04: Battery Commissioning, planned 21 December 2026.

These values are synthetic and must be retrieved from the backend fixture.

Do not use invented costs, expedite premiums, budgets, CO2e or geographical coordinates.

Do not copy illustrative values from earlier UI mockups over the canonical database fixture.

---

## 13. Technical frontend requirements

Use:
- React
- TypeScript
- Vite
- Tailwind CSS
- shadcn/ui
- React Router
- TanStack Query
- React Flow only where a graph genuinely improves understanding
- MapLibre only when verified or explicitly synthetic coordinate data is available

Keep the frontend component architecture modular.

Suggested structure:

src/
  app/
  components/
    layout/
    common/
    workflow/
    agents/
    incidents/
    entities/
    recovery/
  pages/
    IncidentsPage.tsx
    CreateIncidentPage.tsx
    ConfirmEntitiesPage.tsx
    IncidentDetailPage.tsx
  features/
    incident/
    workflow/
    agent-activity/
    recovery/
    approval/
    simulation/
  services/
    api/
  contracts/
    types.ts

Use the shared TypeScript contracts and canonical SCX-04 JSON fixture supplied separately.

Do not create competing frontend models or invent API response fields.

---

## 14. Backend integration

Use:

VITE_API_BASE_URL

Configure CORS for the deployed Replit frontend origin.

Use the existing demo-user identity/header mechanism agreed with the backend.

The frontend must support the agreed API contracts for:

- Create incident
- Identify entities
- Retrieve identified entities
- Confirm identified entities
- Start workflow
- Retrieve incident status
- Retrieve incident detail
- Retrieve workflow stages
- Retrieve agent runs
- Retrieve evidence
- Retrieve recovery plans
- Validate recovery plans
- Submit approval
- Re-simulate
- Retrieve executive summary

Use actual backend responses whenever available.

If an endpoint is not implemented, label the feature MOCK or DESIGN PLACEHOLDER. Never silently fabricate a successful backend response.

Support the demo replay mode using the same UI contracts so the demonstration remains usable if live Foundry calls are unavailable.

---

## 15. Visual design principles

The application must look like a modern enterprise SaaS product.

Use:
- Clean white or light-neutral background
- Dark navy navigation
- Blue primary action color
- Green for successful completion
- Amber for needs-review/warning
- Red for blocked/failed states
- Consistent icons
- Compact cards
- Clear typography
- Generous spacing
- Responsive layout

Accessibility:
- Target WCAG 2.1 AA.
- Never communicate severity or validation using colour alone.
- Provide icons and text labels.
- Ensure keyboard navigation and visible focus states.

Avoid:
- Too many cards
- Too many dashboard charts
- Excessive gradients
- Unnecessary animations
- Large decorative maps
- Separate agent dashboards
- Complex dependency graphs as the default screen
- Multiple independent workflow timelines
- Technical jargon in business-facing labels
- Fake live data
- Fake progress indicators

All times should be displayed consistently, with the timezone clear. Currency must include its ISO code.

---

## 16. Security and governance

- No EY client data or confidential company data in Replit.
- Use only synthetic demo data.
- No database credentials in frontend code.
- Backend is the only database access layer.
- Keep user roles for Analyst, Approver, Executive and Administrator.
- Enforce permissions on the backend.
- Audit incident creation, entity confirmation, workflow execution, plan changes, approval and simulation.
- Approval must be bound to the exact plan version and hash.
- Never claim that a simulated recovery was executed.

---

## 17. Development sequence

Build in the following order.

Phase 1:
- Application shell
- Minimal navigation
- Incidents Home
- Create Incident

Phase 2:
- Entity identification and confirmation
- Incident detail Overview

Phase 3:
- Nine-stage workflow tracker
- Expandable stage details
- Agent activity embedded within the relevant stages
- Three parallel assessment lanes

Phase 4:
- Recovery Plans
- Deterministic validation display
- Human approval

Phase 5:
- Re-simulation results
- Executive summary
- Evidence view

Phase 6:
- API integration
- Loading/error/empty states
- Demo replay mode
- Responsive and accessibility testing

Do not build every screen as a large dashboard before validating the main incident journey.

---

## 18. Final acceptance criteria

The application is accepted only when a business user can:

1. Open Incidents and understand existing incidents.
2. Create a new incident using a simple form.
3. See automatically identified entities.
4. Correct or confirm identified entities.
5. Start the investigation.
6. Follow the nine-stage business workflow.
7. Understand which agent is working inside each stage.
8. See the three parallel assessments without confusing them with separate workflow stages.
9. Review the generated recovery options.
10. Understand PASS, BLOCK and NEEDS_REVIEW.
11. Approve a valid plan or request changes.
12. View the deterministic before/after simulation.
13. Read the final executive summary.

A business user should be able to understand the application's basic journey without knowing what an LLM, agent framework, dependency graph or orchestration engine is.

**Final design philosophy:**

"One incident. One business workflow. Seven specialist AI agents working behind it. One informed human recovery decision."

Build a simple and polished product, not a collection of technical modules.

Before implementing, inspect the existing project and preserve working functionality and API integrations. Do not overwrite existing backend contracts or database structures without identifying the differences first.




<img width="509" height="464" alt="image" src="https://github.com/user-attachments/assets/3afa2905-803d-4dbe-a2f7-5e65f43364b3" />
