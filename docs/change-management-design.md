# Change Management Application Design

## Framework alignment
- **ITIL v4 Change Enablement**: classify change types (standard/normal/emergency), ensure authorization, schedule/review, and record outcomes.
- **COBIT BAI06 Manage Changes**: enforce controlled change lifecycle with approvals, testing, and post-implementation review.
- **ISO 27001 A.12.1.2**: require change control procedures, segregation of duties, and audit logging.
- **NIST 800-53 CM-3**: document change requests, approvals, tests, and documentation updates.

## Hosting platform
- Primary deployment on **Azure** (App Service + Azure SQL / PostgreSQL). Optional parity on AWS (ECS + RDS) or GCP (Cloud Run + Cloud SQL).

## Core data model (logical)

### A. `db_changerequest` (primary record)
| Column | Type | Notes / improvements |
| --- | --- | --- |
| `id` | UUID (PK) | Immutable primary key.
| `changenumber` | Text (unique) | Generated as `CHG-000123`. Use env prefix if needed (`${ENV}-CHG-000123`).
| `title` | Text | Required, indexed for search.
| `description` | Text | Multiline; consider Markdown support.
| `changetype` | Enum | Standard / Normal / Emergency.
| `category` | Enum | Network / Server / Cloud / Security / Endpoint / Application / Database / Other.
| `service_id` | UUID (FK) | Optional link to `cmdb_service` table for CMDB-lite.
| `environment` | Enum | Prod / Non-Prod / DR / Lab.
| `justification` | Text | Business justification.
| `impact` | Enum | Low / Medium / High.
| `risk` | Enum | Low / Medium / High.
| `priority` | Enum | P1/P2/P3/P4.
| `requested_by` | UUID (FK) | Default to current user.
| `owner` | UUID (FK) | Change owner.
| `implementation_group_id` | UUID (FK) | Map to Entra group or internal team table.
| `planned_start` | Timestamp | Required for Normal/Emergency once submitted.
| `planned_end` | Timestamp | Validate `planned_end > planned_start`.
| `window_notes` | Text | Implementation window notes.
| `downtime_required` | Boolean | Default false.
| `stakeholders_notified` | Boolean | Tracks if communication sent.
| `backout_plan` | Text | Required before approval.
| `test_plan` | Text | Optional; required for high risk.
| `validation_plan` | Text | Required before approval.
| `implementation_steps` | Text | Required before approval.
| `cab_required` | Boolean | Calculated by rules or set by admin override.
| `approver_group` | Enum | Manager / CAB / Security / App Owner / Change Manager.
| `status` | Enum | Draft, Submitted, Manager Approval Pending, CAB Approval Pending, Approved (Scheduled), Rejected, In Implementation, Implemented (Pending Review), Closed (Successful), Closed (Unsuccessful), Cancelled.
| `outcome` | Enum | Successful / Failed / Backed Out / Partial.
| `actual_start` | Timestamp | Set on implementation start.
| `actual_end` | Timestamp | Set on implementation end.
| `pir_notes` | Text | Post-implementation review notes.
| `audit_summary` | Text | Summary of evidence/controls.
| `emergency_reason` | Text | Required when `changetype = Emergency`.
| `is_high_risk` | Boolean | Computed: `risk = High OR impact = High`.
| `duration_mins` | Integer | Computed: `planned_end - planned_start` in minutes.
| `approval_stage` | Enum | None / Manager / CAB / Security / Final.
| `created_at` | Timestamp | Auto-managed.
| `updated_at` | Timestamp | Auto-managed.

**Suggested constraints & indexes**
- Unique index on `changenumber`.
- Index on `status`, `planned_start`, `owner`, `requested_by`.
- Check constraints for `planned_end > planned_start` and `actual_end > actual_start`.
- Required fields on submit: `title`, `description`, `justification`, `backout_plan`, `implementation_steps`, `validation_plan`.

### B. `changetask`
| Column | Type | Notes / improvements |
| --- | --- | --- |
| `id` | UUID (PK) |  |
| `change_request_id` | UUID (FK) | Parent change.
| `task_name` | Text | Required.
| `task_type` | Enum | Prep / Implementation / Validation / Communication.
| `assigned_to` | UUID (FK) | User.
| `planned_start` | Timestamp |  |
| `planned_end` | Timestamp |  |
| `status` | Enum | Not Started / In Progress / Blocked / Done.
| `notes` | Text |  |
| `sequence` | Integer | Optional ordering.

### C. `changeapproval`
| Column | Type | Notes / improvements |
| --- | --- | --- |
| `id` | UUID (PK) |  |
| `change_request_id` | UUID (FK) | Parent change.
| `stage` | Enum | Manager / CAB / Security / Emergency CAB / Post Review.
| `approver_id` | UUID (FK) | User.
| `decision` | Enum | Approved / Rejected / Requested More Info.
| `decision_date` | Timestamp |  |
| `comments` | Text |  |
| `approval_instance_id` | Text | Optional external workflow ID.

### D. `changecomms`
| Column | Type | Notes / improvements |
| --- | --- | --- |
| `id` | UUID (PK) |  |
| `change_request_id` | UUID (FK) | Parent change.
| `audience` | Enum | All Staff / IT / Site / Specific Users.
| `recipients` | Text | CSV or JSON list; prefer child table for per-recipient audit.
| `method` | Enum | Email / Teams / Other.
| `sent_on` | Timestamp |  |
| `notes` | Text |  |

### E. `changetemplate`
| Column | Type | Notes / improvements |
| --- | --- | --- |
| `id` | UUID (PK) |  |
| `name` | Text | Required.
| `type` | Enum | Standard / Normal.
| `category` | Enum | Same as change categories.
| `default_steps` | Text | Use child `templatetask` for structured steps.
| `default_backout` | Text |  |
| `default_test` | Text |  |
| `default_validation` | Text |  |
| `default_risk` | Enum | Low / Medium / High.
| `default_impact` | Enum | Low / Medium / High.
| `requires_cab` | Boolean |  |
| `created_at` | Timestamp |  |

### F. `changeartifact` (attachments)
| Column | Type | Notes / improvements |
| --- | --- | --- |
| `id` | UUID (PK) |  |
| `change_request_id` | UUID (FK) | Parent change.
| `artifact_type` | Enum | Plan / Evidence / Screenshot / Log / Other.
| `file_url` | Text | Blob storage URL.
| `uploaded_by` | UUID (FK) |  |
| `uploaded_at` | Timestamp |  |

## Relationships
- Change Request **1—Many** Change Tasks.
- Change Request **1—Many** Approval Logs.
- Change Request **1—Many** Communications.
- Template **1—Many** Template Tasks.
- Change Request **1—Many** Artifacts.
- Optional: `cmdb_service` **1—Many** Change Requests.

## Approval flow (complete)
1. **Draft → Submitted**
   - Validate required fields: description, justification, backout plan, implementation steps, validation plan.
   - If `changetype = Emergency`, require emergency justification.
2. **Manager Approval**
   - Default for Normal/Emergency, unless `requested_by` is manager.
   - If approved, determine CAB requirement and move to CAB stage if needed.
3. **CAB / Security / App Owner**
   - If `is_high_risk`, `impact = High`, or category in Security/Network/Cloud, route to CAB and/or Security.
   - Emergency changes route to **Emergency CAB** (expedited, parallel approvals).
4. **Final Approval & Scheduling**
   - On approvals complete, set status to **Approved (Scheduled)**.
   - Enforce scheduling window and conflict checks (calendar).
5. **Implementation**
   - Change owner sets **In Implementation**, captures actual start/end.
   - Track tasks in `changetask` and communications in `changecomms`.
6. **Post-Implementation Review (PIR)**
   - Record outcome, PIR notes, and evidence (artifacts).
7. **Closure**
   - Success → **Closed (Successful)**.
   - Failure/backout → **Closed (Unsuccessful)** or **Cancelled**.

## Automation recommendations
- Use rule engine for `cab_required`, `approval_stage`, and high-risk flags.
- Auto-notify stakeholders on submission, approval, scheduling, and closure.
- Daily job to flag overdue PIRs and update audit summary.
