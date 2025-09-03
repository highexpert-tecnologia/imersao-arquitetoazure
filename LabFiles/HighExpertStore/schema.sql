IF DB_ID('HighExpertStore') IS NULL BEGIN CREATE DATABASE HighExpertStore; END
GO
USE HighExpertStore;
GO
IF OBJECT_ID('dbo.Users','U') IS NULL
CREATE TABLE dbo.Users (Id INT IDENTITY PRIMARY KEY, Name NVARCHAR(100) NOT NULL, Email NVARCHAR(200) NOT NULL UNIQUE, PasswordHash NVARCHAR(256) NOT NULL, PasswordSalt NVARCHAR(100) NOT NULL, CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME());
GO
IF OBJECT_ID('dbo.Sessions','U') IS NULL
CREATE TABLE dbo.Sessions (Token UNIQUEIDENTIFIER PRIMARY KEY, UserId INT NOT NULL FOREIGN KEY REFERENCES dbo.Users(Id), CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), ExpiresAt DATETIME2 NOT NULL);
GO
IF OBJECT_ID('dbo.Products','U') IS NULL
CREATE TABLE dbo.Products (Id INT IDENTITY PRIMARY KEY, Name NVARCHAR(200) NOT NULL, Description NVARCHAR(MAX) NULL, Price DECIMAL(10,2) NOT NULL, Category NVARCHAR(100) NOT NULL, ImageUrl NVARCHAR(500) NULL, Active BIT NOT NULL DEFAULT 1, EstimatedWeightGrams INT NULL);
GO
IF OBJECT_ID('dbo.Carts','U') IS NULL
CREATE TABLE dbo.Carts (Id INT IDENTITY PRIMARY KEY, UserId INT NOT NULL FOREIGN KEY REFERENCES dbo.Users(Id), Status NVARCHAR(20) NOT NULL DEFAULT 'Active');
GO
IF OBJECT_ID('dbo.CartItems','U') IS NULL
CREATE TABLE dbo.CartItems (Id INT IDENTITY PRIMARY KEY, CartId INT NOT NULL FOREIGN KEY REFERENCES dbo.Carts(Id), ProductId INT NOT NULL FOREIGN KEY REFERENCES dbo.Products(Id), Quantity INT NOT NULL DEFAULT 1);
GO
IF OBJECT_ID('dbo.Orders','U') IS NULL
CREATE TABLE dbo.Orders (Id INT IDENTITY PRIMARY KEY, UserId INT NOT NULL FOREIGN KEY REFERENCES dbo.Users(Id), OrderNumber NVARCHAR(50) NOT NULL UNIQUE, Subtotal DECIMAL(10,2) NULL, Discount DECIMAL(10,2) NULL, Shipping DECIMAL(10,2) NULL, Total DECIMAL(10,2) NOT NULL, Cep NVARCHAR(20) NULL, CouponCode NVARCHAR(50) NULL, Status NVARCHAR(20) NOT NULL, CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME());
GO
IF OBJECT_ID('dbo.OrderItems','U') IS NULL
CREATE TABLE dbo.OrderItems (Id INT IDENTITY PRIMARY KEY, OrderId INT NOT NULL FOREIGN KEY REFERENCES dbo.Orders(Id), ProductId INT NOT NULL FOREIGN KEY REFERENCES dbo.Products(Id), Quantity INT NOT NULL DEFAULT 1, UnitPrice DECIMAL(10,2) NOT NULL);
GO
IF OBJECT_ID('dbo.Wishlist','U') IS NULL
CREATE TABLE dbo.Wishlist (Id INT IDENTITY PRIMARY KEY, UserId INT NOT NULL FOREIGN KEY REFERENCES dbo.Users(Id), ProductId INT NOT NULL FOREIGN KEY REFERENCES dbo.Products(Id), CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), CONSTRAINT UQ_Wishlist UNIQUE (UserId, ProductId));
GO
IF OBJECT_ID('dbo.Coupons','U') IS NULL
CREATE TABLE dbo.Coupons (Id INT IDENTITY PRIMARY KEY, Code NVARCHAR(50) NOT NULL UNIQUE, Description NVARCHAR(200) NULL, DiscountType NVARCHAR(10) NOT NULL, DiscountValue DECIMAL(10,2) NOT NULL, Active BIT NOT NULL DEFAULT 1, ExpiresAt DATETIME2 NULL);
GO
IF NOT EXISTS (SELECT 1 FROM dbo.Coupons WHERE Code='BEMVINDO10') INSERT INTO dbo.Coupons(Code,Description,DiscountType,DiscountValue,Active) VALUES ('BEMVINDO10','10% de boas-vindas','percent',10,1);
IF NOT EXISTS (SELECT 1 FROM dbo.Coupons WHERE Code='CLOUD20')  INSERT INTO dbo.Coupons(Code,Description,DiscountType,DiscountValue,Active) VALUES ('CLOUD20','R$20 off em qualquer compra','value',20,1);
GO
IF NOT EXISTS (SELECT 1 FROM dbo.Products)
BEGIN
 INSERT INTO dbo.Products(Name,Description,Price,Category,ImageUrl,Active,EstimatedWeightGrams) VALUES
 (N'Camiseta High Expert - Azure Architect',N'Camiseta premium para arquitetos de nuvem',79.90,N'Camisetas',N'static/img/prod_camiseta_azure.png',1,250),
 (N'Camiseta High Expert - DevOps',N'Estilo e performance para quem vive CI/CD',79.90,N'Camisetas',N'static/img/prod_camiseta_devops.png',1,250),
 (N'Caneca High Expert - Cloud Lover',N'Caneca 350ml para começar o dia no Azure',49.90,N'Canecas',N'static/img/prod_caneca_cloud.png',1,350),
 (N'Adesivo High Expert - Kubernetes',N'Adesivo vinil recortado do K8s',14.90,N'Acessorios',N'static/img/prod_adesivo_k8s.png',1,20),
 (N'Caneca High Expert - MVP Edition',N'Edição especial para colecionadores',69.90,N'Canecas',N'static/img/prod_caneca_mvp.png',1,350);
END
GO
IF COL_LENGTH('dbo.Orders','Address') IS NULL
  ALTER TABLE dbo.Orders ADD Address NVARCHAR(400) NULL;
GO
