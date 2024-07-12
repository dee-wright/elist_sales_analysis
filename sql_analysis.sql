-- Average delivery time by region
SELECT 
  geo_lookup.region, 
  AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)) AS avg_time_to_deliver
FROM core.orders
LEFT JOIN core.order_status 
  ON orders.id=order_status.order_id
LEFT JOIN core.customers 
  ON orders.customer_id=customers.id
LEFT JOIN core.geo_lookup 
  ON customers.country_code=geo_lookup.country
WHERE 
  (EXTRACT(YEAR FROM orders.purchase_ts)=2022 AND orders.purchase_platform='website')
  OR orders.purchase_platform='mobile app'
GROUP BY region
ORDER BY avg_time_to_deliver DESC

-- North America MacBook Sales by Quarter
SELECT 
  geo_lookup.region, 
  AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)) AS avg_time_to_deliver
FROM core.orders
LEFT JOIN core.order_status 
  ON orders.id=order_status.order_id
LEFT JOIN core.customers 
  ON orders.customer_id=customers.id
LEFT JOIN core.geo_lookup 
  ON customers.country_code=geo_lookup.country
WHERE 
  (EXTRACT(year from orders.purchase_ts)=2022 AND orders.purchase_platform='website')
  OR orders.purchase_platform='mobile app'
GROUP BY region
ORDER BY avg_time_to_deliver DESC

-- Refund rate and refund count by product
SELECT 
  CASE WHEN product_name LIKE '27in""%' THEN '27in 4K gaming monitor' ELSE product_name END AS product_clean,
  AVG(CASE WHEN refund_ts IS not null THEN 1 ELSE 0 END) AS refund_rate, 
  SUM(CASE WHEN refund_ts IS not null THEN 1 ELSE 0 END) AS refund_count
FROM core.orders
LEFT JOIN core.order_status 
  ON orders.id=order_status.order_id
GROUP BY product_clean
ORDER BY refund_rate DESC

-- Refunds by product and year
SELECT 
  EXTRACT(YEAR FROM orders.purchase_ts) AS purchase_year,
  CASE WHEN product_name LIKE '27in""%' THEN '27in 4K gaming monitor' ELSE product_name END AS product_clean,
  AVG(CASE WHEN refund_ts IS not null THEN 1 ELSE 0 END) AS refund_rate, 
  SUM(CASE WHEN refund_ts IS not null THEN 1 ELSE 0 END) AS refund_count
FROM core.orders
LEFT JOIN core.order_status 
  ON orders.id=order_status.order_id
GROUP BY purchase_year, product_clean
ORDER BY purchase_year

-- Most popular product in each region
WITH sales_by_product AS (
  SELECT region,
  product_name,
  COUNT(DISTINCT orders.id) AS total_orders
FROM core.orders
LEFT JOIN core.customers
  ON orders.customer_id = customers.id
LEFT JOIN core.geo_lookup
  ON geo_lookup.country = customers.country_code
GROUP BY region, product_name)

SELECT *, 
  row_number() over (PARTITION BY region ORDER BY total_orders DESC) AS order_ranking
FROM sales_by_product
QUALIFY row_number() over (PARTITION BY region ORDER BY total_orders DESC) = 1;

-- Time to purchase difference between loyalty & non-loyalty customers, per purchase platform
SELECT orders.purchase_platform, 
  customers.loyalty_program, 
  ROUND(AVG(DATE_DIFF(order_status.purchase_ts, customers.created_on, day)),1) AS days_to_purchase,
  ROUND(AVG(DATE_DIFF(order_status.purchase_ts, customers.created_on, month)),1) AS months_to_purchase,
  COUNT(*) AS row_count
FROM core.customers
LEFT JOIN core.orders
  ON customers.id = orders.customer_id
LEFT JOIN core.order_status
  ON order_status.order_id = orders.id
GROUP BY purchase_platform, loyalty_program

-- all distinct product IDs, product names, and product suppliers
SELECT product_id FROM core.orders
UNION DISTINCT
SELECT product_name FROM core.orders
UNION DISTINCT
SELECT supplier FROM core.suppliers;

-- distinct products purchased by each customer
SELECT customer_id, 
  string_agg(DISTINCT product_name, ", " ) AS distinct_products
FROM core.orders
GROUP BY customer_id;
