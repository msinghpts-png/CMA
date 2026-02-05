/*## Change Management Database – Demo Data (v1.0)*/

USE ChangeManagementDB;
GO

/*
## Demo Users*/


INSERT INTO sec.AppUser (UserPrincipalName,DisplayName)
VALUES
('demo.requestor@local','Demo Requestor'),
('demo.owner@local','Demo Change Owner'),
('demo.manager@local','Demo Manager');

/*
## Demo Change Request*/

DECLARE @req uniqueidentifier = (SELECT UserId FROM sec.AppUser WHERE UserPrincipalName='demo.requestor@local');
DECLARE @own uniqueidentifier = (SELECT UserId FROM sec.AppUser WHERE UserPrincipalName='demo.owner@local');

INSERT INTO cm.ChangeRequest (
  ChangeNumber,Title,Description,Justification,
  ChangeTypeId,ChangeCategoryId,EnvironmentId,ImpactLevelId,RiskLevelId,PriorityId,ChangeStatusId,
  RequestedByUserId,OwnerUserId,
  BackoutPlan,ValidationPlan,ImplementationSteps
)
VALUES (
  NULL,
  'Demo – Windows Server Patching',
  'Apply monthly patches to production server',
  'Security compliance and vulnerability remediation',
  (SELECT ChangeTypeId FROM ref.ChangeType WHERE Code='NORMAL'),
  (SELECT ChangeCategoryId FROM ref.ChangeCategory WHERE Code='SERVER'),
  (SELECT EnvironmentId FROM ref.Environment WHERE Code='PROD'),
  (SELECT ImpactLevelId FROM ref.ImpactLevel WHERE Code='MED'),
  (SELECT RiskLevelId FROM ref.RiskLevel WHERE Code='MED'),
  (SELECT PriorityId FROM ref.Priority WHERE Code='P2'),
  (SELECT ChangeStatusId FROM ref.ChangeStatus WHERE Code='DRAFT'),
  @req,@own,
  'Restore snapshot if issues occur',
  'Verify services and event logs',
  'Snapshot → Patch → Reboot → Validate'
);

/*
## Demo Audit Event*/

DECLARE @cr uniqueidentifier = (SELECT TOP 1 ChangeRequestId FROM cm.ChangeRequest ORDER BY CreatedAt DESC);
DECLARE @chg nvarchar(20) = (SELECT ChangeNumber FROM cm.ChangeRequest WHERE ChangeRequestId=@cr);

EXEC audit.usp_WriteEvent
  @EventTypeCode='CHANGE_CREATED',
  @ActorUpn='demo.requestor@local',
  @ActorDisplayName='Demo Requestor',
  @EntitySchema='cm',
  @EntityName='ChangeRequest',
  @EntityId=@cr,
  @ChangeNumber=@chg,
  @Reason='Demo record creation';

/*
**Demo Version:** 1.0 */
