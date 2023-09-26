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


