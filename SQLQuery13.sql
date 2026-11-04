DROP TABLE IF EXISTS zepto_1;
DROP TABLE IF EXISTS Sheet1$;
GO

CREATE TABLE zepto_1 (
    sku_id INT IDENTITY(1,1) PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp NUMERIC(8,2),
    discountPercent NUMERIC(5,2),
    availableQuantity INT,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms INT,
    outOfStock BIT,
    quantity INT
);

-- Staging table: same columns as the CSV, in the same order, no sku_id
CREATE TABLE zepto_staging (
    category VARCHAR(120),
    name VARCHAR(150),
    mrp NUMERIC(8,2),
    discountPercent NUMERIC(5,2),
    availableQuantity INT,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms INT,
    outOfStock VARCHAR(10),
    quantity INT
);
GO

BULK INSERT zepto_staging
FROM 'C:\Users\anies\Downloads\zepto_v1.csv'
WITH (
    FORMAT = 'CSV',          -- handles quoted fields with commas (SQL Server 2017+)
    FIRSTROW = 2,            -- skip the header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',  -- use '\n' or '0x0d0a' if rows don't load
    CODEPAGE = '65001'       -- UTF-8
);
GO

INSERT INTO zepto_1(category, name, mrp, discountPercent, availableQuantity,
                   discountedSellingPrice, weightInGms, outOfStock, quantity)
SELECT category, name, mrp, discountPercent, availableQuantity,
       discountedSellingPrice, weightInGms,
       CASE WHEN UPPER(outOfStock) IN ('TRUE', '1') THEN 1 ELSE 0 END,
       quantity
FROM zepto_staging;
GO

DROP TABLE zepto_staging;
GO

SELECT TOP 10 * FROM zepto_1;

Select count(*) from zepto_1;

SELECT DISTINCT category
FROM zepto_1
ORDER BY category;

SELECT outOfStock, COUNT(sku_id)
FROM zepto_1
GROUP BY outOfStock;

SELECT name, COUNT(sku_id) AS "Number of SKUs"
FROM zepto_1
GROUP BY name
HAVING count(sku_id) > 1
ORDER BY count(sku_id) DESC;

SELECT * FROM zepto_1
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto_1
WHERE mrp = 0;

UPDATE zepto_1
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto_1;

-- Q1. Find the top 10 beat-value products based on the discount %. 
SELECT TOP 10 WITH TIES
    name,
    mrp,
    discountPercent
FROM zepto_1
GROUP BY name, mrp, discountPercent
ORDER BY discountPercent DESC;

-- Q2. What are the products with High MRP but Out of Stock. True = 1
SELECT DISTINCT name,mrp
FROM zepto_1
WHERE outOfStock = 1 and mrp > 300
ORDER BY mrp DESC;

-- Q3. Calulate Estimated Revenue for each category. 
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto_1
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find all products where MRP is greater than 500 and discounted %.
SELECT top 10
category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto_1
GROUP BY category
ORDER BY avg_discount DESC;

-- Q6. Find the price per gram for products above 100g and sort by best value.
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto_1
WHERE weightInGms >= 100
ORDER BY price_per_gram;

--Q7.Group the products into categories like Low, Medium, Bulk.
SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto_1;

--Q8.What is the Total Inventory Weight Per Category 
SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto_1
GROUP BY category
ORDER BY total_weight;