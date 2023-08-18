select *  from items;
select * from orders;

--Q1) How many distinct items were ordered?
select count(distinct name) from items;

--Q2) How many veg and non-veg items were ordered?
select is_veg,count(name) as items from items
group by is_veg;

--Q3) How many distinct orders were placed?
select count(distinct order_id) from items;

--Q4) How many items contain the word chicken?
select * from items
where name like '%Chicken%';

--Q5) How many Paratha items were ordered?
select * from items
where name like '%Paratha%';

--Q6) Average Items per order?
select 1.0*count(name)/count(distinct order_id) as avg_item_per_order from items;

--Q7) Which items were ordered how many times?
select name, count(*) as count from items
group by name
order by count(*) desc;

--Q8)How many distinct resturents we have ordered from?
select count(distinct restaurant_name) as restaurant_count from orders;

--Q9) Which is the favourite restaurant (most order placed)?
select restaurant_name, count(*) as order_count from orders
group by restaurant_name
order by count(*) desc;

--Q10) Which month has the most order?
select year(order_time) as order_year,month(order_time) as order_month, count(*) as order_number from orders
group by year(order_time),month(order_time)
order by order_number desc;

--Q11) How much revenue earned per year?
select year(order_time) as order_year,month(order_time) as order_month,sum(order_total) as revenue from orders
group by year(order_time),month(order_time)
order by revenue desc;

--Q12) On an average how much does customer spend in an order?
select sum(order_total)/count(distinct order_id) as averege_spent from orders;

--Q13) Yearly spent and last year spent?
with cte as 
(select year(order_time) as order_year, sum(order_total) as spent from orders
group by year(order_time))

select order_year, spent, lag(spent) over (order by order_year) as prev_year_spent from cte; 

--Q14) Rank year baseed on spent?
with cte as 
(select year(order_time) as order_year, sum(order_total) as spent from orders
group by year(order_time))

select order_year, spent, rank() over (order by spent desc) from cte; 

--Q15)What items were ordered together?
select a.name, b.name as name2, concat(a.name,'-',b.name) as food  from items a
join items b
on a.order_id=b.order_id
where a.name!=b.name
and a.name<b.name;