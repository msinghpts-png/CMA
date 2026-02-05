/*## Change Management Database – Seed Data (v1.0)*/


USE ChangeManagementDB;
GO

/*## Change Types*/


INSERT INTO ref.ChangeType (Code,Name,SortOrder)
VALUES ('STANDARD','Standard',1),('NORMAL','Normal',2),('EMERGENCY','Emergency',3);


/*## Change Categories*/


INSERT INTO ref.ChangeCategory (Code,Name,SortOrder)
VALUES
('NETWORK','Network',1),('SERVER','Server',2),('CLOUD','Cloud',3),('SECURITY','Security',4),
('ENDPOINT','Endpoint',5),('APPLICATION','Application',6),('DATABASE','Database',7),('OTHER','Other',99);


/*## Environments*/


INSERT INTO ref.Environment (Code,Name,SortOrder)
VALUES ('PROD','Production',1),('NONPROD','Non-Production',2),('DR','Disaster Recovery',3),('LAB','Lab',4);


/*## Risk / Impact*/


INSERT INTO ref.RiskLevel (Code,Name,SortOrder) VALUES ('LOW','Low',1),('MED','Medium',2),('HIGH','High',3);
INSERT INTO ref.ImpactLevel (Code,Name,SortOrder) VALUES ('LOW','Low',1),('MED','Medium',2),('HIGH','High',3);


/*## Priority*/


INSERT INTO ref.Priority (Code,Name,SortOrder)
VALUES ('P1','Critical',1),('P2','High',2),('P3','Medium',3),('P4','Low',4);


/*## Change Status Lifecycle*/


INSERT INTO ref.ChangeStatus (Code,Name,SortOrder)
VALUES
('DRAFT','Draft',1),
('SUBMITTED','Submitted',2),
('MGR_PENDING','Manager Approval Pending',3),
('CAB_PENDING','CAB Approval Pending',4),
('APPROVED_SCHEDULED','Approved (Scheduled)',5),
('IN_IMPL','In Implementation',6),
('IMPL_PENDING_REVIEW','Implemented (Pending Review)',7),
('CLOSED_SUCCESS','Closed (Successful)',8),
('CLOSED_FAIL','Closed (Unsuccessful)',9),
('CANCELLED','Cancelled',10);


/*## Approval & Audit*/


INSERT INTO ref.ApprovalStage (Code,Name,SortOrder)
VALUES ('MANAGER','Manager',1),('CAB','CAB',2),('SECURITY','Security',3),('POST_REVIEW','Post Review',4);

INSERT INTO ref.ApprovalDecision (Code,Name,SortOrder)
VALUES ('APPROVED','Approved',1),('REJECTED','Rejected',2),('MORE_INFO','More Info Requested',3);

INSERT INTO audit.EventType (Code,Name,SortOrder)
VALUES
('CHANGE_CREATED','Change created',10),
('CHANGE_SUBMITTED','Change submitted',20),
('CHANGE_STATUS_CHANGED','Change status changed',30),
('APPROVAL_RECORDED','Approval recorded',40),
('IMPLEMENTATION_STARTED','Implementation started',50),
('IMPLEMENTATION_COMPLETED','Implementation completed',60),
('PIR_RECORDED','Post-implementation review recorded',70),
('CHANGE_CLOSED','Change closed',80),
('ADMIN_SETTING_CHANGED','Admin setting changed',900);

/* **Seed Version:** 1.0 */
