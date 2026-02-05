# Change Management Application Data Model

## Guiding Framework Alignment
- **ITIL v4 Change Enablement**: risk-based approvals, authorization, scheduling windows, PIR, and audit evidence.
- **COBIT BAI06**: standardized changes, change backlog, segregation of duties, and traceability.
- **ISO 27001 A.12.1.2**: controlled change process with approvals and evidence.
- **NIST 800-53 CM-3**: documented approvals, configuration control board (CAB), and impact assessment.

## Core Entities

### A. `db_changerequest`
Main record for change control.

**Recommended field improvements**
| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID (PK) | Use UUID for distributed workflows. |
| `changenumber` | Text, unique | Generated from `CHG-` prefix + sequence; keep immutable. |
| `title` | Text | Required, indexed. |
| `description` | Text | Required, full-text index. |
| `changetype` | Enum | Standard / Normal / Emergency. |
| `category` | Enum | Add `Other` with freeform `category_other`. |
| `service_id` | UUID | FK to service table (`cmdb_service`). |
| `environment` | Enum | Prod / Non-Prod / DR / Lab. |
| `justification` | Text | Required. |
| `impact` | Enum | Low / Medium / High. |
| `risk` | Enum | Low / Medium / High. |
| `priority` | Enum | P1/P2/P3/P4 or Low/Med/High; standardize to one scheme. |
| `requested_by` | UUID | FK to `user`. |
| `owner_id` | UUID | FK to `user`. |
| `impl_group_id` | UUID | FK to group mapping; map to Entra group. |
| `planned_start` | Timestamptz | Required. |
| `planned_end` | Timestamptz | Required; add CHECK `planned_end > planned_start`. |
| `window_notes` | Text | Optional. |
| `downtime_required` | Boolean | Required for scheduling gates. |
| `stakeholders_notified` | Boolean | Used by closure checklist. |
| `backout_plan` | Text | Required before approvals. |
| `test_plan` | Text | Optional for standard; required for normal/emergency. |
| `validation_plan` | Text | Required before implementation start. |
| `implementation_steps` | Text | Required for normal/emergency. |
| `cab_required` | Boolean | Calculated from risk/impact/type thresholds. |
| `approver_group` | Enum | Manager / CAB / Security / App Owner. |
| `status` | Enum | Draft, Submitted, Manager Approval Pending, CAB Approval Pending, Approved (Scheduled), Rejected, In Implementation, Implemented (Pending Review), Closed (Successful), Closed (Unsuccessful), Cancelled. |
| `outcome` | Enum | Successful / Failed / Backed Out / Partial. |
| `actual_start` | Timestamptz | Recorded at execution. |
| `actual_end` | Timestamptz | Recorded at execution. |
| `pir_notes` | Text | PIR detail. |
| `audit_summary` | Text | Controls evidence. |
| `emergency_reason` | Text | Required when `changetype = Emergency`. |
| `approval_stage` | Enum | None / Manager / CAB / Security / Final. |
| `duration_mins` | Integer | Generated from planned window. |
| `is_high_risk` | Boolean | Generated from risk/impact. |
| `created_at` | Timestamptz | Audit fields. |
| `updated_at` | Timestamptz | Audit fields. |
| `deleted_at` | Timestamptz | Optional soft delete. |

**Indexes**
- `changenumber` unique index.
- Composite index `(status, planned_start)` for calendar queries.
- Full-text index on `title`, `description`, `justification`.

### B. `change_task`
Breaks a change into tracked steps.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID (PK) | |
| `change_id` | UUID | FK to `db_changerequest`. |
| `task_name` | Text | Required. |
| `task_type` | Enum | Prep / Implementation / Validation / Communication. |
| `assigned_to` | UUID | FK to `user`. |
| `planned_start` | Timestamptz | |
| `planned_end` | Timestamptz | |
| `status` | Enum | Not Started / In Progress / Blocked / Done. |
| `notes` | Text | |
| `sequence` | Integer | Order for execution. |

### C. `change_approval`
Approval history for auditability.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID (PK) | |
| `change_id` | UUID | FK to `db_changerequest`. |
| `stage` | Enum | Manager / CAB / Security / Emergency CAB / Post Review. |
| `approver_id` | UUID | FK to `user`. |
| `decision` | Enum | Approved / Rejected / Requested More Info. |
| `decision_date` | Timestamptz | |
| `comments` | Text | |
| `approval_instance_id` | Text | Optional workflow engine ID. |

### D. `change_comms`
Communications tracking.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID (PK) | |
| `change_id` | UUID | FK to `db_changerequest`. |
| `audience` | Enum | All Staff / IT / Site / Specific Users. |
| `method` | Enum | Email / Teams / Other. |
| `sent_on` | Timestamptz | |
| `notes` | Text | |

### E. `change_template`
Reusable templates.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID (PK) | |
| `name` | Text | Required, unique. |
| `type` | Enum | Standard / Normal. |
| `category` | Enum | |
| `default_steps` | Text | Optional if `template_task` used. |
| `default_backout` | Text | |
| `default_test` | Text | |
| `default_validation` | Text | |
| `default_risk` | Enum | |
| `default_impact` | Enum | |
| `requires_cab` | Boolean | |
| `created_by` | UUID | |

### F. `template_task` (optional)
Child tasks for templates.

### G. `change_artifact` (optional)
Structured file storage for evidence.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID (PK) | |
| `change_id` | UUID | FK to `db_changerequest`. |
| `artifact_type` | Enum | Screenshot / Evidence / Plan / Other. |
| `file_url` | Text | Storage URI (Azure Blob/AWS S3). |
| `uploaded_by` | UUID | |
| `uploaded_at` | Timestamptz | |

## Relationships
- `db_changerequest` 1—Many `change_task`
- `db_changerequest` 1—Many `change_approval`
- `db_changerequest` 1—Many `change_comms`
- `change_template` 1—Many `template_task`
- `db_changerequest` 1—Many `change_artifact`

## Platform Notes (Azure-first)
- Store files in **Azure Blob Storage**; retain URIs in `change_artifact`.
- Use **Azure SQL** or **PostgreSQL** with read replicas for reporting.
- Consider **Azure Logic Apps / Power Automate** for approval workflows and Teams notifications.
