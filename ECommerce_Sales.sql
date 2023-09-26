----SQL code to clean ECommerce sales data prior to Power BI dashboard build

--Alter Date columns to reflect historical dates (not future)

ALTER TABLE sales_data
Add SaleDateConverted date

UPDATE sales_data
SET SaleDateConverted = DATEADD(year, -4, Saledate)

ALTER TABLE sales_data
Add ShippingDateConverted date

UPDATE sales_data
SET ShippingDateConverted = DATEADD(year, -4, ShippingDate)

ALTER TABLE sales_data
Add DeliveryDateConverted date

UPDATE sales_data
SET DeliveryDateConverted = DATEADD(year, -4, DeliveredDate)

--Create SaleToShipTime, ShipToDeliveryTime, SaleToDeliveryTime

ALTER TABLE sales_data
Add SaleToShipTime int

UPDATE sales_data
SET SaleToShipTime = DATEDIFF(day,SaleDateConverted,ShippingDateConverted)

ALTER TABLE sales_data
Add ShipToDeliveryTime int

UPDATE sales_data
SET ShipToDeliveryTime = DATEDIFF(day,ShippingDateConverted, DeliveryDateConverted)

ALTER TABLE sales_data
Add SaleToDeliveryTime int

UPDATE sales_data
SET SaleToDeliveryTime = DATEDIFF(day,SaleDateConverted, DeliveryDateConverted)

--Create TotalRevenue Column
 
 ALTER TABLE sales_data
 Add TotalRevenue money

 UPDATE sales_data
 SET TotalRevenue = SoldQuantity*ItemPrice


--Queries
--What is the top selling product by Quantity?
Select TOP(1)ProductName, SUM(SoldQuantity) AS TotalQuantity
From sales_data
GROUP BY ProductName
ORDER BY TotalQuantity DESC

--What is the top selling product by Revenue?
Select TOP(1)ProductName, SUM(TotalRevenue) AS ProductRevenue
From sales_data
GROUP BY ProductName
ORDER BY ProductRevenue DESC

--Which shop has the highest Revenue?
Select TOP(1)ShopName, SUM(TotalRevenue) as ShopRevenue
From sales_data
GROUP BY ShopName
ORDER BY ShopRevenue DESC

--Which Country had the highest number of sales?
Select TOP(1)CustomerCountry, COUNT(SaleID) as NumberOfSales
From sales_data
GROUP BY CustomerCountry
ORDER BY NumberOfSales DESC

--What is the average wait time for deliveries?
Select 
	AVG(SaleToShipTime) as 'Average Days From Sale to Shipped',
	AVG(ShipToDeliveryTime) as 'Average Days In Transit',
	AVG(SaleToDeliveryTime) as 'Average Days From Sale to Delivery'
From sales_data

--How many items were purchased on each weekday?
SELECT
    DATEPART(weekday, SaleDate) AS WeekdayNumber,
    DATENAME(weekday, SaleDate) AS WeekdayName,
    COUNT(*) AS ItemsSold
FROM sales_data
GROUP BY DATEPART(weekday, SaleDate), DATENAME(weekday, SaleDate)
ORDER BY WeekdayNumber

--How many sales were made from Countries that were the same as the Customer?
Select COUNT(CustomerID) AS NumCustomers
From sales_data
Where CustomerCountry = ShopLocationCountry
