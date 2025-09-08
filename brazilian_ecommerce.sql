create database ecommerce;
use ecommerce;
select * from [dbo].[brazilian_ecommerce_cleaned];

--1.question--
--Who are the top 10 customers by total spending?--

select top 10 customer_unique_id,round(sum(price),2) as spend from [dbo].[brazilian_ecommerce_cleaned]
group by customer_unique_id 
order by spend desc;

select  customer_unique_id,spend,r_num 
from(
	select 
        customer_unique_id,
        round(sum(price),2) AS spend,
	    ROW_NUMBER() over(order by sum(price) desc) as r_num
	from [dbo].[brazilian_ecommerce_cleaned]
	group by customer_unique_id
)  AS x
where x.r_num <= 10;

--2.Find customers who purchased more than the average number of orders.

with customer_avg_orders as(
	select 
		 customer_unique_id,
		 count(order_id) as total_orders from [dbo].[brazilian_ecommerce_cleaned]
	group by customer_unique_id
	)
select 
	customer_unique_id,
	total_orders
from customer_avg_orders
where total_orders>(select avg(total_orders) from customer_avg_orders)
order by total_orders desc;


--3.List customers who have never purchased again after their first order.
with first_order as(
select 
	customer_unique_id,
	order_id,
	order_purchase_timestamp ,
	row_number() over(partition by customer_unique_id order by  order_purchase_timestamp) as order_rank,
	count(*) over( partition by customer_unique_id) as total_orders
from [dbo].[brazilian_ecommerce_cleaned]
)
select 
	customer_unique_id,
	order_id As first_order_id,
	order_purchase_timestamp as first_order_date
from first_order
where total_orders=1 AND order_rank=1

--4.What is the monthly sales trend (revenue and number of orders)?

select
	month(order_purchase_timestamp) as months ,
	sum(price+freight_value) as total_revenue ,
	count(distinct order_id) as total_orders
	from [dbo].[brazilian_ecommerce_cleaned]
	where order_status='delivered'
group by month(order_purchase_timestamp)
order by months ;

--5.Compare sales between weekdays vs weekends.

select
	Case
		when datepart(weekday,order_purchase_timestamp) IN (1,7) then 'weekends' else 'weekday' 
	end as day_type,
	count(distinct order_id) as total_orders,
	sum(price+freight_value) as total_revenue
from[dbo].[brazilian_ecommerce_cleaned]
where order_status =' delivered'
group by Case when datepart(weekday,order_purchase_timestamp) IN (1,7) then 'weekends' else 'weekday' end;

--6.Find the month with the highest revenue and the month with the lowest revenue


select months,total_revenue,rnk_high,rnk_low from(
				select 
					month(order_purchase_timestamp) as months,
					sum(price+freight_value) as total_revenue,
					rank() over(order by sum(price+freight_value) desc) as rnk_high,
					rank() over(order by sum(price+freight_value) ) as rnk_low
				from[dbo].[brazilian_ecommerce_cleaned]
				where order_status='delivered'
				group by month(order_purchase_timestamp)) as t
				where t.rnk_high=1 or t.rnk_low=1;
--7.Which are the top 5 best-selling product categories?

select top 5
customer_unique_id,
count(product_id) as units_sold ,
sum(price) as revenue  
from[dbo].[brazilian_ecommerce_cleaned]
group by customer_unique_id
order by units_sold

---8.Find products that were bought only once across all customers.
SELECT
  product_id,
  COUNT(DISTINCT order_id) AS times_purchased
FROM [dbo].[brazilian_ecommerce_cleaned]
group by product_id
having count(distinct order_id) =1;

--9.Which products contribute the most revenue (Pareto / 80-20 analysis)?
WITH product_revenue AS (
  SELECT
    product_id,
    SUM(price + freight_value) AS revenue
  FROM [dbo].[brazilian_ecommerce_cleaned]
  GROUP BY product_id
),
ranked AS (
  SELECT
    product_id,
    revenue,
    SUM(revenue) OVER (ORDER BY revenue DESC
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
      / SUM(revenue) OVER () AS cumulative_revenue_pct
  FROM product_revenue
)
SELECT *
FROM ranked
ORDER BY revenue DESC;

--10.What is the average delivery time, and which sellers deliver the fastest?
SELECT
  seller_id,
  AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days,
  COUNT(DISTINCT order_id) AS delivered_orders
FROM [dbo].[brazilian_ecommerce_cleaned]
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY seller_id
ORDER BY avg_delivery_days ASC;




---END OF THE PROJECT----	

	