
-- #1  (Database Exploration)

select * from INFORMATION_SCHEMA.TABLES
select * from INFORMATION_SCHEMA.COLUMNS




-- #2 (Dimension Exploration) 

select distinct country from gold.dim_customers
select distinct product_name from gold.dim_products
select distinct category from gold.dim_products
select distinct subcategory from gold.dim_products





--#3 (Date Exploration) 

-- How many years sales are available ? 
select min(order_date) as oldest_order_date,
max(order_date) as latest_order_date,
DATEDIFF(MONTH,min(order_date),max(order_date)) as duration
from gold.fact_sales


-- Find the youngest and the oldest customer
select 
min(birthdate) as oldest_birthdate,
DATEDIFF(year,min(birthdate),getdate() ) as oldest_age,
max(birthdate) as youngest_birthdate,
DATEDIFF(year,max(birthdate),getdate() ) as youngest_age

from gold.dim_customers


-- find average cusotmer age
select avg(age) as average_ages
from(
	select
	DATEDIFF(year,birthdate,GETDATE())as age 
	from gold.dim_customers
	) t





-- #4 (Measure Exploration) 

-- What it is the total sales/total revenue ?
select sum(sales_amount) as total_sales from gold.fact_sales

-- What it is the Total Product ?
select count(distinct product_key) as total_product  from gold.dim_products

-- What it is the total product that actually have sales?
select count(distinct product_key) as product_saled from gold.fact_sales

-- What it is the total orders ?
select count(distinct order_number) as total_orders from gold.fact_sales

-- How many items sold?
select sum(quantity) as total_quantity from gold.fact_sales

-- How many subcategory category?
select count(distinct subcategory) as total_subcatgory from gold.dim_products

-- find the total number of customers
select count(customer_key) from gold.dim_customers

-- find average price 
select avg(price) as average_price from gold.fact_sales


select 'Total sales' as measure_name, sum(sales_amount) as measure_value from gold.fact_sales
union all
select 'Total product', count(product_key) from gold.dim_products
union all
select 'Total product saled', count(distinct product_key)  from gold.fact_sales
union all
select 'Total orders', count(distinct order_number) from gold.fact_sales
union all
select 'Total quantity', sum(quantity) from gold.fact_sales
union all
select 'Total customer', count(customer_key) from gold.dim_customers
union all
select 'Average price', avg(price) from gold.fact_sales




