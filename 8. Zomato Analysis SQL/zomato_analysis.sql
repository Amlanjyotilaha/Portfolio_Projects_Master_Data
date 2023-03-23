-- Creating a Sample Zomato Dataset
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'22-09-2017'),
(3,'21-04-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'02-09-2014'),
(2,'15-01-2015'),
(3,'11-04-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'19-04-2017',2),
(3,'18-12-2019',1),
(2,'20-07-2020',3),
(1,'23-10-2019',2),
(1,'19-03-2018',3),
(3,'20-12-2016',2),
(1,'09-11-2016',1),
(1,'20-05-2016',3),
(2,'24-09-2017',1),
(1,'11-03-2017',2),
(1,'11-03-2016',1),
(3,'10-11-2016',1),
(3,'07-12-2017',2),
(3,'15-12-2016',2),
(2,'08-11-2017',2),
(2,'10-09-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Q1. What is the total amount each customer spent on zomato?
select s.userid , sum(p.price) as totalspend
from sales s
join product p on p.product_id = s.product_id
group by s.userid;


-- Q2. How many days each customer visited zomato?
select userid, count(distinct created_date) 
from sales
group by userid;


-- Q3. What was the first product purchased by each customer?
with user_purchase as
(
	select p.product_name ,p.product_id, s.userid,s.created_date,
	rank() over(partition by s.userid order by s.created_date) as rnk
	from product p 
	join sales s on s.product_id =p.product_id
)
select * from user_purchase
where rnk <=1;

-- Q4. What is the most purchased item on the menu and how many times was it purchased 
-- by all customers?
select userid,count(product_id)as count 
from sales 
where product_id =
(select product_id
from sales 
group by product_id
order by count(*) desc
limit 1)
group by userid;

-- Q5. Which item was most popular for each customer?
with cte as
(
	select userid,product_id ,count(product_id),
	rank () over (partition by userid order by count(product_id) desc) as rnk
	from sales
	group by userid,product_id
	
)
select userid ,product_id 
from cte
where rnk =1;

-- Q6. What items was purchased first by the customer after they became members?
select * from 
(
	select s.userid , s.product_id,gd.gold_signup_date,s.created_date,
	rank() over (partition by s.userid order by s.created_date)as rnk
	from goldusers_signup gd
	join sales s on s.userid = gd.userid
	where s.created_date >= gd.gold_signup_date
	order by userid
) as a
where rnk =1;

-- Q7. Which item was purchased just before the customer became a member?

select * from 
(
	select s.userid , s.product_id,gd.gold_signup_date,s.created_date,
	rank() over (partition by s.userid order by s.created_date desc)as rnk
	from goldusers_signup gd
	join sales s on s.userid = gd.userid
	where s.created_date <= gd.gold_signup_date
	order by userid
) as a
where rnk =1;

-- Q8. What is the total orders and amount spent by each customer before becoming member?
select userid,count(*),sum(price) as total_spent from 
(
	select s.userid , s.product_id,gd.gold_signup_date,s.created_date,
	rank() over (partition by s.userid order by s.created_date desc)as rnk
	from goldusers_signup gd
	join sales s on s.userid = gd.userid
	where s.created_date <= gd.gold_signup_date
	order by userid
) a
join product p on p.product_id = a.product_id
group by userid;


-- Q9. If buying each product generates points and 2 zomato points = 5rs ,and each 
-- product has different purcase points for eg. P1 5rs = 1 zomato points , 
-- for P2 10 rs = 5 zomato points , for P3 5 rs = 1 zomato points .
-- Calculate cashback collected by each customers and for which produt most points 
-- have been given till now ?

-- part 1 : Calculate cashback collected by each customers
select 	b.userid,sum(b.total_points)*2.5 as cashback_earned from
	(select a.*,a.total_spend/points as total_points from 
		(select s.userid,p.product_name,sum(p.price) as total_spend,
		case when p.product_name = 'p1' then 5
		when p.product_name = 'p2' then 2
		when p.product_name = 'p3' then 5
		else 0
		end as points
		from sales s
		join product p on p.product_id = s.product_id
		group by 1,2
		order by 1) as a
	) as b
	group by 1
	order by 1;
	
-- part 2 :for which produt most points have been given till now
select b.product_id, b.product_name ,sum(total_points) as total_points_given from
	(select a.*,a.total_spend/points as total_points from 
		(select s.userid,p.product_name,p.product_id,sum(p.price) as total_spend,
		case when p.product_name = 'p1' then 5
		when p.product_name = 'p2' then 2
		when p.product_name = 'p3' then 5
		else 0
		end as points
		from sales s
		join product p on p.product_id = s.product_id
		group by 1,2,3
		order by 1) as a
	) as b
	group by 1,2
	order by 3 desc
	limit 1;
	
-- Q10: In the first 1 year afte a customer joins a gold program (include their joining date),
-- irrespective of what the customer has purchased,they earn 5 zomato pointsfor every 10 rs 
-- spend. So who earned more , 1 or 3? and what was their points earned in trheir 1st year?
select *,(price/2) as no_of_points from 
	(select * , (gold_signup_date + integer '364') as next_yr_date from	
		(
		select s.*,p.*,gd.*
		from sales s
		join product p on p.product_id = s.product_id
		join goldusers_signup gd on gd.userid = s.userid
		) as a
	) as b 
where created_date between gold_signup_date and next_yr_date
order by no_of_points desc
limit 1;

-- Q11. Rank all the transactions of the customers.
select * , rank() over(partition by userid order by created_date) as transaction_rank
from sales;

-- Q12. Rank all the transactions of each member whenever they are gold member ,for every non gold
-- member transaction mark as na.
select b.*,case when trans = '0' then  'na' else trans end as rank
from
	(select *,
		cast((case when created_date >= gold_signup_date then rank ()over 
		(partition by userid order by created_date desc)
		else 0
	end )as varchar)as trans
	from (
			select s.*,gd.gold_signup_date
			from sales s
			left join goldusers_signup gd
			on s.userid = gd.userid
		)a
	) b;
	
