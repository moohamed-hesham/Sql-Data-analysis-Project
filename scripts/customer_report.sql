
/*
==================================================================================================================
Customer Report
==================================================================================================================
Purpose
	- This report consolidates key customer metrics and behaviors 

Highlights :
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend

*/


-- base query (CTE) : retreive all core columns from tables

create view gold.customer_report as
With base_query as(
SELECT 
order_number,
product_key,
f.customer_key,
order_date,
sales_amount,
quantity,
customer_number,
CONCAT(first_name, ' ', last_name) as customer_name,
DATEDIFF(year,birthdate,GETDATE()) as age

FROM gold.fact_sales f 
LEFT JOIN gold.dim_customers c 
on f.customer_key = c.customer_key 
)


-- customer_aggregation (CTE) : summarize key metrics at the customer level

,customer_Agg AS(

select
customer_key,
customer_number,
customer_name,
age,
count(order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
DATEDIFF(month,min(order_date), max(order_date) ) as lifespan
from base_query
group by 
customer_key,
customer_number,
customer_name,
age
)


select
customer_key,
customer_number,
customer_name,
CASE 
	WHEN age <20 Then 'Under 20'
	WHEN age between 20 and 29 Then '20-29'
	WHEN age between 30 and 39 Then '30-39'
	WHEN age between 40 and 49 Then '40-49'
	ELSE 'above 50'
End AS age_group,
	case 
		when total_sales > 5000 and lifespan >= 12 then 'VIP'
		when total_sales <= 5000 and lifespan >= 12 then 'Regular'
		else 'New'
	end customer_segment,
total_orders,
total_sales,
total_quantity,
total_products,
--  recency (months since last order)
DATEDIFF(month, last_order_date, getdate() ) as recency,
lifespan,
-- compute average order value
Case 
	When total_orders = 0 Then 0
	Else total_sales / total_orders 
End as avg_order_value,

-- 	average monthly spend
Case 
	When lifespan = 0 Then total_sales
	Else total_sales / lifespan 
End as avg_monthly_spend
from customer_Agg

------------------------------------------------------------------------
-- select from view
select * from gold.customer_report
-----------------------------------------------------------------















