select * from dbo.Customers

select * from dbo.Exchange_Rates

select * from dbo.Products

select * from dbo.Sales

select * from dbo.Stores

--KIỂM TRA GIÁ TRỊ NULL Ở TỪNG BẢNG
SELECT * 
FROM dbo.Sales
WHERE  Order_Number is null 
	or Line_Item is null
	or Order_Date is null 
	or CustomerKey is null
	or StoreKey is null
	or ProductKey is null
	or Quantity is null
	or Currency_Code is null

select * 
from dbo.Customers
WHERE CustomerKey is null
	or Gender is null
	or Name is null
	or City is null
	or State_Code is null
	or State is null
	or Zip_Code is null
	or Country is null
	or Continent is null
	or Birthday is null

select * 
from dbo.Exchange_Rates
WHERE Date IS NULL
	OR Currency IS NULL
	OR Exchange IS NULL

select * 
from dbo.Products
WHERE ProductKey IS NULL
	OR Product_Name IS NULL
	OR Brand IS NULL
	OR Color IS NULL
	OR Unit_Cost_USD IS NULL
	OR Unit_Price_USD IS NULL
	OR SubcategoryKey IS NULL
	OR Subcategory IS NULL
	OR CategoryKey IS NULL
	OR Category IS NULL

select * 
from dbo.Stores
WHERE StoreKey IS NULL
	OR Country IS NULL
	OR State IS NULL
	OR Square_Meters IS NULL
	OR Open_Date IS NULL

--FILL SQUARE_METERS CỦA KÊNH ONLINE = 0 
update dbo.Stores
set Square_Meters = 0
where StoreKey = 0 

--THÊM CÁC CỘT CẦN THIẾT\

ALTER TABLE dbo.Sales
ADD 
    Revenue FLOAT,
    Cost FLOAT,
    Profit FLOAT,
	Age int;

UPDATE Sales
SET 
    Sales.Revenue = Products.Unit_Price_USD * Sales.Quantity,
    Sales.Cost = Products.Unit_Cost_USD * Sales.Quantity
FROM dbo.Sales Sales
LEFT JOIN dbo.Products Products ON Sales.ProductKey = Products.ProductKey;

UPDATE dbo.Sales
SET Profit = Revenue - Cost;

UPDATE Sales
SET 
    Sales.Age = YEAR(Sales.order_date) - YEAR(Cust.Birthday)
FROM dbo.Sales Sales
LEFT JOIN dbo.Customers Cust ON Sales.CustomerKey = Cust.CustomerKey;

--SALES OVERVIEW

--Doanh thu và lợi nhuận theo tháng/năm
SELECT 
     Year          = YEAR(Order_Date)
    ,Month         = MONTH(Order_Date)
    ,Total_Revenue = ROUND(SUM(Revenue), 2)
	,Total_Cost    = ROUND(SUM(Cost),2)
    ,Total_Profit  = ROUND(SUM(Profit), 2)
FROM dbo.Sales
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Year, Month;

--Top sản phẩm theo số lượng bán / doanh thu
SELECT 
     Products.Product_Name
    ,Total_Quantity_Sold = SUM(Sales.Quantity)
    ,Total_Revenue = ROUND(SUM(Sales.Revenue),2) 
FROM dbo.Sales Sales
JOIN dbo.Products Products ON Sales.ProductKey = Products.ProductKey
GROUP BY Products.Product_Name
ORDER BY Total_Revenue DESC

--Top cửa hàng theo doanh thu
SELECT 
     St.StoreKey
    ,St.Country
    ,St.State
    ,Total_Revenue = ROUND(SUM(Sales.Revenue),2)
FROM dbo.Sales Sales
LEFT JOIN dbo.Stores St ON Sales.StoreKey = St.StoreKey
GROUP BY St.StoreKey, St.Country, St.State
ORDER BY Total_Revenue DESC;

--Hiệu suất theo quốc gia / state / continent
SELECT 
     Cust.Country
    ,Cust.State
    ,Cust.Continent
    ,Total_Revenue = ROUND(SUM(Sales.Revenue),2)
    ,Total_Profit = ROUND(SUM(Sales.Profit),2)
FROM dbo.Sales Sales
LEFT JOIN dbo.Customers Cust ON Sales.CustomerKey = Cust.CustomerKey
GROUP BY Cust.Country, Cust.State, Cust.Continent
ORDER BY Total_Revenue DESC;

/*PHÂN KHÚC KHÁCH HÀNG*/

--Phân tích theo giới tính, độ tuổi, quốc gia
SELECT 
     Cust.Gender
    ,Cust.Country
    ,Sales.Age
    ,Total_Revenue = ROUND(SUM(Sales.Revenue),2)
FROM dbo.Sales Sales
LEFT JOIN dbo.Customers Cust ON Sales.CustomerKey = Cust.CustomerKey
GROUP BY Cust.Gender, Cust.Country, Sales.Age;

--RFM Analysis (Recency – Frequency – Monetary)
SELECT 
     Cust.CustomerKey
    ,Last_Order_Date = MAX(Sales.Order_Date)
    ,Frequency = COUNT(DISTINCT Sales.Order_Number) 
    ,Monetary_Value = SUM(Sales.Revenue)
    ,Recency = DATEDIFF(DAY, MAX(Sales.Order_Date), GETDATE())
FROM dbo.Sales Sales
LEFT JOIN dbo.Customers Cust ON Sales.CustomerKey = Cust.CustomerKey
GROUP BY Cust.CustomerKey
ORDER BY Frequency desc

--Tổng doanh thu mỗi khách hàng
SELECT 
     Cust.CustomerKey
    ,Cust.Name
    ,CLV = SUM(Sales.Revenue)
FROM dbo.Sales Sales
LEFT JOIN dbo.Customers Cust ON Sales.CustomerKey = Cust.CustomerKey
GROUP BY Cust.CustomerKey, Cust.Name
ORDER BY CLV DESC;

/*Phân tích sản phẩm*/
--Biên lợi nhuận từng sản phẩm
SELECT 
     Products.ProductKey,
     Products.Product_Name,
     Total_Revenue = ROUND(SUM(Sales.Revenue), 2),
     Total_Cost = ROUND(SUM(Sales.Cost), 2),
     Profit_Margin = ROUND((SUM(Sales.Revenue) - SUM(Sales.Cost)) / SUM(Sales.Revenue), 2)
FROM dbo.Sales Sales
LEFT JOIN dbo.Products Products ON Sales.ProductKey = Products.ProductKey
GROUP BY Products.ProductKey, Products.Product_Name
ORDER BY Profit_Margin DESC;

--Hiệu suất theo Category/Subcategory/Brand
SELECT 
     Products.Category
    ,Products.Subcategory
    ,Products.Brand
    ,Total_Revenue = SUM(Sales.Revenue) 
    ,Total_Profit = SUM(Sales.Profit) 
FROM dbo.Sales Sales
JOIN dbo.Products Products ON Sales.ProductKey = Products.ProductKey
GROUP BY Products.Category, Products.Subcategory, Products.Brand
ORDER BY Total_Revenue DESC;

--Màu nào được ưa chuộng nhất?
SELECT 
     Products.Color
    ,Total_Sold = SUM(Sales.Quantity)
FROM dbo.Sales Sales
LEFT JOIN dbo.Products Products ON Sales.ProductKey = Products.ProductKey
GROUP BY Products.Color
ORDER BY Total_Sold DESC;

--Cohort Analysis – Nhóm khách hàng theo tháng đầu mua
WITH FirstPurchase AS (
    SELECT 
        CustomerKey,
        MIN(Order_Date) AS First_Order_Date
    FROM Sales
    GROUP BY CustomerKey
),
CohortData AS (
    SELECT 
        S.CustomerKey,
        YEAR(FP.First_Order_Date) AS Cohort_Year,
        MONTH(FP.First_Order_Date) AS Cohort_Month,
        YEAR(S.Order_Date) AS Order_Year,
        MONTH(S.Order_Date) AS Order_Month,
        DATEDIFF(MONTH, FP.First_Order_Date, S.Order_Date) AS Cohort_Index,
        S.Revenue
    FROM Sales S
    JOIN FirstPurchase FP ON S.CustomerKey = FP.CustomerKey
)
SELECT 
    Cohort_Year,
    Cohort_Month,
    Cohort_Index,
    COUNT(DISTINCT CustomerKey) AS Customers,
    SUM(Revenue) AS Revenue
FROM CohortData
GROUP BY Cohort_Year, Cohort_Month, Cohort_Index
ORDER BY Cohort_Year, Cohort_Month, Cohort_Index;


-- CTE trước
WITH FirstPurchase AS (
    SELECT 
        CustomerKey,
        MIN(Order_Date) AS First_Order_Date
    FROM Sales
    GROUP BY CustomerKey
),
CohortData AS (
    SELECT 
        FORMAT(FP.First_Order_Date, 'yyyy-MM') AS Cohort_Label,
        DATEDIFF(MONTH, FP.First_Order_Date, S.Order_Date) AS Cohort_Index,
        S.CustomerKey,
        S.Revenue
    FROM Sales S
    JOIN FirstPurchase FP ON S.CustomerKey = FP.CustomerKey
)

-- SELECT INTO sau
SELECT 
    Cohort_Label,
    Cohort_Index,
    COUNT(DISTINCT CustomerKey) AS Customers,
    SUM(Revenue) AS Revenue
INTO dbo.Cohort_Table
FROM CohortData
GROUP BY Cohort_Label, Cohort_Index;

select * from dbo.Cohort_Table

ALTER TABLE Sales
ADD Order_Label AS FORMAT(Order_Date, 'yyyy-MM'); 
select * from dbo.Sales 

