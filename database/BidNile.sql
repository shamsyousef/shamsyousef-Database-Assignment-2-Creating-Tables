CREATE DATABASE BidNile;
GO
Create schema Accounts;
GO
CREATE SCHEMA Operations;
GO

CREATE SCHEMA Catalog;
GO

CREATE SCHEMA Sales;
GO
CREATE TABLE Accounts.City (
    CityId  INT IDENTITY(1,1) 
	      CONSTRAINT PK_City PRIMARY KEY,
    Name  NVARCHAR(60)  NOT NULL,
    CountryCode CHAR(2)   NOT NULL
          CONSTRAINT CK_City_CountryCode CHECK (CountryCode IN ('EG', 'SA', 'AE')),

    CONSTRAINT UQ_City_Name_CountryCode UNIQUE (Name, CountryCode)
);
GO
CREATE TABLE Accounts.Member (
    MemberId UNIQUEIDENTIFIER NOT NULL
	   CONSTRAINT PK_Member PRIMARY KEY
	   CONSTRAINT DF_Member_MemberId DEFAULT NEWID(),
	FullName NVARCHAR(100) NOT NULL ,
	Email    NVARCHAR(254) NOT NULL
	     CONSTRAINT UQ_Member_Email UNIQUE,
    Mobile   VARCHAR(16)   NOT NULL,
	NationalId VARCHAR(20) NOT NULL
	  CONSTRAINT UQ_Member_NationalId UNIQUE,
	BirthDate Date Not NULL
	  CONSTRAINT CK_Member_BirthDate CHECK (DATEADD(YEAR, 18, BirthDate) <= CAST(GETDATE() AS DATE)),
    IsVerified BIT NOT NULL
	  CONSTRAINT DF_Member_IsVerified DEFAULT 0,
    RegisteredAt DateTime2(3) NOT NULL
	  CONSTRAINT DF_Member_RegisteredAt DEFAULT SYSDATETIME(),
    CityId int NOT NULL,
	ReferredByMemberId UNIQUEIDENTIFIER NULL,
	WarehouseId INT  NULL);
	Go
CREATE TABLE Accounts.Wallet (
    MemberId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_Wallet PRIMARY KEY,
    Balance DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Wallet_Balance DEFAULT 0
        CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0),
    HeldAmount DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Wallet_HeldAmount DEFAULT 0
        CONSTRAINT CK_Wallet_HeldAmount CHECK (HeldAmount >= 0),
    Currency CHAR(3) NOT NULL
        CONSTRAINT DF_Wallet_Currency DEFAULT 'EGP',
    UpdatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Wallet_UpdatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Wallet_HeldAmount_Balance CHECK (HeldAmount <= Balance));
GO
CREATE TABLE Operations.Warehouse (
    WarehouseId INT IDENTITY(1,1)
        CONSTRAINT PK_Warehouse PRIMARY KEY,
    Name NVARCHAR(80) NOT NULL
        CONSTRAINT UQ_Warehouse_Name UNIQUE,
    Capacity INT NOT NULL
        CONSTRAINT CK_Warehouse_Capacity CHECK (Capacity > 0),
    Latitude FLOAT NOT NULL
        CONSTRAINT CK_Warehouse_Latitude CHECK (Latitude BETWEEN -90 AND 90),
    Longitude FLOAT NOT NULL
        CONSTRAINT CK_Warehouse_Longitude CHECK (Longitude BETWEEN -180 AND 180),
    CityId INT NOT NULL,
    ManagerId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT UQ_Warehouse_ManagerId UNIQUE,
    ManagerStartDate DATE NOT NULL);
GO
CREATE TABLE Catalog.Category (
    CategoryId INT NOT NULL
        CONSTRAINT PK_Category PRIMARY KEY,
    NameEn VARCHAR(50) NOT NULL
        CONSTRAINT UQ_Category_NameEn UNIQUE,
    NameAr NVARCHAR(50) NULL,
    CommissionRate DECIMAL(4, 2) NOT NULL
        CONSTRAINT CK_Category_CommissionRate CHECK (CommissionRate BETWEEN 0 AND 30),
    ParentCategoryId INT NULL);
GO
CREATE TABLE Catalog.Item (
    ItemId INT IDENTITY(1,1)
        CONSTRAINT PK_Item PRIMARY KEY,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ConditionScore TINYINT NOT NULL
        CONSTRAINT CK_Item_ConditionScore CHECK (ConditionScore BETWEEN 1 AND 10),
    Specifications NVARCHAR(MAX) NOT NULL
        CONSTRAINT CK_Item_Specifications CHECK (ISJSON(Specifications) = 1),
    ListedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Item_ListedAt DEFAULT SYSDATETIME(),
    SellerId UNIQUEIDENTIFIER NOT NULL,
    InspectorId UNIQUEIDENTIFIER NULL,
    CategoryId INT NOT NULL,
    WarehouseId INT NULL,
    CONSTRAINT CK_Item_Seller_Inspector CHECK (InspectorId IS NULL OR SellerId <> InspectorId));
GO
CREATE TABLE Catalog.ItemPhoto (
    ItemId INT NOT NULL,
    Position TINYINT NOT NULL
        CONSTRAINT CK_ItemPhoto_Position CHECK (Position BETWEEN 1 AND 20),
    Url VARCHAR(500) NOT NULL,
    IsMain BIT NOT NULL
        CONSTRAINT DF_ItemPhoto_IsMain DEFAULT 0,
    CONSTRAINT PK_ItemPhoto PRIMARY KEY (ItemId, Position));
GO
CREATE TABLE Sales.Auction (
    AuctionId INT IDENTITY(1,1)
        CONSTRAINT PK_Auction PRIMARY KEY,
    ItemId INT NOT NULL,
    StartingPrice DECIMAL(12, 2) NOT NULL
        CONSTRAINT CK_Auction_StartingPrice CHECK (StartingPrice > 0),
    ReservePrice DECIMAL(12, 2) NULL,
    BidIncrement DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Auction_BidIncrement DEFAULT 50.00
        CONSTRAINT CK_Auction_BidIncrement CHECK (BidIncrement > 0),
    StartTime DATETIMEOFFSET NOT NULL,
    EndTime DATETIMEOFFSET NOT NULL,
    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_Auction_Status DEFAULT 'Draft'
        CONSTRAINT CK_Auction_Status CHECK (Status IN ('Draft', 'Live', 'Ended', 'Cancelled')),
    CONSTRAINT CK_Auction_TimeRange CHECK (EndTime > StartTime),
    CONSTRAINT CK_Auction_ReservePrice CHECK (ReservePrice IS NULL OR ReservePrice >= StartingPrice));
GO
CREATE TABLE Sales.Bid (
    BidId BIGINT IDENTITY(1,1)
        CONSTRAINT PK_Bid PRIMARY KEY,
    AuctionId INT NOT NULL,
    MemberId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(12, 2) NOT NULL
        CONSTRAINT CK_Bid_Amount CHECK (Amount > 0),
    PlacedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Bid_PlacedAt DEFAULT SYSDATETIME(),
    IpAddress VARCHAR(45) NOT NULL,
    CONSTRAINT UQ_Bid_AuctionId_Amount UNIQUE (AuctionId, Amount));
GO

CREATE TABLE Sales.AuctionFollow (
    MemberId UNIQUEIDENTIFIER NOT NULL,
    AuctionId INT NOT NULL,
    FollowedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_AuctionFollow_FollowedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_AuctionFollow PRIMARY KEY (MemberId, AuctionId));
GO
ALTER TABLE Accounts.Member
    ADD CONSTRAINT FK_Member_City FOREIGN KEY (CityId) REFERENCES Accounts.City (CityId),
        CONSTRAINT FK_Member_ReferredBy FOREIGN KEY (ReferredByMemberId) REFERENCES Accounts.Member (MemberId),
        CONSTRAINT FK_Member_Warehouse FOREIGN KEY (WarehouseId) REFERENCES Operations.Warehouse (WarehouseId);
GO
ALTER TABLE Accounts.Wallet
    ADD CONSTRAINT FK_Wallet_Member FOREIGN KEY (MemberId) REFERENCES Accounts.Member (MemberId);
GO
ALTER TABLE Operations.Warehouse
    ADD CONSTRAINT FK_Warehouse_City FOREIGN KEY (CityId) REFERENCES Accounts.City (CityId),
        CONSTRAINT FK_Warehouse_Manager FOREIGN KEY (ManagerId) REFERENCES Accounts.Member (MemberId);
GO
ALTER TABLE Catalog.Category
    ADD CONSTRAINT FK_Category_Parent FOREIGN KEY (ParentCategoryId) REFERENCES Catalog.Category (CategoryId);
GO
ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Seller FOREIGN KEY (SellerId) REFERENCES Accounts.Member (MemberId),
        CONSTRAINT FK_Item_Inspector FOREIGN KEY (InspectorId) REFERENCES Accounts.Member (MemberId),
        CONSTRAINT FK_Item_Category FOREIGN KEY (CategoryId) REFERENCES Catalog.Category (CategoryId),
        CONSTRAINT FK_Item_Warehouse FOREIGN KEY (WarehouseId) REFERENCES Operations.Warehouse (WarehouseId);
GO
ALTER TABLE Catalog.ItemPhoto
    ADD CONSTRAINT FK_ItemPhoto_Item FOREIGN KEY (ItemId) REFERENCES Catalog.Item (ItemId) ON DELETE CASCADE;
GO

ALTER TABLE Sales.Auction
    ADD CONSTRAINT FK_Auction_Item FOREIGN KEY (ItemId) REFERENCES Catalog.Item (ItemId);
GO

ALTER TABLE Sales.Bid
    ADD CONSTRAINT FK_Bid_Auction FOREIGN KEY (AuctionId) REFERENCES Sales.Auction (AuctionId),
        CONSTRAINT FK_Bid_Member FOREIGN KEY (MemberId) REFERENCES Accounts.Member (MemberId);
GO

ALTER TABLE Sales.AuctionFollow
    ADD CONSTRAINT FK_AuctionFollow_Member FOREIGN KEY (MemberId) REFERENCES Accounts.Member (MemberId),
        CONSTRAINT FK_AuctionFollow_Auction FOREIGN KEY (AuctionId) REFERENCES Sales.Auction (AuctionId);
GO
ALTER TABLE Accounts.Member
    ADD AppLanguage CHAR(2) NOT NULL
        CONSTRAINT DF_Member_AppLanguage DEFAULT 'ar'
        CONSTRAINT CK_Member_AppLanguage CHECK (AppLanguage IN ('ar', 'en'));
GO
ALTER TABLE Catalog.Item
    ADD IsFeatured BIT NOT NULL
        CONSTRAINT DF_Item_IsFeatured DEFAULT 0;
GO
EXEC sp_rename 'Sales.Bid.IpAddress', 'DeviceIp', 'COLUMN';
GO
ALTER TABLE Operations.Warehouse
    DROP CONSTRAINT CK_Warehouse_Capacity;
GO
EXEC sp_rename 'Operations.Warehouse.Capacity', 'MaxItems', 'COLUMN';
GO
ALTER TABLE Operations.Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO

ALTER TABLE Accounts.Member
    ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO
ALTER TABLE Operations.Warehouse
    DROP CONSTRAINT CK_Warehouse_MaxItems;
GO
ALTER TABLE Operations.Warehouse
    ALTER COLUMN MaxItems SMALLINT NOT NULL;
GO
ALTER TABLE Operations.Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO
ALTER TABLE Catalog.Category
    DROP CONSTRAINT CK_Category_CommissionRate;
GO

ALTER TABLE Catalog.Category
    ADD CONSTRAINT CK_Category_CommissionRate CHECK (CommissionRate BETWEEN 0 AND 25);
GO
ALTER TABLE Sales.Auction
    DROP CONSTRAINT CK_Auction_Status, DF_Auction_Status;
GO

ALTER TABLE Sales.Auction
    ADD CONSTRAINT CK_Auction_Status CHECK (Status IN ('PendingReview', 'Draft', 'Live', 'Ended', 'Cancelled')),
        CONSTRAINT DF_Auction_Status DEFAULT 'PendingReview' FOR Status;
GO
ALTER TABLE Sales.Auction
    ADD BuyNowPrice DECIMAL(12, 2) NULL;
GO
ALTER TABLE Sales.Auction WITH CHECK
    ADD CONSTRAINT CK_Auction_BuyNowPrice CHECK (BuyNowPrice IS NULL OR BuyNowPrice > StartingPrice);
GO
ALTER TABLE Accounts.Member
    ADD CONSTRAINT UQ_Member_Mobile UNIQUE (Mobile);
GO
ALTER TABLE Accounts.Member
    ADD VerifiedAt DATETIME2(3) NULL;
GO
ALTER TABLE Accounts.Member
    DROP CONSTRAINT DF_Member_IsVerified;
GO
ALTER TABLE Accounts.Member
    DROP COLUMN IsVerified;
GO
CREATE SCHEMA Marketing;
GO
ALTER SCHEMA Marketing TRANSFER Sales.AuctionFollow;
GO