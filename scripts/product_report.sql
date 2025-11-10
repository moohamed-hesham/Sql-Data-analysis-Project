/*
Product Report
Purpose :
	- This report consolidates key product metrics and behaviors.
Highlights :
	1. Gathers essential fields such as product name, category, subcategory, and cost.
	2. Segments products by revenue to identify High-Performers,
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)

	4.Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
		Mid-Range, or Low-Performers .
*/

Create View gold.product_report AS 
-- base query (CTE) : retreive all core columns from tables
with base_query AS(
select 
order_number,
order_date,
customer_key,
sales_amount,
quantity,
p.product_key,
product_name,
category,
subcategory,
cost

from gold.fact_sales f
left join gold.dim_products p
on f.product_key = p.product_key
where order_date is not null
)
-- product_aggregation (CTE) : summarize key metrics at the product level
,Product_agg as(
select 
product_name,
category,
subcategory,
cost,
COUNT(distinct order_number) as total_orders,
max(order_date) as last_sales_date,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity ) as total_quantity,
datediff(month,min(order_date), max(order_date) ) as lifespan

from base_query
group by 
product_name,
category,
subcategory,
cost
)

select 
product_name,
category,
subcategory,
cost,
last_sales_date,
DATEDIFF(month,last_sales_date,getdate()) as recency,
Case 
	when total_sales > 50000 then 'High-performance'
	when total_sales >= 10000 then 'Mid-range'
	Else 'low-performance'
End as product_segment,

total_orders,
total_sales,
total_customers,
total_quantity,
lifespan,

-- average order revenue (AOR)
Case 
	when total_orders =0 then 0
	else total_sales / total_orders
end as avg_order_revenue,

-- average monthly revenue
Case 
	when lifespan=0 then total_sales
	else total_sales / lifespan 
end as avg_monthly_revenue

from Product_agg


------------------------------------------------------------------------
-- select from view
select * from gold.product_report
-----------------------------------------------------------------


