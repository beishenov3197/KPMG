# Age of customers
SELECT TIMESTAMPDIFF(YEAR, DOB, CURDATE()) AS age, COUNT(*) AS customer_count
FROM kpmg_2
GROUP BY age
ORDER BY age;

# Distribution of order volume
SELECT customer_id,
       COUNT(transaction_id) AS order_count,
       SUM(list_price) AS total_revenue,
       SUM(list_price - standard_cost) AS total_profit
FROM kpmg_1
GROUP BY customer_id;

# Frequency customer
SELECT
  customer_id,
  COUNT(transaction_id) AS frequency,
  EXTRACT(YEAR FROM transaction_date) AS order_year
FROM
  kpmg_1
GROUP BY
  customer_id, EXTRACT(YEAR FROM transaction_date);

# Gender customer
SELECT gender, COUNT(*) AS customer_count
FROM kpmg_2
GROUP BY gender;

# Monetary customers - profit 
SELECT
  k.customer_id,
  SUM(k.list_price - k.standard_cost) AS profit
FROM
  kpmg_1 k
GROUP BY
  k.customer_id;

# Revenue and profit by online orders
SELECT online_order,
       COUNT(transaction_id) AS order_count,
       SUM(list_price) AS total_revenue,
       SUM(list_price - standard_cost) AS total_profit
FROM kpmg_1
GROUP BY online_order;

# Profit by months
SELECT DATE_FORMAT(transaction_date, '%m') AS month,
       SUM(list_price - standard_cost) AS total_profit
FROM kpmg_1
GROUP BY DATE_FORMAT(transaction_date, '%m')
ORDER BY DATE_FORMAT(transaction_date, '%m');

#Quintilies
SELECT
  customer_id,
  NTILE(5) OVER (ORDER BY DATEDIFF((SELECT MAX(transaction_date) FROM kpmg_1), MAX(transaction_date))) AS recency_quintile,
  NTILE(5) OVER (ORDER BY frequency) AS frequency_quintile,
  NTILE(5) OVER (ORDER BY monetary) AS monetary_quintile
FROM (
  SELECT
    customer_id,
    COUNT(transaction_id) AS frequency,
    ROUND(SUM(list_price - standard_cost)) AS monetary,
    MAX(transaction_date) AS transaction_date
  FROM kpmg_1
  GROUP BY customer_id
) AS subquery
GROUP BY customer_id;

# Recency customers
SELECT
  customer_id,
  DATEDIFF((SELECT MAX(transaction_date) FROM kpmg_1), MAX(transaction_date)) AS days_since_last_transaction
FROM
  kpmg_1
GROUP BY
  customer_id;

# Revenue and profit by brands
SELECT brand,
       COUNT(transaction_id) AS order_count,
       SUM(list_price) AS total_revenue,
       SUM(list_price - standard_cost) AS total_profit
FROM kpmg_1
GROUP BY brand;

# Revenue by months
SELECT DATE_FORMAT(transaction_date, '%m') AS month,
       SUM(list_price) AS total_revenue
FROM kpmg_1
GROUP BY DATE_FORMAT(transaction_date, '%m')
ORDER BY DATE_FORMAT(transaction_date, '%m');

# Tenures of customers
SELECT tenure, COUNT(*) AS customer_count, SUM(past_3_years_bike_related_purchases) AS total_bike_purchases
FROM kpmg_2
GROUP BY tenure
ORDER BY tenure;


# RFM segmentation 
WITH rfm_analysis AS (
    SELECT
        customer_id,
        DATEDIFF(MAX(transaction_date), (SELECT MAX(transaction_date) FROM kpmg_1)) AS recency,
        COUNT(transaction_id) AS frequency,
        AVG(list_price) AS avg_spending
    FROM adi_kpmg.kpmg_1
    GROUP BY customer_id
),
quintiles AS (
    SELECT
        customer_id,
        recency,
        frequency,
        NTILE(5) OVER (ORDER BY recency) AS recency_quintile,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_quintile,
        avg_spending
    FROM rfm_analysis
)

SELECT
    CASE
        WHEN recency_quintile = 1 AND frequency_quintile = 5 THEN 'Best Customers'
        WHEN recency_quintile = 4 AND frequency_quintile BETWEEN 4 AND 5 THEN 'Loyal Customers'
        WHEN recency_quintile = 3 OR frequency_quintile BETWEEN 3 AND 4 THEN 'High Value Customers'
        WHEN recency_quintile BETWEEN 2 AND 3 AND frequency_quintile BETWEEN 3 AND 5 THEN 'Mid Value Customers'
        WHEN recency_quintile = 2 AND frequency_quintile BETWEEN 2 AND 3 THEN 'Promising Customers'
        WHEN recency_quintile = 2 AND frequency_quintile BETWEEN 2 AND 4 THEN 'Low Value Customers'
        WHEN recency_quintile = 2 AND frequency_quintile BETWEEN 1 AND 2 THEN 'At Risk'
        WHEN recency_quintile = 1 AND frequency_quintile = 1 THEN 'Churned Customers'
        ELSE 'Other'
    END AS segment,
    AVG(frequency) AS avg_frequency,
    AVG(avg_spending) AS avg_spending
FROM quintiles
GROUP BY segment; 



