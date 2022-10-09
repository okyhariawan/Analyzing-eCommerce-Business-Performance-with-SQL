-- REVENUE PER YEAR
CREATE TABLE revenue_by_year AS
	SELECT  
		DATE_PART('year', o.order_purchase_timestamp) AS year_transaction,
		SUM(revenue_per_order) AS revenue
	FROM (
		SELECT 
			order_id, 
			SUM(price+freight_value) AS revenue_per_order
		FROM order_items
		GROUP BY 1
		) subq
	JOIN orders o ON subq.order_id = o.order_id
	WHERE o.order_status = 'delivered'
	GROUP BY 1
	ORDER BY 1;

-- COUNT CANCEL ORDER
CREATE TABLE canceled_order_by_year AS 
	SELECT 
		DATE_PART('year', order_purchase_timestamp) AS year_transaction,
		COUNT(order_id) AS total_canceled_order
	FROM orders
	WHERE order_status = 'canceled'
	GROUP BY 1
	ORDER BY 1;

--CATEGORY WITH HIGHEST REVENUE
CREATE TABLE top_category_revenue_by_year AS
	SELECT 
		year_transaction,
		product_category_name,
		revenue
	FROM (
		SELECT 
			year_transaction,
			product_category_name,
			SUM(price+freight_value) AS revenue,
			RANK () OVER(
				PARTITION BY year_transaction
				ORDER BY SUM(price+freight_value) DESC
			) AS rank_revenue
		FROM order_items AS oid
		JOIN (
			SELECT 
				order_id,
				DATE_PART('year', order_purchase_timestamp) AS year_transaction
			FROM orders
			WHERE order_status = 'delivered'
			) AS orders
		ON oid.order_id = orders.order_id
		JOIN product AS p
		ON oid.product_id = p.product_id
		GROUP BY 1,2
	) AS revenue_category
	WHERE rank_revenue = 1;


-- CATEGORY WITH HIGHEST CANCEL
CREATE TABLE top_category_canceled_order_by_year AS
	SELECT 
		year_transaction,
		product_category_name,
		canceled_order
	FROM (
		SELECT 
			year_transaction,
			product_category_name,
			COUNT(oid.order_id) AS canceled_order,
			RANK () OVER(
				PARTITION BY year_transaction
				ORDER BY COUNT(oid.order_id) DESC
			) AS rank_cancel
		FROM order_items AS oid
		JOIN (
			SELECT 
				order_id,
				DATE_PART('year', order_purchase_timestamp) AS year_transaction
			FROM orders
			WHERE order_status ='canceled'
			) AS orders
		ON oid.order_id = orders.order_id
		JOIN product AS p
		ON oid.product_id = p.product_id
		GROUP BY 1,2
	) AS canceled
	WHERE rank_cancel = 1;


--JOIN ALL TABLE
SELECT
	rby.year_transaction AS year_transaction,
	rby.revenue AS total_revenue,
	tcrby.product_category_name AS highest_revenue_category,
	tcrby.revenue AS highest_revenue_by_category,
	coby.total_canceled_order AS total_canceled_order,
	tccoby.product_category_name AS highest_canceled_order_category,
	tccoby.canceled_order AS highest_canceled_order
FROM revenue_by_year AS rby
JOIN canceled_order_by_year AS coby ON rby.year_transaction = coby.year_transaction
JOIN top_category_revenue_by_year AS tcrby ON coby.year_transaction = tcrby.year_transaction
JOIN top_category_canceled_order_by_year AS tccoby ON tcrby.year_transaction = tccoby.year_transaction;