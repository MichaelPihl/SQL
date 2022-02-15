-- USING SQLite
-- Data: stores.db from Dataquest.io  
 
-- The purpose of this script is to create a view with all order numbers, their respective customer numbers and the associated total invoiced amounts. In order to do 
-- this we need to join three tables with order numbers, order details and customer details, respectively.

-- skills used: tables, joins, aggregate functions, creating views + checking dataset for double instances of same data, nulls and more


-----------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------- CHECKING CLEANLINESS OF DATA ---------------------------------------------------------

-- checking if there are multiple instances of same ordernumber
SELECT COUNT(*) AS num_ordernumbers
  FROM orders
 GROUP BY orderNumber
 ORDER BY orderNumber DESC;
-- no double instances found!

 -- looking for nulls, orderNumber
 SELECT *
   FROM orders
  WHERE orderNumber IS NULL;
  
-- looking for nulls, orderdate
 SELECT *
   FROM orders
  WHERE orderDate IS NULL;

-- looking for trailing spaces, orderNumber
 SELECT orderNumber, SUBSTRING(ordernumber, LENGTH(orderNumber), LENGTH(ordernumber)) AS last_char
   FROM orders
  WHERE last_char = " ";

-- looking for trailing spaces, orderdate
 SELECT orderDate, SUBSTRING(orderDate, LENGTH(orderDate), LENGTH(orderDate)) AS last_char
   FROM orders
  WHERE last_char = " ";

  
-----------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------- JOINING TABLES  ----------------------------------------------------------------

-- joining the order number list with order details. By doing this, we get an order list with quantity and price of each good included
CREATE TEMP TABLE IF NOT EXISTS expanded_orderlist AS
SELECT o.orderNumber, o.customerNumber, o.orderDate, od.quantityOrdered, od.priceEach 
  FROM orders o
  JOIN orderdetails od
    ON o.orderNumber = od.orderNumber;

-- joining the expanded order list with the customer list to get a "master list" with customer information and order details all included in one list
CREATE TABLE IF NOT EXISTS complete_list AS
SELECT *
  FROM expanded_orderlist n_o
  JOIN customers c
    ON c.customerNumber = n_o.customerNumber
 ORDER BY orderNumber;	
 
-- optional statement to view the whole list 
 SELECT * 
   FROM complete_list;

   
-----------------------------------------------------------------------------------------------------------------------------------
   
--------------------------------------------------- CREATING THE VIEW -------------------------------------------------------------

CREATE VIEW IF NOT EXISTS customer_orders AS
SELECT customerNumber AS customer_number, contactLastName AS last_name, contactFirstName AS first_name, orderNumber AS order_number, orderDate as order_date, SUM(quantityOrdered * priceEach) AS total
  FROM complete_list
 GROUP BY orderNumber;

-- optional statement in order to view the view
 SELECT *
   FROM customer_orders
  LIMIT 5;


-----------------------------------------------------------------------------------------------------------------------------------
  
-------------------------------------- CALCULATING SOME SUMMARY STATISTICS ON THE VIEW --------------------------------------------
------------------------------------------ using common table expressions (CTE) ---------------------------------------------------

-- calculating total amount invoiced
WITH invoiced_total AS (
SELECT SUM(total)
  FROM customer_orders
),  
-- calculating order_average
order_average AS (
   SELECT AVG(total)
     FROM customer_orders
),
-- calculating number of customers during the analyzed period
num_of_customers AS (
SELECT COUNT(*)
  FROM (SELECT COUNT(*)
		 FROM customer_orders
		GROUP BY customer_number)
),
-- number of years analyzed
num_of_years AS (
SELECT COUNT(*)
  FROM (SELECT COUNT(*)
          FROM customer_orders
		 GROUP BY SUBSTRING(order_date, 1, 4))
),
-- average order amount per customer each year
avg_order_per_customer AS (
SELECT SUM(total) / (SELECT * FROM num_of_customers) / (SELECT * FROM num_of_years)
  FROM customer_orders
)

-- combining the calculations above into one table
SELECT  ROUND((SELECT * FROM invoiced_total)) AS invoiced_total,
        ROUND((SELECT * FROM order_average)) AS order_average,
		ROUND((SELECT MIN(total) FROM customer_orders)) AS min_customer_order,
	    ROUND((SELECT MAX(total) FROM customer_orders)) AS max_customer_order,
		(SELECT * FROM num_of_customers) AS num_of_customers,
		ROUND((SELECT * FROM avg_order_per_customer)) AS avg_order_per_customer_per_year;