DROP TABLE IF EXISTS superstore

CREATE TABLE IF NOT EXISTS superstore (
    row_id INTEGER,
    order_id VARCHAR(30),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(30),
    customer_id VARCHAR(30),
    customer_name VARCHAR(100),
    segment VARCHAR(30),
    country VARCHAR(50),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(30),
    product_id VARCHAR(30),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales NUMERIC(12,2),
    quantity INTEGER,
    discount NUMERIC(5,2),
    profit NUMERIC(12,2),
    discount_group VARCHAR(30),
    profit_margin varchar(20)
);

COPY public.superstore(
row_id, order_id, order_date, ship_date, ship_mode,
customer_id, customer_name, segment, country, city, state,
postal_code, region, product_id, category, sub_category,
product_name, sales, quantity, discount, profit,
discount_group, profit_margin
)
FROM 'D:/MEHUL/Data Analyst/projects/Revenue Leakage & Pricing Intelligence System/Cleaned_Superstore.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

--BASICS
SELECT * FROM SUPERSTORE

SELECT SUM(sales) AS TOTAL_SALES FROM SUPERSTORE

SELECT SUM(PROFIT) AS TOTAL_PROFIT FROM SUPERSTORE

SELECT SUM(PROFIT)/SUM(SALES)*100 AS PROFIT_MARGIN FROM SUPERSTORE

--CATEGORY ANALYSIS

SELECT CATEGORY,
SUM(SALES) AS TOTAL_SALES,
SUM(PROFIT) AS TOTAL_PROFIT,
SUM(PROFIT)/SUM(SALES)*100 AS MARGIN
FROM SUPERSTORE
GROUP BY CATEGORY
ORDER BY TOTAL_SALES DESC

SELECT SUB_CATEGORY,
SUM(SALES) AS TOTAL_SALES,
SUM(PROFIT) AS TOTAL_PROFIT
FROM SUPERSTORE
GROUP BY SUB_CATEGORY
HAVING SUM(PROFIT) <=0
ORDER BY TOTAL_PROFIT

--DISCOUNT ANALYSIS

SELECT 	
	CASE
		WHEN DISCOUNT = 0 THEN '0%'
		WHEN DISCOUNT <= 0.10 THEN '1-10%'
		WHEN DISCOUNT <= 0.20 THEN '11-20%'
		WHEN DISCOUNT <= 0.30 THEN '21-30%'
		ELSE '>30%'
	END AS DISCOUNT_GROUP,

	SUM(SALES) AS TOTAL_SALES,
	SUM(PROFIT) AS TOTAL_PROFIT,
	SUM(SALES)/SUM(PROFIT)*100 AS MARGIN
 FROM SUPERSTORE
 GROUP BY 
 	CASE
		WHEN DISCOUNT = 0 THEN '0%'
		WHEN DISCOUNT <= 0.10 THEN '1-10%'
		WHEN DISCOUNT <= 0.20 THEN '11-20%'
		WHEN DISCOUNT <= 0.30 THEN '21-30%'
		ELSE '>30%'
	END
	ORDER BY TOTAL_SALES DESC;


SELECT PRODUCT_NAME,
SUM(SALES) AS TOTAL_SALES,
SUM(PROFIT) AS TOTAL_PROFIT,
SUM(PROFIT)/SUM(SALES)*100 AS MARGIN
FROM SUPERSTORE
GROUP BY PRODUCT_NAME
HAVING SUM(PROFIT)<=0
ORDER BY TOTAL_PROFIT
LIMIT 10

SELECT PRODUCT_NAME,CATEGORY,SUB_CATEGORY,
SUM(SALES) AS TOTAL_SALES,
SUM(PROFIT) AS TOTAL_PROFIT,
AVG(DISCOUNT) *100 AS AVG_DISCOUNT,
SUM(PROFIT)/SUM(SALES)*100 AS MARGIN
FROM SUPERSTORE
GROUP BY PRODUCT_NAME,CATEGORY,SUB_CATEGORY
HAVING SUM(PROFIT)<=0
ORDER BY TOTAL_PROFIT

WITH PRODUCT_ANALYSIS AS(
SELECT PRODUCT_NAME,CATEGORY,SUB_CATEGORY,
SUM(SALES) AS TOTAL_SALES,
SUM(PROFIT) AS TOTAL_PROFIT,
AVG(DISCOUNT) AS AVG_DISCOUNT
SUM(PROFIT)/SUM(SALES)*100 AS MARGIN
FROM SUPERSTORE
GROUP BY PRODUCT_NAME,CATEGORY,SUB_CATEGORY
)
SELECT * FROM PRODUCT_ANALYSIS
HAVING TOTAL_PROFIT <=0
ORDER BY TOTAL_PROFIT


--ADVANCE
SELECT
    Product_Name,
    Category,
    Sub_Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    AVG(Discount) * 100 AS Avg_Discount,
    SUM(Profit) / NULLIF(SUM(Sales), 0) * 100 AS Profit_Margin
FROM superstore
GROUP BY
    Product_Name,
    Category,
    Sub_Category
HAVING SUM(Profit) < 0
ORDER BY Total_Profit ASC
LIMIT 10;



WITH product_loss AS (
    SELECT
        Product_Name,
        Category,
        Sub_Category,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit,
        AVG(Discount) AS Avg_Discount
    FROM superstore
    GROUP BY
        Product_Name,
        Category,
        Sub_Category
    HAVING SUM(Profit) < 0
)
SELECT
    *,
    RANK() OVER (ORDER BY Total_Profit ASC) AS Loss_Rank
FROM product_loss
ORDER BY Loss_Rank;



SELECT
    SUM(Profit) AS Total_Loss
FROM superstore
WHERE Profit < 0;



SELECT
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    AVG(Discount) * 100 AS Avg_Discount,
    SUM(Profit) / NULLIF(SUM(Sales), 0) * 100 AS Profit_Margin
FROM superstore
WHERE Discount > 0.30
GROUP BY Category
ORDER BY Total_Profit ASC;



WITH product_analysis AS (
    SELECT
        Product_Name,
        Category,
        Sub_Category,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit,
        AVG(Discount) AS Avg_Discount
    FROM superstore
    GROUP BY
        Product_Name,
        Category,
        Sub_Category
),
ranked_products AS (
    SELECT
        *,
        Total_Profit / NULLIF(Total_Sales, 0) * 100
            AS Profit_Margin,
        RANK() OVER (ORDER BY Total_Profit ASC) AS Loss_Rank
    FROM product_analysis
    WHERE Total_Profit < 0
)
SELECT
    Loss_Rank,
    Product_Name,
    Category,
    Sub_Category,
    ROUND(Total_Sales::numeric, 2) AS Total_Sales,
    ROUND(Total_Profit::numeric, 2) AS Total_Profit,
    ROUND((Avg_Discount * 100)::numeric, 2) AS Avg_Discount,
    ROUND(Profit_Margin::numeric, 2) AS Profit_Margin
FROM ranked_products
ORDER BY Loss_Rank;


--Calculate cumulative loss
WITH product_loss AS (

    SELECT
        Product_Name,
        Category,
        Sub_Category,
        SUM(Profit) AS Total_Profit

    FROM superstore

    GROUP BY
        Product_Name,
        Category,
        Sub_Category

    HAVING SUM(Profit) < 0
),

loss_ranked AS (

    SELECT
        *,
        SUM(ABS(Total_Profit)) OVER () AS Total_Loss,

        SUM(ABS(Total_Profit)) OVER (
            ORDER BY Total_Profit ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Loss

    FROM product_loss
)

SELECT
    Product_Name,
    Category,
    Sub_Category,
    Total_Profit,
    Cumulative_Loss,
    Cumulative_Loss / Total_Loss * 100 AS Cumulative_Loss_Percentage
FROM loss_ranked
ORDER BY Total_Profit ASC;


--Find the worst 10% of products
WITH product_loss AS (

    SELECT
        Product_Name,
        Category,
        Sub_Category,
        SUM(Profit) AS Total_Profit

    FROM superstore

    GROUP BY
        Product_Name,
        Category,
        Sub_Category

    HAVING SUM(Profit) < 0
),

ranked AS (

    SELECT
        *,
        NTILE(10) OVER (
            ORDER BY Total_Profit ASC
        ) AS Loss_Decile

    FROM product_loss
)

SELECT
    Loss_Decile,
    COUNT(*) AS Product_Count,
    SUM(Total_Profit) AS Total_Profit_Loss
FROM ranked
GROUP BY Loss_Decile
ORDER BY Loss_Decile;

--Leakage Score
WITH product_analysis AS (

    SELECT
        Product_Name,
        Category,
        Sub_Category,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit,
        AVG(Discount) AS Avg_Discount

    FROM superstore

    GROUP BY
        Product_Name,
        Category,
        Sub_Category
)

SELECT
    Product_Name,
    Category,
    Sub_Category,
    Total_Sales,
    Total_Profit,
    Avg_Discount * 100 AS Avg_Discount,
    Total_Profit / NULLIF(Total_Sales,0) * 100 AS Profit_Margin,

    CASE
        WHEN Total_Profit < 0
             AND Avg_Discount > 0.30
            THEN 'Critical Leakage'

        WHEN Total_Profit < 0
             THEN 'Profit Leakage'

        WHEN Total_Profit >= 0
             AND Avg_Discount > 0.30
            THEN 'Discount Risk'

        ELSE 'Healthy'
    END AS Leakage_Status

FROM product_analysis
ORDER BY Total_Profit ASC;