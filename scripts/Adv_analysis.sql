
--#1 Sales Perforamnce over time
select YEAR(order_date) as year,
SUM(sales_amount) as total_sales,
COUNT(distinct customer_key) as total_customer,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by year(order_date) 
order by year(order_date) desc


select
YEAR(order_date) as year,
Month(order_date) as month,
SUM(sales_amount) as total_sales,
COUNT(distinct customer_key) as total_customer,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by year(order_date),Month(order_date)
order by year(order_date),Month(order_date) desc



select 
format(order_date,'yyyy MMM') as date,
SUM(sales_amount) as total_sales,
COUNT(distinct customer_key) as total_customer,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by format(order_date,'yyyy MMM')
order by format(order_date,'yyyy MMM') desc

------------------------------------------------------------------------
--#2 Cumulative Analysis 
-- Running total sales by year and moving avg of sales by year 


select 
order_date,
total_sales,
SUM(total_sales) over (partition by order_date order by order_date) as running_total_sales
from(
select 
DATETRUNC(month,order_date) as order_date ,
SUM(sales_amount) as total_sales 
from gold.fact_sales
where order_date is not null
group by DATETRUNC(month,order_date)
) t


select 
order_date,
total_sales,
SUM(total_sales) over ( order by order_date) as running_total_sales,
AVG(total_sales) over ( order by order_date) as moving_avg_sales
from(
select 
DATETRUNC(year,order_date) as order_date ,
SUM(sales_amount) as total_sales 
from gold.fact_sales
where order_date is not null
group by DATETRUNC(year,order_date)
) t


-----------------------------------------------------------------------
/* Analyze the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year's sales */

with yearly_product_sales as(
select 
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from gold.fact_sales f 
left join gold.dim_products p
on f.product_key = p.product_key
where order_date is not null
group by year(f.order_date), p.product_name 
)

select 
order_year,
product_name,
current_sales,
AVG(current_sales) over(partition by product_name) as avg_sales,
current_sales - AVG(current_sales) over(partition by product_name) as diff_avg,

case 
	when current_sales - AVG(current_sales) over(partition by product_name) > 0 then 'above avg'
	when current_sales - AVG(current_sales) over(partition by product_name) < 0 then 'below avg'
	else 'avg'
end as avg_change,

lag(current_sales) over(partition by product_name order by order_year) as prv_year_sales,

case 
	when current_sales - lag(current_sales) over(partition by product_name order by order_year) > 0 then 'Increase'
	when current_sales - lag(current_sales) over(partition by product_name order by order_year) < 0 then 'Decrease'
	else 'No Change'
end as diff_pv

from yearly_product_sales
order by product_name, order_year

---------------------------------------------------------------------
--# Part of Whole - propration 
With category_sales as(
select 
category,
SUM(sales_amount) as total_sales 
from gold.fact_sales f 
left join gold.dim_products p 
on p.product_key = f.product_key
group by category
)

select category, total_sales,
sum(total_sales) over() as overall_sales,
Concat(Round( (CAST(total_sales AS float) / sum(total_sales) over())*100,2),'%')  as percentage_of_total
from category_sales 
order by total_sales desc


--------------------------------------------------------------------------------------
-- # Data Segmentation 
/* segment products into cost ranges and
count how many products fall into each segment*/

	with product_segment as(
	select 
	product_key,
	product_name,
	cost,
	case
		when cost <100 then 'below 100'
		when cost between 100 and 500 then '100-500'
		when cost between 500 and 1000 then '500-1000'
		else 'above 1000'
	end as cost_range

	from gold.dim_products)

	select 
	cost_range,
	COUNT(product_key) as total_product 
	from product_segment 
	group by cost_range


-------------------------------------------------------------------------
/* Group customers into three segments based on their spending behavior:
- VIP: Customers with at least 12 months of history and spending more than €5,000.
- Regular: Customers with at least 12 months of history but spending €5,000 or less.
- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group */

with customer_spending as(
select 
c.customer_key,
sum(sales_amount) as total_spending,
min(order_date) as first_order,
max(order_date) as last_order,
DATEDIFF(month,min(order_date),max(order_date)) as lifespan
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
group by c.customer_key
)



select 
customer_segment,
count(customer_key) as total_customers

from (
	select 
	customer_key,
	case 
		when total_spending > 5000 and lifespan >= 12 then 'VIP'
		when total_spending <= 5000 and lifespan >= 12 then 'Regular'
		else 'New'
	end customer_segment
	from customer_spending 
	) t
group by customer_segment 

