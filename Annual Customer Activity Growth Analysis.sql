--COUNT MONTHLY ACTIVE USER GROWTH
WITH count_mau AS (
SELECT year,ROUND(AVG(total_cust),0) AS avg_mau
FROM 
(SELECT DATE_PART('year', o.order_purchase_timestamp) AS year,
		DATE_PART('month', o.order_purchase_timestamp) AS month,
		COUNT(DISTINCT c.customer_unique_id) AS total_cust
FROM orders O JOIN customers c
ON c.customer_id = o.customer_id
GROUP BY 1,2) a
GROUP BY 1
),

--COUNT NEW CUSTOMERS EACH YEARS
new_cust AS(
SELECT DATE_PART('year', first_order) AS year,
	   COUNT(a.customer_unique_id) AS new_customer
FROM ( SELECT c.customer_unique_id,
	 		  MIN(o.order_purchase_timestamp) AS first_order
	   FROM orders o JOIN customers c
	   ON c.customer_id = o.customer_id
	   GROUP BY 1) a
GROUP BY 1
ORDER BY 1
),

--COUNT CUSTOMERS WHO REPEAT ORDER
repeat_order as(
SELECT year, COUNT(total_customer) AS repeat_order
FROM(SELECT DATE_PART('year', o.order_purchase_timestamp) AS year,
 		    c.customer_unique_id,
 		    COUNT(c.customer_unique_id) AS total_customer,
 		    COUNT(o.order_id) AS total_order
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
GROUP BY 1,2
HAVING COUNT(order_id) >1
) a
GROUP BY 1
ORDER BY 1
),

--AVERAGE ORDER
avg_order AS (
SELECT year, ROUND(AVG(total_order),3) AS avg_frequency_order
FROM(SELECT DATE_PART('year', o.order_purchase_timestamp) AS year,
 		    c.customer_unique_id,
 		    COUNT(DISTINCT order_id) AS total_order
FROM orders o JOIN customers c 
ON o.customer_id = c.customer_id
GROUP BY 1,2
) a
GROUP BY 1
)

-- Group metrics in one display table
SELECT cm.year,
	   cm.avg_mau,
	   nc.new_customer,
	   ro.repeat_order,
	   ao.avg_frequency_order
from count_mau cm 
join new_cust nc on cm.year=nc.year
join repeat_order ro on cm.year=ro.year
join avg_order ao on cm.year=ao.year;