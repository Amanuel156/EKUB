



--1. Create database

CREATE DATABASE EqubAppDB;
GO

USE EqubAppDB;
GO













--2. Schemas

CREATE SCHEMA app;
GO

CREATE SCHEMA finance;
GO

CREATE SCHEMA security;
GO

CREATE SCHEMA audit;
GO

CREATE SCHEMA ref;
GO































--3. Reference tables

CREATE TABLE ref.GroupStatus (
    GroupStatusId TINYINT PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO ref.GroupStatus VALUES
(1, 'Draft'),
(2, 'PendingMembers'),
(3, 'Active'),
(4, 'Completed'),
(5, 'Cancelled'),
(6, 'Suspended');
GO

CREATE TABLE ref.MemberStatus (
    MemberStatusId TINYINT PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO ref.MemberStatus VALUES
(1, 'Invited'),
(2, 'Accepted'),
(3, 'Active'),
(4, 'Removed'),
(5, 'Defaulted');
GO

CREATE TABLE ref.PaymentStatus (
    PaymentStatusId TINYINT PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO ref.PaymentStatus VALUES
(1, 'Pending'),
(2, 'Processing'),
(3, 'Succeeded'),
(4, 'Failed'),
(5, 'Cancelled'),
(6, 'Refunded');
GO

CREATE TABLE ref.PayoutStatus (
    PayoutStatusId TINYINT PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO ref.PayoutStatus VALUES
(1, 'Scheduled'),
(2, 'Ready'),
(3, 'Processing'),
(4, 'Paid'),
(5, 'Failed'),
(6, 'Cancelled');
GO

CREATE TABLE ref.FrequencyType (
    FrequencyTypeId TINYINT PRIMARY KEY,
    FrequencyName VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO ref.FrequencyType VALUES
(1, 'Weekly'),
(2, 'BiWeekly'),
(3, 'Monthly');
GO











































--4. Users

CREATE TABLE app.Users (
    UserId BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserGuid UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),

    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    PhoneNumber NVARCHAR(30) NULL,

    DateOfBirth DATE NULL,

    StripeCustomerId NVARCHAR(100) NULL,
    StripeConnectedAccountId NVARCHAR(100) NULL,

    IsEmailVerified BIT NOT NULL DEFAULT 0,
    IsPhoneVerified BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc DATETIME2(3) NULL,

    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT UQ_Users_UserGuid UNIQUE (UserGuid)
);
GO














--5. Groups

CREATE TABLE app.Groups (
    GroupId BIGINT IDENTITY(1,1) PRIMARY KEY,
    GroupGuid UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),

    GroupName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000) NULL,

    CreatedByUserId BIGINT NOT NULL,
    GroupStatusId TINYINT NOT NULL DEFAULT 1,

    ContributionAmount DECIMAL(19,4) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL DEFAULT 'USD',
    FrequencyTypeId TINYINT NOT NULL DEFAULT 1,

    MaxMembers INT NOT NULL,
    StartDate DATE NULL,
    EndDate DATE NULL,

    PlatformFeePercent DECIMAL(9,4) NOT NULL DEFAULT 0,
    PlatformFeeFlatAmount DECIMAL(19,4) NOT NULL DEFAULT 0,

    IsPayoutOrderLocked BIT NOT NULL DEFAULT 0,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc DATETIME2(3) NULL,

    CONSTRAINT FK_Groups_CreatedByUser
        FOREIGN KEY (CreatedByUserId) REFERENCES app.Users(UserId),

    CONSTRAINT FK_Groups_GroupStatus
        FOREIGN KEY (GroupStatusId) REFERENCES ref.GroupStatus(GroupStatusId),

    CONSTRAINT FK_Groups_FrequencyType
        FOREIGN KEY (FrequencyTypeId) REFERENCES ref.FrequencyType(FrequencyTypeId),

    CONSTRAINT CK_Groups_ContributionAmount
        CHECK (ContributionAmount > 0),

    CONSTRAINT CK_Groups_MaxMembers
        CHECK (MaxMembers >= 2),

    CONSTRAINT UQ_Groups_GroupGuid UNIQUE (GroupGuid)
);
GO
















--6 Group members

CREATE TABLE app.GroupMembers (
    GroupMemberId BIGINT IDENTITY(1,1) PRIMARY KEY,

    GroupId BIGINT NOT NULL,
    UserId BIGINT NOT NULL,

    MemberStatusId TINYINT NOT NULL DEFAULT 1,

    JoinedAtUtc DATETIME2(3) NULL,
    RemovedAtUtc DATETIME2(3) NULL,

    HasReceivedPayout BIT NOT NULL DEFAULT 0,
    ReceivedPayoutAtUtc DATETIME2(3) NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_GroupMembers_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_GroupMembers_User
        FOREIGN KEY (UserId) REFERENCES app.Users(UserId),

    CONSTRAINT FK_GroupMembers_Status
        FOREIGN KEY (MemberStatusId) REFERENCES ref.MemberStatus(MemberStatusId),

    CONSTRAINT UQ_GroupMembers_Group_User UNIQUE (GroupId, UserId)
);
GO


























--7,Payout order
CREATE TABLE app.GroupPayoutOrder (
    GroupPayoutOrderId BIGINT IDENTITY(1,1) PRIMARY KEY,

    GroupId BIGINT NOT NULL,
    GroupMemberId BIGINT NOT NULL,

    PayoutPosition INT NOT NULL,
    PayoutDate DATE NULL,

    IsLocked BIT NOT NULL DEFAULT 0,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_GroupPayoutOrder_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_GroupPayoutOrder_GroupMember
        FOREIGN KEY (GroupMemberId) REFERENCES app.GroupMembers(GroupMemberId),

    CONSTRAINT UQ_GroupPayoutOrder_Group_Position UNIQUE (GroupId, PayoutPosition),

    CONSTRAINT UQ_GroupPayoutOrder_Group_Member UNIQUE (GroupId, GroupMemberId),

    CONSTRAINT CK_GroupPayoutOrder_Position CHECK (PayoutPosition > 0)
);
GO






















--8. Contribution cycles

CREATE TABLE app.ContributionCycles (
    ContributionCycleId BIGINT IDENTITY(1,1) PRIMARY KEY,

    GroupId BIGINT NOT NULL,
    CycleNumber INT NOT NULL,

    DueDate DATE NOT NULL,
    PayoutDate DATE NOT NULL,

    RecipientGroupMemberId BIGINT NOT NULL,

    ExpectedTotalAmount DECIMAL(19,4) NOT NULL,
    ActualCollectedAmount DECIMAL(19,4) NOT NULL DEFAULT 0,

    IsClosed BIT NOT NULL DEFAULT 0,
    ClosedAtUtc DATETIME2(3) NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_ContributionCycles_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_ContributionCycles_Recipient
        FOREIGN KEY (RecipientGroupMemberId) REFERENCES app.GroupMembers(GroupMemberId),

    CONSTRAINT UQ_ContributionCycles_Group_Cycle UNIQUE (GroupId, CycleNumber),

    CONSTRAINT CK_ContributionCycles_CycleNumber CHECK (CycleNumber > 0)
);
GO



















--9. Member contribution obligations

CREATE TABLE finance.MemberContributions (
    MemberContributionId BIGINT IDENTITY(1,1) PRIMARY KEY,

    ContributionCycleId BIGINT NOT NULL,
    GroupId BIGINT NOT NULL,
    GroupMemberId BIGINT NOT NULL,

    AmountDue DECIMAL(19,4) NOT NULL,
    AmountPaid DECIMAL(19,4) NOT NULL DEFAULT 0,

    PaymentStatusId TINYINT NOT NULL DEFAULT 1,

    DueDate DATE NOT NULL,
    PaidAtUtc DATETIME2(3) NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc DATETIME2(3) NULL,

    CONSTRAINT FK_MemberContributions_Cycle
        FOREIGN KEY (ContributionCycleId) REFERENCES app.ContributionCycles(ContributionCycleId),

    CONSTRAINT FK_MemberContributions_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_MemberContributions_GroupMember
        FOREIGN KEY (GroupMemberId) REFERENCES app.GroupMembers(GroupMemberId),

    CONSTRAINT FK_MemberContributions_Status
        FOREIGN KEY (PaymentStatusId) REFERENCES ref.PaymentStatus(PaymentStatusId),

    CONSTRAINT UQ_MemberContributions_Cycle_Member UNIQUE (ContributionCycleId, GroupMemberId),

    CONSTRAINT CK_MemberContributions_AmountDue CHECK (AmountDue >= 0)
);
GO























--10. Payment records

CREATE TABLE finance.Payments (
    PaymentId BIGINT IDENTITY(1,1) PRIMARY KEY,

    MemberContributionId BIGINT NOT NULL,
    GroupId BIGINT NOT NULL,
    UserId BIGINT NOT NULL,

    Amount DECIMAL(19,4) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL DEFAULT 'USD',

    PaymentStatusId TINYINT NOT NULL DEFAULT 1,

    StripePaymentIntentId NVARCHAR(150) NULL,
    StripeChargeId NVARCHAR(150) NULL,
    StripeBalanceTransactionId NVARCHAR(150) NULL,

    FailureCode NVARCHAR(100) NULL,
    FailureMessage NVARCHAR(1000) NULL,

    AttemptNumber INT NOT NULL DEFAULT 1,

    RequestedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    ProcessedAtUtc DATETIME2(3) NULL,

    CONSTRAINT FK_Payments_MemberContribution
        FOREIGN KEY (MemberContributionId) REFERENCES finance.MemberContributions(MemberContributionId),

    CONSTRAINT FK_Payments_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_Payments_User
        FOREIGN KEY (UserId) REFERENCES app.Users(UserId),

    CONSTRAINT FK_Payments_Status
        FOREIGN KEY (PaymentStatusId) REFERENCES ref.PaymentStatus(PaymentStatusId),

    CONSTRAINT CK_Payments_Amount CHECK (Amount > 0)
);
GO























--11. Payouts

CREATE TABLE finance.Payouts (
    PayoutId BIGINT IDENTITY(1,1) PRIMARY KEY,

    ContributionCycleId BIGINT NOT NULL,
    GroupId BIGINT NOT NULL,
    RecipientGroupMemberId BIGINT NOT NULL,
    RecipientUserId BIGINT NOT NULL,

    GrossAmount DECIMAL(19,4) NOT NULL,
    PlatformFeeAmount DECIMAL(19,4) NOT NULL DEFAULT 0,
    NetAmount DECIMAL(19,4) NOT NULL,

    CurrencyCode CHAR(3) NOT NULL DEFAULT 'USD',

    PayoutStatusId TINYINT NOT NULL DEFAULT 1,

    StripeTransferId NVARCHAR(150) NULL,
    StripePayoutId NVARCHAR(150) NULL,
    StripeBalanceTransactionId NVARCHAR(150) NULL,

    ScheduledDate DATE NOT NULL,
    RequestedAtUtc DATETIME2(3) NULL,
    PaidAtUtc DATETIME2(3) NULL,

    FailureCode NVARCHAR(100) NULL,
    FailureMessage NVARCHAR(1000) NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc DATETIME2(3) NULL,

    CONSTRAINT FK_Payouts_Cycle
        FOREIGN KEY (ContributionCycleId) REFERENCES app.ContributionCycles(ContributionCycleId),

    CONSTRAINT FK_Payouts_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_Payouts_RecipientGroupMember
        FOREIGN KEY (RecipientGroupMemberId) REFERENCES app.GroupMembers(GroupMemberId),

    CONSTRAINT FK_Payouts_RecipientUser
        FOREIGN KEY (RecipientUserId) REFERENCES app.Users(UserId),

    CONSTRAINT FK_Payouts_Status
        FOREIGN KEY (PayoutStatusId) REFERENCES ref.PayoutStatus(PayoutStatusId),

    CONSTRAINT UQ_Payouts_Cycle UNIQUE (ContributionCycleId),

    CONSTRAINT CK_Payouts_GrossAmount CHECK (GrossAmount >= 0),
    CONSTRAINT CK_Payouts_NetAmount CHECK (NetAmount >= 0)
);
GO






















--12. App fees

CREATE TABLE finance.AppFees (
    AppFeeId BIGINT IDENTITY(1,1) PRIMARY KEY,

    GroupId BIGINT NOT NULL,
    ContributionCycleId BIGINT NULL,
    PaymentId BIGINT NULL,
    PayoutId BIGINT NULL,

    FeeAmount DECIMAL(19,4) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL DEFAULT 'USD',

    FeeType NVARCHAR(50) NOT NULL, -- PlatformFee, MonthlyFee, SetupFee

    StripeApplicationFeeId NVARCHAR(150) NULL,
    StripeBalanceTransactionId NVARCHAR(150) NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_AppFees_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_AppFees_Cycle
        FOREIGN KEY (ContributionCycleId) REFERENCES app.ContributionCycles(ContributionCycleId),

    CONSTRAINT FK_AppFees_Payment
        FOREIGN KEY (PaymentId) REFERENCES finance.Payments(PaymentId),

    CONSTRAINT FK_AppFees_Payout
        FOREIGN KEY (PayoutId) REFERENCES finance.Payouts(PayoutId),

    CONSTRAINT CK_AppFees_FeeAmount CHECK (FeeAmount >= 0)
);
GO
































--13. Stripe webhook events
CREATE TABLE finance.StripeWebhookEvents (
    StripeWebhookEventId BIGINT IDENTITY(1,1) PRIMARY KEY,

    StripeEventId NVARCHAR(150) NOT NULL,
    EventType NVARCHAR(150) NOT NULL,

    ApiVersion NVARCHAR(50) NULL,
    Livemode BIT NOT NULL DEFAULT 0,

    Payload NVARCHAR(MAX) NOT NULL,

    IsProcessed BIT NOT NULL DEFAULT 0,
    ProcessedAtUtc DATETIME2(3) NULL,

    ProcessingError NVARCHAR(MAX) NULL,

    ReceivedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_StripeWebhookEvents_StripeEventId UNIQUE (StripeEventId)
);
GO



























--14. Audit log

CREATE TABLE audit.AuditLog (
    AuditLogId BIGINT IDENTITY(1,1) PRIMARY KEY,

    UserId BIGINT NULL,
    EntityName NVARCHAR(100) NOT NULL,
    EntityId BIGINT NULL,

    ActionName NVARCHAR(100) NOT NULL,

    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,

    IpAddress NVARCHAR(50) NULL,
    UserAgent NVARCHAR(500) NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_AuditLog_User
        FOREIGN KEY (UserId) REFERENCES app.Users(UserId)
);
GO


























--15. Disputes / support cases

CREATE TABLE app.SupportCases (
    SupportCaseId BIGINT IDENTITY(1,1) PRIMARY KEY,

    CreatedByUserId BIGINT NOT NULL,
    GroupId BIGINT NULL,
    PaymentId BIGINT NULL,
    PayoutId BIGINT NULL,

    Subject NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,

    Status NVARCHAR(50) NOT NULL DEFAULT 'Open',
    Priority NVARCHAR(50) NOT NULL DEFAULT 'Normal',

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    ClosedAtUtc DATETIME2(3) NULL,

    CONSTRAINT FK_SupportCases_User
        FOREIGN KEY (CreatedByUserId) REFERENCES app.Users(UserId),

    CONSTRAINT FK_SupportCases_Group
        FOREIGN KEY (GroupId) REFERENCES app.Groups(GroupId),

    CONSTRAINT FK_SupportCases_Payment
        FOREIGN KEY (PaymentId) REFERENCES finance.Payments(PaymentId),

    CONSTRAINT FK_SupportCases_Payout
        FOREIGN KEY (PayoutId) REFERENCES finance.Payouts(PayoutId)
);
GO





















--16. Notifications

CREATE TABLE app.Notifications (
    NotificationId BIGINT IDENTITY(1,1) PRIMARY KEY,

    UserId BIGINT NOT NULL,

    Title NVARCHAR(200) NOT NULL,
    Message NVARCHAR(1000) NOT NULL,

    NotificationType NVARCHAR(50) NOT NULL,

    IsRead BIT NOT NULL DEFAULT 0,
    ReadAtUtc DATETIME2(3) NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Notifications_User
        FOREIGN KEY (UserId) REFERENCES app.Users(UserId)
);
GO




















--17. Security tables

CREATE TABLE security.UserLoginHistory (
    UserLoginHistoryId BIGINT IDENTITY(1,1) PRIMARY KEY,

    UserId BIGINT NOT NULL,

    LoginAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    IpAddress NVARCHAR(50) NULL,
    UserAgent NVARCHAR(500) NULL,

    WasSuccessful BIT NOT NULL,
    FailureReason NVARCHAR(500) NULL,

    CONSTRAINT FK_UserLoginHistory_User
        FOREIGN KEY (UserId) REFERENCES app.Users(UserId)
);
GO

CREATE TABLE security.UserSessions (
    UserSessionId BIGINT IDENTITY(1,1) PRIMARY KEY,

    UserId BIGINT NOT NULL,

    RefreshTokenHash NVARCHAR(500) NOT NULL,

    CreatedAtUtc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    ExpiresAtUtc DATETIME2(3) NOT NULL,
    RevokedAtUtc DATETIME2(3) NULL,

    IpAddress NVARCHAR(50) NULL,
    UserAgent NVARCHAR(500) NULL,

    CONSTRAINT FK_UserSessions_User
        FOREIGN KEY (UserId) REFERENCES app.Users(UserId)
);
GO

































--18. Important indexes

CREATE INDEX IX_Users_Email
ON app.Users(Email);
GO

CREATE INDEX IX_Groups_CreatedByUserId
ON app.Groups(CreatedByUserId);
GO

CREATE INDEX IX_GroupMembers_UserId
ON app.GroupMembers(UserId);
GO

CREATE INDEX IX_GroupMembers_GroupId
ON app.GroupMembers(GroupId);
GO

CREATE INDEX IX_ContributionCycles_GroupId_DueDate
ON app.ContributionCycles(GroupId, DueDate);
GO

CREATE INDEX IX_MemberContributions_GroupMemberId
ON finance.MemberContributions(GroupMemberId);
GO

CREATE INDEX IX_MemberContributions_Status
ON finance.MemberContributions(PaymentStatusId);
GO

CREATE INDEX IX_Payments_StripePaymentIntentId
ON finance.Payments(StripePaymentIntentId)
WHERE StripePaymentIntentId IS NOT NULL;
GO

CREATE INDEX IX_Payments_GroupId_Status
ON finance.Payments(GroupId, PaymentStatusId);
GO

CREATE INDEX IX_Payouts_GroupId_Status
ON finance.Payouts(GroupId, PayoutStatusId);
GO

CREATE INDEX IX_AuditLog_Entity
ON audit.AuditLog(EntityName, EntityId);
GO

CREATE INDEX IX_AuditLog_CreatedAtUtc
ON audit.AuditLog(CreatedAtUtc);
GO

CREATE INDEX IX_StripeWebhookEvents_EventType
ON finance.StripeWebhookEvents(EventType);
GO
































		--19. Example flow in this database
		--User creates group

		--Insert into:

		--app.Users
		--app.Groups
		--app.GroupMembers
		--Randomize payout order once

		--Insert into:

		--app.GroupPayoutOrder

		--Then set:

		--app.Groups.IsPayoutOrderLocked = 1
		--Generate weekly schedule

		--Insert into:

		--app.ContributionCycles
		--finance.MemberContributions
		--finance.Payouts
		--Weekly payment

		--Insert/update:

		--finance.Payments
		--finance.MemberContributions
		--finance.StripeWebhookEvents
		--Weekly payout

		--Update:

		--finance.Payouts
		--app.ContributionCycles
		--app.GroupMembers