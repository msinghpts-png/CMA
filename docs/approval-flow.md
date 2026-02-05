# Approval Flow & Lifecycle

## Key Rules
1. **Draft → Submitted**: Validate mandatory fields (title, description, justification, backout plan, planned window).
2. **Risk-based routing**:
   - **Standard**: Auto-approve if template is pre-authorized and risk/impact low.
   - **Normal**: Manager approval required; CAB required if `risk = High` or `impact = High`.
   - **Emergency**: Emergency CAB + post-implementation review required.
3. **Segregation of duties**: Requester cannot be final approver.
4. **Audit**: All decisions written to `change_approval`.

## Submit / Approve Change Flow
1. **Draft** → user completes fields and submits.
2. System evaluates:
   - `cab_required = (risk = High OR impact = High OR changetype = Emergency)`.
   - `approval_stage = Manager` for Normal, `CAB` for high risk, `Emergency CAB` for emergency.
3. **Manager Approval**:
   - Approve → next stage (CAB/Security if required).
   - Reject → status = Rejected.
   - Request Info → status = Submitted with comment; notify requester.
4. **CAB Approval** (if required):
   - Approve → Security review (optional) or Approved (Scheduled).
   - Reject → status = Rejected.
5. **Security Approval** (if required by category or policy):
   - Approve → status = Approved (Scheduled).
   - Reject → status = Rejected.
6. **Scheduling**:
   - Enforce change window and blackout constraints.
   - Set `planned_start`, `planned_end` and notify stakeholders.

## Implementation & PIR Flow
1. **In Implementation**: set `actual_start` and track `change_task`.
2. **Implemented (Pending Review)**: set `actual_end`, collect validation evidence.
3. **Post-Implementation Review (PIR)**:
   - Capture outcome, PIR notes, and audit summary.
   - Update `change_approval` with Post Review approval.
4. **Closure**:
   - `Closed (Successful)` or `Closed (Unsuccessful)`; set `outcome`.
   - Ensure communication log completed.

## Automation Triggers
- **On Submit**: Create approval tasks and notify approvers via email/Teams.
- **On Approval**: Advance `approval_stage`, record approval log.
- **On Implementation Start**: Lock schedule changes except by CAB.
- **On PIR Complete**: Close change, update KPIs.
