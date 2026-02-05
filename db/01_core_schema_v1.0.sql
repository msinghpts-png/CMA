/* ## Change Management Database – Core Schema (v1.0)

**Target:** SQL Server Express (tested)
**Important:** Run this script ONLY after the database has been created and context switched.

```sql*/
USE ChangeManagementDB;
GO

/* ```
---
## 1. Schemas

```sql*/
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='ref')   EXEC('CREATE SCHEMA ref');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='cm')    EXEC('CREATE SCHEMA cm');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='sec')   EXEC('CREATE SCHEMA sec');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='cfg')   EXEC('CREATE SCHEMA cfg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='audit') EXEC('CREATE SCHEMA audit');
GO
/*```
---
## 2. Local Users (sec.AppUser)

```sql*/
CREATE TABLE sec.AppUser (
  UserId uniqueidentifier NOT NULL DEFAULT newsequentialid() PRIMARY KEY,
  UserPrincipalName nvarchar(256) NOT NULL UNIQUE,
  DisplayName nvarchar(200) NOT NULL,
  IsActive bit NOT NULL DEFAULT 1,
  CreatedAt datetime2(0) NOT NULL DEFAULT sysutcdatetime(),
  UpdatedAt datetime2(0) NOT NULL DEFAULT sysutcdatetime(),
  RowVersion rowversion NOT NULL
);
GO
/*```
---
## 3. Reference Tables (Lookup Pattern)
> Same structure used for all enums (ITIL / COBIT safe)
```sql*/

CREATE TABLE ref.ChangeType (
  ChangeTypeId int IDENTITY PRIMARY KEY,
  Code nvarchar(50) NOT NULL UNIQUE,
  Name nvarchar(200) NOT NULL UNIQUE,
  IsActive bit NOT NULL DEFAULT 1,
  SortOrder int NOT NULL DEFAULT 0
);
GO

/*```
> Repeat this table structure for:
* ChangeCategory
* Environment
* ImpactLevel
* RiskLevel
* Priority
* ChangeStatus
* Outcome
* TaskType
* TaskStatus
* ApprovalStage
* ApprovalDecision
* CommunicationAudience
* CommunicationMethod
* ArtifactType
---
## 4. Change Request (cm.ChangeRequest)
```sql*/

CREATE TABLE cm.ChangeRequest (
  ChangeRequestId uniqueidentifier NOT NULL DEFAULT newsequentialid() PRIMARY KEY,
  ChangeNumber nvarchar(20) NOT NULL UNIQUE,
  Title nvarchar(300) NOT NULL,
  Description nvarchar(max) NOT NULL,
  Justification nvarchar(max) NULL,

  ChangeTypeId int NOT NULL,
  ChangeCategoryId int NOT NULL,
  EnvironmentId int NOT NULL,
  ImpactLevelId int NOT NULL,
  RiskLevelId int NOT NULL,
  PriorityId int NOT NULL,
  ChangeStatusId int NOT NULL,

  RequestedByUserId uniqueidentifier NOT NULL,
  OwnerUserId uniqueidentifier NOT NULL,

  PlannedStartAt datetime2(0) NULL,
  PlannedEndAt datetime2(0) NULL,
  HasDowntime bit NOT NULL DEFAULT 0,

  BackoutPlan nvarchar(max) NULL,
  ValidationPlan nvarchar(max) NULL,
  ImplementationSteps nvarchar(max) NULL,

  ActualStartAt datetime2(0) NULL,
  ActualEndAt datetime2(0) NULL,
  OutcomeId int NULL,
  PirNotes nvarchar(max) NULL,

  CreatedAt datetime2(0) NOT NULL DEFAULT sysutcdatetime(),
  UpdatedAt datetime2(0) NOT NULL DEFAULT sysutcdatetime(),
  RowVersion rowversion NOT NULL,

  CONSTRAINT CK_CR_Planned CHECK (PlannedEndAt IS NULL OR PlannedEndAt > PlannedStartAt),
  CONSTRAINT CK_CR_Actual CHECK (ActualEndAt IS NULL OR ActualEndAt > ActualStartAt)
);
GO

/*```
---
## 5. Audit Framework
### audit.EventType
```sql*/

CREATE TABLE audit.EventType (
  EventTypeId int IDENTITY PRIMARY KEY,
  Code nvarchar(80) NOT NULL UNIQUE,
  Name nvarchar(200) NOT NULL,
  SortOrder int NOT NULL DEFAULT 0
);
GO

/*```
### audit.Event
```sql*/

CREATE TABLE audit.Event (
  AuditEventId uniqueidentifier NOT NULL DEFAULT newsequentialid() PRIMARY KEY,
  EventTypeId int NOT NULL,
  EventAt datetime2(0) NOT NULL DEFAULT sysutcdatetime(),
  ActorUserId uniqueidentifier NULL,
  ActorUpn nvarchar(256) NULL,
  EntitySchema nvarchar(50) NULL,
  EntityName nvarchar(100) NULL,
  EntityId uniqueidentifier NULL,
  ChangeNumber nvarchar(20) NULL,
  Reason nvarchar(500) NULL,
  Details nvarchar(max) NULL
);
GO

/*```
### audit.EventFieldChange
```sql*/

CREATE TABLE audit.EventFieldChange (
  AuditEventFieldChangeId uniqueidentifier NOT NULL DEFAULT newsequentialid() PRIMARY KEY,
  AuditEventId uniqueidentifier NOT NULL,
  FieldName nvarchar(200) NOT NULL,
  OldValue nvarchar(max) NULL,
  NewValue nvarchar(max) NULL
);
GO

/*```
---
## 6. Core Lifecycle Stored Procedures (SQL Express Safe)
### Submit Change
```sql*/

CREATE PROCEDURE cm.usp_SubmitChangeRequest
  @ChangeRequestId uniqueidentifier,
  @ActorUserId uniqueidentifier
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE cm.ChangeRequest
  SET ChangeStatusId = (SELECT ChangeStatusId FROM ref.ChangeStatus WHERE Code='SUBMITTED')
  WHERE ChangeRequestId=@ChangeRequestId;

  EXEC audit.usp_WriteEvent
    @EventTypeCode='CHANGE_SUBMITTED',
    @ActorUserId=@ActorUserId,
    @EntitySchema='cm',
    @EntityName='ChangeRequest',
    @EntityId=@ChangeRequestId;
END;
GO

/*```
---
**DB Version:** 1.0 (Core)*/
