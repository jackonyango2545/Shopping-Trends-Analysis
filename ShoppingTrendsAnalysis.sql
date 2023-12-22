--Lets select which database we will be using during this project
USE [Sales ];

--Lets look at the data we have,
SELECT * FROM shopping_behavior;

--Lets look at the columns and their data type
SELECT COLUMN_NAME,DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME='shopping_behavior';

--Lets start with data cleaning
--We need to change the data types of various columns, eg Age,Purchase Amount (USD),Review Rating,Previous Purchases
ALTER TABLE shopping_behavior ALTER COLUMN Age INT;
ALTER TABLE shopping_behavior ALTER COLUMN [Purchase Amount (USD)] MONEY;
ALTER TABLE shopping_behavior ALTER COLUMN [Review Rating] DECIMAL(10,2);
ALTER TABLE shopping_behavior ALTER COLUMN [Previous Purchases] INT;

--Lets go to checking for null values in our dataset
SELECT * FROM shopping_behavior
WHERE COALESCE([Customer ID], Age, Gender, [Item Purchased], Category, [Purchase Amount (USD)], Location,
Size, Color, Season, [Review Rating], [Subscription Status], [Shipping Type],[Discount Applied], [Promo Code Used],
[Previous Purchases], [Payment Method],[Frequency of Purchases]) IS NULL;

--Next step is to check if we have duplicates,we will use the column of customer id to check,this is because it should be unique
SELECT [Customer ID],COUNT([Customer ID]) AS Appearances FROM shopping_behavior
GROUP BY [Customer ID]
HAVING COUNT([Customer ID])>1;

/*Lets create another column of Age group,this will be helpful when we want to group them in their respective groups
We will be using the Age column to populate the Age group column,therefore we can start by understanding the age column*/
SELECT MIN(Age) AS 'Minimum Age',AVG(Age) AS 'Mean Age',ROUND(STDEVP(Age),4) AS 'Population Standard Deviation',MAX(Age) AS 'Maximum Age'FROM shopping_behavior;

--To create the new column:
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='shopping_behavior' AND COLUMN_NAME='Age Group')
BEGIN
    ALTER TABLE shopping_behavior ADD [Age Group] VARCHAR(20);
END;
--To populate the column
UPDATE shopping_behavior
SET [Age Group]=
    CASE
        WHEN Age <= 19 THEN 'UNDER 20'
        WHEN Age >= 20 AND Age <= 29 THEN '20-29'
        WHEN Age >= 30 AND Age <= 39 THEN '30-39'
        WHEN Age >= 40 AND Age <= 49 THEN '40-49'
        WHEN Age >= 50 AND Age <= 59 THEN '50-59'
        ELSE '60 and above'
    END;

--Lets start our analysis
/*How is purchase behavior distributed across different genders concerning
frequency, purchase amount, shipping type, discounts, and product categories?*/

--What is the distribituion of Gender on the shipping type have influence,purchase amount and does frequency of purchase?
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Gender_Shipping_and_Frequency')
BEGIN
	CREATE TABLE Gender_Shipping_and_Frequency(
		Gender VARCHAR(50),
		Category VARCHAR(50),
		[Shipping Type] VARCHAR(50),
		[Frequency of Purchases] VARCHAR(50),
		[Number of Times] INT,
		[Average Cost] MONEY);

	INSERT INTO Gender_Shipping_and_Frequency
	SELECT Gender,Category,[Shipping Type],[Frequency of Purchases],COUNT([Frequency of Purchases]) AS 'Number of Times',ROUND(AVG([Purchase Amount (USD)]),2) AS 'Average Cost'
	FROM shopping_behavior
	GROUP BY Gender,Category,[Shipping Type],[Frequency of Purchases]
	ORDER BY 'Number of Times' DESC;
END;
--What is the popular products and category among each gender of different age group and does discount have influence?
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Popular_item_in_Gender')
BEGIN
	CREATE TABLE Popular_item_in_Gender(
		 Gender VARCHAR(50),
		 [Age Group] VARCHAR(50),
		 Category VARCHAR(50),
		 [Item Purchased] VARCHAR(50),
		 [Discount Applied] VARCHAR(50),
		 [Number Sold] INT,
		 [Average Cost] MONEY);

	INSERT INTO Popular_item_in_Gender
	SELECT Gender,[Age Group],Category,[Item Purchased],[Discount Applied],
	COUNT([Item Purchased]) AS 'Number Sold',ROUND(AVG([Purchase Amount (USD)]),2) AS 'Average Cost'
	FROM shopping_behavior
	GROUP BY Gender,[Age Group],Category,[Item Purchased],[Discount Applied]
	ORDER BY 'Number Sold' DESC;
END;

/*How does age distribution influence purchase frequency, payment methods, applied discounts, 
shipping types, and purchase amounts across different categories?*/
--What is the average amount spent by each age on each category and item and the number of units sold
IF NOT EXISTS( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Popular_items_by_Age')
BEGIN
	CREATE TABLE Popular_items_by_Age(
		Age INT,
		[Age Group] VARCHAR(50),
		Category VARCHAR(50),
		[Item Purchased] VARCHAR(50),
		[Number Sold] INT,
		[Average Cost] MONEY);
	INSERT INTO Popular_items_by_Age
	SELECT Age,[Age Group],Category,[Item Purchased],COUNT([Item Purchased]) AS 'Number Sold',ROUND(AVG([Purchase Amount (USD)]),2) AS 'Average Cost'
	FROM shopping_behavior
	GROUP BY Age,[Age Group],Category,[Item Purchased]
	ORDER BY 'Number Sold' DESC;
END;

--What is the distribituion of Age on the shipping type have influence,purchase amount and does frequency of purchase?
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Age_Shipping_and_Frequency')
BEGIN
	CREATE TABLE Age_Shipping_and_Frequency(
		Age INT,
		[Age Group] VARCHAR(50),
		Category VARCHAR(50),
		[Shipping Type] VARCHAR(50),
		[Frequency of Purchases] VARCHAR(50),
		[Number of Times] INT,
		[Average Cost] MONEY);

	INSERT INTO Age_Shipping_and_Frequency
	SELECT Age,[Age Group],Category,[Shipping Type],[Frequency of Purchases],COUNT([Frequency of Purchases]) AS 'Number of Times',ROUND(AVG([Purchase Amount (USD)]),2) AS 'Average Cost'
	FROM shopping_behavior
	GROUP BY Age,[Age Group],Category,[Shipping Type],[Frequency of Purchases]
	ORDER BY 'Number of Times' DESC;
END;


/*What impact does review rating have on product prices, purchase frequency, and shipment methods?
How does the review rating affect the purchases of different categories and their average cost?*/
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Category_vs_Review')
BEGIN
	CREATE TABLE Category_vs_Review(
		Category VARCHAR(50),
		[Review Rating] DECIMAL(10,2),
		[Number Sold] INT,
		[Average Cost] MONEY);
	INSERT INTO Category_vs_Review
	SELECT Category,[Review Rating],COUNT([Item Purchased]) AS 'Number Sold',ROUND(AVG([Purchase Amount (USD)]),2) AS 'Average Cost'
	FROM shopping_behavior
	GROUP BY Category,[Review Rating];
END;
--Do seasons affect Sales of products? 

--What are the most and least popuplar Category,shipping methods and payment methods in the season wise?
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Seasons_ShippingType_Payment')
BEGIN 
	CREATE TABLE Seasons_ShippingType_Payment(
			Season VARCHAR(50),
			Category VARCHAR(50),
			[Shipping Type] VARCHAR(50),
			[Payment Method] VARCHAR(50),
			[Number of Times] INT);

	INSERT INTO Seasons_ShippingType_Payment
	SELECT Season,Category,[Shipping Type],[Payment Method],COUNT([Payment Method]) AS 'Number of Times'
	FROM shopping_behavior
	GROUP BY Season,Category,[Shipping Type],[Payment Method]
	ORDER BY 'Number of Times' DESC;
END;
--What are the most and least in-demand items per season?
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Summer_sales')
BEGIN
	CREATE TABLE Summer_sales(
		Season VARCHAR(50),
		Gender VARCHAR(50),
		Category VARCHAR(50),
		[Item Purchased] VARCHAR(50),
		[Number Sold] INT,
		[Average Cost] MONEY);
	INSERT INTO Summer_sales
	SELECT Season,Gender,Category,[Item Purchased],COUNT([Item Purchased]) as 'Number Sold',AVG([Purchase Amount (USD)]) AS 'Average Cost'
	FROM shopping_behavior
	WHERE Season='Summer' 
	GROUP BY Season,Gender,[Item Purchased],Category
	ORDER BY 'Number Sold';
END;

--In Winter,which product have high purchases and least and their average price
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Winter_sales')
BEGIN
	CREATE TABLE Winter_sales(
	Season VARCHAR(50),
	Gender VARCHAR(50),
	Category VARCHAR(50),
	[Item Purchased] VARCHAR(50),
	[Number Sold] INT,
	[Average Cost] MONEY);

	INSERT INTO winter_sales
	SELECT Season,Gender,Category,[Item Purchased],COUNT([Item Purchased]) as 'Number Sold',AVG([Purchase Amount (USD)]) AS 'Average Cost'
	FROM shopping_behavior	WHERE Season='Winter' 
	GROUP BY Season,Gender,[Item Purchased],Category
	ORDER BY 'Number Sold';
END;


--And then Fall,which product have high purchases and least and their average price
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Fall_sales')
BEGIN
	CREATE TABLE Fall_sales(
	Season VARCHAR(50),
	Gender VARCHAR(50),
	Category VARCHAR(50),
	[Item Purchased] VARCHAR(50),
	[Number Sold] INT,
	[Average Cost] MONEY);

	INSERT INTO Fall_sales
	SELECT Season,Gender,Category,[Item Purchased],COUNT([Item Purchased]) as 'Number Sold',AVG([Purchase Amount (USD)]) AS 'Average Cost'
	FROM shopping_behavior
	WHERE Season='Fall' 
	GROUP BY Season,Gender,[Item Purchased],Category
	ORDER BY 'Number Sold';
END;


--In Spring,which product have high purchases and least and their average price
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Spring_sales')
BEGIN
	CREATE TABLE Spring_sales(
	Season VARCHAR(50),
	Gender VARCHAR(50),
	Category VARCHAR(50),
	[Item Purchased] VARCHAR(50),
	[Number Sold] INT,
	[Average Cost] MONEY);

	INSERT INTO Spring_sales
	SELECT Season,Gender,Category,[Item Purchased],COUNT([Item Purchased]) as 'Number Sold',AVG([Purchase Amount (USD)]) AS 'Average Cost'
	FROM shopping_behavior
	WHERE Season='Spring' 
	GROUP BY Season,Gender,[Item Purchased],Category
	ORDER BY 'Number Sold';
END;