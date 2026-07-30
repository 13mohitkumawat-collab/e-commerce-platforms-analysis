select * from Sales
-- 1. total orders by platforms
select count(order_id),platform
from Sales
group by platform

-- 2. Which platform generates the highest revenue?
select sum(order_value) as revenue,platform
from Sales
group by platform
order by revenue desc
limit 1

-- 3. What is the average delivery time and average service rating for each platform?
select avg(delivery_time) as avg_delivery_time,avg(service_rating) as avg_service_rating,platform
from Sales
group by platform

-- 4. Which product category contributes the highest total revenue?
select sum(order_value) as total_revenue,product_category 
from Sales
group by product_category
order by total_revenue desc

-- 5. What is the refund rate for each platform?
select round((sum(case when Refund_Requested=true then 1 else 0 end)*100.0/count(refund_requested))::numeric,2) as refund_rate,platform
from Sales
group by platform

-- 6. Which product categories have the highest refund requests?
select sum(case when Refund_Requested=true then 1 else 0 end) as count_ref_request,Product_Category
from Sales
group by Product_Category

-- 7. Find the Top 5 customers based on total order value
select sum(order_value) as total_order_value,customer_id
from Sales
group by customer_id
order by total_order_value desc
limit 5

-- 8. Rank platforms based on total revenue.
select platform ,sum(order_value) as total_revenue,dense_rank() over (order by sum(order_value) desc) as rank
from Sales
group by platform

-- 9. Compare delayed vs. non-delayed orders in terms of:
--   .Average order value
--   .Average service rating
--   .Refund percentage
select avg(order_value) as avg_order_value ,avg(service_rating) , round((sum(case when Refund_Requested=true then 1 else 0 end)*100.0/count(refund_requested))::numeric,2) as refund_rate, del_status from(
    select Delivery_Delay,(case when Delivery_Delay=true then 'delayed' else 'non_delayed'end) as del_status,order_value,service_rating, Refund_Requested
    from Sales)
group by del_status	

-- 10. What is the average delivery time and average service rating for each platform?
select avg(delivery_time) as avg_del_time,avg(service_rating) as avg_service_reating
from Sales
group by platform

-- 11. Find the percentage contribution of each platform to total revenue.
select platform, round(sum(order_value)*100.0/(select sum(order_value) from Sales)::numeric,2) as percentage_contribution
from Sales
group by platform

-- 12. Find customers who ordered above the average order value.
select customer_id,order_value
from Sales
where order_value > (select avg(order_value) from Sales)

-- 13. Identify orders where:
--     Delivery Time > Average Delivery Time
--     Rating < Average Rating
select * from Sales
where delivery_time > (select avg(delivery_time) from Sales) and
service_rating < (select avg(service_rating) from Sales)

-- 14. Rank product categories based on average service rating.
select product_category ,avg(service_rating) as avg_service_rating ,dense_rank() over (order by avg(service_rating) desc) as rank
from Sales
group by product_category

-- 15.Calculate refund percentage for each platform using CTEs.
with platform_orders as (
    select
        platform,
        count(*) as total_orders,
        sum(case when refund_requested = true then 1 else 0 end) as refunded_orders
    from sales
    group by platform
)
select
    platform,
    total_orders,
    refunded_orders,
    round((refunded_orders * 100.0) / total_orders, 2) as refund_percentage
from platform_orders
order by refund_percentage desc;

-- 16. Which platform has the highest refund risk after controlling for delivery delays and customer ratings?
--     Management wants to know whether refunds are caused only by delivery delays or if platform quality itself is a factor.
with platforms as (select platform ,sum(order_value) as total ,avg(service_rating) as avg_rating ,round((sum(case when Refund_Requested=true then 1 else 0 end)*100.0/count(refund_requested))::numeric,2) as refund_rate ,sum(case when Delivery_Delay=true then 1 else 0 end) as delayed ,count(*) as total_count
from Sales
group by platform)
select platform , total ,avg_rating ,refund_rate ,round((delayed*100.0/total_count)::numeric,2) as delayed_rate
from platforms
order by refund_rate desc