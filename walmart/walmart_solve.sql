-- What are the different payment methods, and how many transactions and items were sold with each method?
SELECT payment_method, COUNT(*) total_transactions, SUM(quantity) total_items_sold
FROM walmart
GROUP BY 1
ORDER BY 2 DESC;

-- Which category received the highest average rating in each branch?
SELECT * FROM (
	SELECT branch, category, ROUND(AVG(rating::NUMERIC),2) AS avg_rating,
	RANK() OVER(
		PARTITION BY branch ORDER BY AVG(rating) DESC
	) AS rk
	FROM walmart
	GROUP BY 1, 2
)
WHERE rk =1

-- What is the busiest day of the week for each branch based on transaction volume?
SELECT * FROM (
SELECT branch, TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS Day, COUNT(*) transactions,
RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rk
FROM walmart
GROUP BY 1,2
ORDER BY 1, 3 DESC
)
WHERE rk = 1;


-- How many items were sold through each payment method?
SELECT payment_method, SUM(quantity) AS total_qty_sold 
FROM walmart
GROUP BY 1 
ORDER BY 2;

-- What are the average, minimum, and maximum ratings for each category in each city?
SELECT city, category, ROUND(AVG(rating::NUMERIC),2) avg_ratings, MAX(rating) max_ratings, MIN(rating) min_ratings 
FROM walmart
GROUP BY 1, 2
ORDER BY 3, 4, 5;

-- What is the total profit for each category, ranked from highest to lowest?
SELECT category, ROUND(SUM(total::NUMERIC * profit_margin::NUMERIC),2) AS total_profit
FROM walmart
GROUP BY 1
ORDER BY 2 DESC;

-- What is the most frequently used payment method in each branch?
SELECT * FROM (
SELECT branch, payment_method, COUNT(payment_method) AS payment_method,
RANK() OVER(PARTITION BY branch ORDER BY COUNT(payment_method) DESC) AS rk
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3
)
WHERE rk = 1

-- How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
SELECT branch, CASE 
	WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'Morning'
	WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
	ELSE 'Evening'
END day_time,
COUNT(*) AS transactions
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- Which branches experienced the largest decrease in revenue compared to the previous year?
WITH 
rev_22 AS (
	SELECT branch, SUM(total) AS revenue_2022
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
	GROUP BY 1
	ORDER BY 1, 2 
),
rev_23 AS (
SELECT branch, SUM(total) AS revenue_2023
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
	ORDER BY 1, 2
)

SELECT ls.branch, ls.revenue_2022, cs.revenue_2023, ROUND(((ls.revenue_2022 - cs.revenue_2023)/ ls.revenue_2022 *100)::NUMERIC,2) AS ratio
FROM rev_22 AS ls
JOIN rev_23 AS cs
ON ls.branch = cs.branch
WHERE ls.revenue_2022 > cs.revenue_2023
ORDER BY 4 DESC
LIMIT 5;

 




