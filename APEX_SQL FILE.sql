USE apex_planet;
SELECT * FROM apexplanet_dataanalytics_dataset;
RENAME TABLE apexplanet_dataanalytics_dataset TO apex_data;
SELECT * FROM apex_data;

-- 1. What is the total revenue (Total_Sales) for each product category, sorted from highest to lowest?
SELECT Category, SUM(Total_Sales) AS Revenue
FROM apex_data 
GROUP BY Category 
ORDER BY Revenue DESC;

-- 2. Which city has the highest number of orders? 
-- Include the orders with a NULL city as their own group.
SELECT City, COUNT(Order_ID) AS Orders
FROM apex_data
GROUP BY City
ORDER BY Orders DESC;

-- 3. Find the total sales for each month of 2025. Which month had the highest revenue?
SELECT monthname(Order_Date) AS month, 
SUM(Quantity) AS Total_Quantity,
ROUND(SUM(Total_Sales),2) AS Revenue
FROM apex_data
GROUP BY month
ORDER BY Revenue DESC ;

-- 4. Compare the average Total_Sales for Male and Female customers within each category.
SELECT Category, Gender,ROUND(AVG(Total_Sales),2) AS Revenue
FROM apex_data
GROUP BY Category, Gender
ORDER BY Category ;


-- 5. Which orders were placed by customers under 30 years old with an order value exceeding average price?
SELECT Customer_ID, Age, Total_Sales
FROM apex_data
where Age < 30 and 
(SELECT AVG(Total_Sales) FROM apex_data);


-- 6. Find the customers (Customer_ID) who placed more than one order. Show their order count and total spend.
SELECT Customer_ID, 
		COUNT(Order_ID) AS order_count , 
        SUM(Total_Sales) AS Total_spend
FROM apex_data
GROUP BY Customer_ID
HAVING order_count > 1;

-- 7. Which cities have total sales above the overall average city sales?
WITH city_sale AS (
	SELECT City, SUM(Total_Sales) AS Revenue 
    FROM apex_data
	group by City)
		(SELECT City , Revenue 
        FROM city_sale 
        WHERE Revenue > (SELECT AVG(Revenue) FROM city_sale))
	ORDER BY Revenue DESC ;

-- 8. Create age groups (18–25, 26–35, 36–50, 51+, Unknown) using CASE WHEN. Show the number of orders  
-- and the average order value for each group.

SELECT CASE
	WHEN Age BETWEEN 18 AND 25 THEN '18–25'
	WHEN Age BETWEEN 26 AND 35 THEN '26–35'
	WHEN Age BETWEEN 36 AND 50 THEN '36–50'
	WHEN Age >=51 THEN '51+'
	ELSE 'UNKNOWN'
	END AS Age_Div,
        COUNT(Order_ID) AS Orders,
        ROUND(AVG(Total_Sales),2) AS Revenue
	FROM apex_data
	GROUP BY Age_Div
	ORDER BY Age_Div;

-- 9. Rank the products by revenue using RANK() or DENSE_RANK().
SELECT Product ,ROUND(SUM(Total_Sales),2) AS Revenue,
DENSE_RANK() OVER(
				ORDER BY SUM(Total_Sales) DESC)  AS Product_Rank
FROM apex_data 
GROUP BY Product
ORDER BY Product_Rank;

-- 10. Calculate month-over-month revenue growth (%) using LAG().
WITH Monthly_sale AS(SELECT DATE_FORMAT(Order_Date,'%Y-%M') AS Months,
					ROUND(SUM(Total_Sales),2) AS Revenue 
                    FROM apex_data
                    GROUP BY DATE_FORMAT(Order_Date,'%Y-%M')
                    )
SELECT Months,Revenue,
		ROUND(LAG(Revenue)OVER (ORDER BY Months),2) AS Previous_month_sale,
        ROUND(
        ((Revenue-LAG(Revenue)OVER (ORDER BY Months))/LAG(Revenue)OVER (ORDER BY Months))*100
        ,2) AS MOM_growth_Percent
        FROM Monthly_sale
        ORDER BY Months;


-- 11. Find the top 3 cities by revenue for each category, using a CTE with ROW_NUMBER().
WITH City_sale AS(
		SELECT  Category, City, ROUND(SUM(Total_Sales),2) AS Revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category 
            ORDER BY SUM(total_sales) DESC) AS rank_num
        FROM apex_data
        GROUP BY  Category,City  )
SELECT Category, City, Revenue, rank_num
FROM City_sale
WHERE rank_num <= 3
ORDER BY category,rank_num ;


-- 12. Show the running (cumulative) total of sales ordered by `Order_Date`.
-- running total per order (row by row)
SELECT 
    Order_ID,Order_Date,Total_Sales,
    ROUND(SUM(Total_Sales) OVER (
		  ORDER BY Order_Date, Order_ID), 2) AS running_total
FROM apex_data
ORDER BY Order_Date, Order_ID;