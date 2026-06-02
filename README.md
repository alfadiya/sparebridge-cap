# SpareBridge
### Emergency Cross-Plant Spare Part Matching — CAP Application on SAP BTP

---

## Overview

SpareBridge is a SAP CAP application that surfaces internal spare part availability the moment a breakdown is recorded and local stock is zero — before any external supplier is contacted.

Large industrial organisations running multiple plants already manage inventory, breakdowns, and inter-plant transfers in SAP. The data needed to make a good decision exists. The workflow to act on it under pressure does not. SpareBridge provides that missing link.

> **Note:** IOCL (Indian Oil Corporation) is used throughout this document as an illustrative example. The application is designed for any multi-plant industrial organisation operating on SAP.

---

## The Problem

### What already exists in SAP
- Material master and inventory data across all plants
- Stock Transfer Order (STO) capability for inter-plant transfers
- Maintenance notification and breakdown records

### What does not exist
When a breakdown occurs and local stock is zero, there is no automated workflow that:
1. Searches all plants for the required part
2. Validates which plants can safely spare stock (above safety threshold)
3. Estimates logistics effort and cost
4. Surfaces a ranked recommendation to the decision-maker
5. Initiates the STO on approval — without manual SAP navigation

Under operational pressure, teams default to calling an external supplier — not because internal stock is unavailable, but because finding it manually across a multi-plant SAP landscape takes time no one has during a breakdown.

### Example scenario *(illustrative)*
A critical pump seal fails at a refinery. Local stock: 0. External supplier: 3-day lead time. A nearby plant — 6 hours away by road — holds 4 units. The STO mechanism exists in SAP. The stock record is live. But no workflow connects the breakdown event to that stock. SpareBridge does.

---

## Solution

SpareBridge is a recommendation and execution layer on top of SAP's existing STO process. It does not replace SAP inventory management or introduce a parallel data store.

**Trigger → Search → Recommend → Approve → Execute → Track → Replenish**

Each step either reads from or writes to existing SAP objects. The STO, once approved, is a standard SAP transfer — SpareBridge simply automates its creation.

---

## Workflow

### Step 1 — Breakdown Entry
A maintenance engineer logs the breakdown. In production, this is triggered from an existing SAP maintenance notification (PM module). For the MVP, a dedicated entry screen is provided.

### Step 2 — Local Stock Check
SpareBridge checks warehouse stock for the required material at the breakdown plant. If stock is sufficient, no action is taken. If stock is zero, cross-plant matching triggers automatically.

### Step 3 — Cross-Plant Matching
The matching engine evaluates all participating plants in parallel:
- Current stock at each plant
- Configured safety stock per plant per material
- Transferable quantity (stock minus safety stock)
- Distance from breakdown plant
- Estimated transit time and logistics cost

Only plants with transferable quantity above zero are surfaced as candidates.

### Step 4 — Recommendation to Procurement Manager
Candidates are ranked (by transit time, cost, or configurable weight) and presented as a structured recommendation. No search, no calculation, one decision.

```
SPARE PART MATCH FOUND

  Part Required   :  Pump Seal 75mm
  Local Stock     :  0 units

  RECOMMENDED SOURCE
  Plant B  ·  2 units available
  Distance: 360 km  |  Transit: ~6 hrs  |  Est. Logistics: ₹5,000*

  [ Approve Internal Transfer ]     [ Proceed with Supplier ]
```
*Figures are illustrative estimates. Actual costs depend on courier and route.*

### Step 5 — Approval and STO Creation
On manager approval:
- A **Stock Transfer Order (STO)** is created in SAP automatically
- The supplying plant warehouse receives a structured dispatch notification (quantity, destination, deadline)
- No manual SAP navigation required from either plant

### Step 6 — Transfer Tracking
Both plants track status in real time:
`Approved → Dispatched → In Transit → Received → Complete`

SAP stock levels update at both plants on goods receipt confirmation.

### Step 7 — Replenishment
On transfer completion, SpareBridge raises a purchase requisition for the supplying plant to restore what was transferred. This step is automatic and requires no manual follow-up.

---

## MVP Scope

The MVP is a complete, working prototype using mock data for five plants. The data model, matching logic, and screens are identical to a production implementation. The only production delta is replacing mock seed data with live SAP connectivity — application logic is unchanged.

### Screens

| Screen | Purpose |
|---|---|
| Breakdown Entry | Log the breakdown event, required part, quantity, urgency |
| Match Results & Approval | Ranked transfer candidates with one-tap approval or supplier fallback |
| Transfer Tracking | Live status visible to both requesting and supplying plant |
| Dashboard | Internal vs supplier resolution rate, active transfers, logistics spend |

### Core Components

| Component | Responsibility |
|---|---|
| Data Model | Plants, Inventory, Breakdown Requests, Match Results, Transfer Orders |
| Matching Engine | Cross-plant stock query, safety stock validation, ranking |
| Approval Service | STO creation on approval, status propagation |
| Replenishment Service | Purchase requisition on transfer completion |
| Seed Data | 5 plants with GPS coordinates, representative stock, standard part codes |

---

## Technology

| Layer | Technology |
|---|---|
| Platform | SAP BTP |
| Application framework | SAP CAP (Cloud Application Programming Model) |
| Data layer | CDS models |
| UI | SAP Fiori Elements |
| Integration | Native SAP BTP — no middleware, no external database |

SpareBridge operates within the host organisation's existing SAP authentication and authorisation model. All data is read from and written to existing SAP objects. No external storage. No synchronisation overhead.

---

## Production Considerations

| Consideration | Position |
|---|---|
| STO process | SpareBridge automates creation; the underlying SAP STO process is unchanged |
| Safety stock rules | Configured per plant per material; transferable quantity respects these thresholds |
| Approval authority | Integrated with existing SAP authorisation roles |
| Trigger source | MVP uses manual entry; production connects to SAP PM maintenance notifications |
| Data residency | Fully within existing SAP landscape |
| Adoption risk | Runs inside the SAP environment operations and IT already trust |

---

## Expected Benefits

- Internal stock identified in seconds, not after a manual multi-plant search
- STO initiated automatically on approval — no manual SAP entry under pressure
- Supplying plant safety stock protected by configurable thresholds
- Both plants have full transfer visibility without phone calls
- Replenishment triggered automatically; no inventory gaps go unaddressed
- Dashboard gives management visibility into internal resolution rate over time

---

*SpareBridge · SAP BTP · CAP Application · Emergency Spare Part Transfer Workflow*
