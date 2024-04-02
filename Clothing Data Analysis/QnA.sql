-- 1.How many transactions were completed during each marketing campaign? -- 
select t.product_id,campaign_name,count(t.transaction_id)
from transactions t 
join marketing_campaigns mc on t.product_id = mc.product_id
group by t.product_id,campaign_name;

-- 2.Which product had the highest sales quantity? --
with cte as
(	select sc.product_id,product_name,price,sum(t.quantity) as Total_quantity 
	from transactions t
	join sustainable_clothing sc on t.product_id = sc.product_id
	group by sc.product_id,product_name,price
)
select * from cte where Total_quantity in (select max(Total_quantity) from cte);

-- 3.What is the total revenue generated from each marketing campaign? --
with cte as
(
	select mc.campaign_name,sum(price) as Total_Price
    from transactions t
	join sustainable_clothing sc on t.product_id = sc.product_id
    join marketing_campaigns mc on sc.product_id = mc.product_id
    group by mc.campaign_name
)
select * from cte where Total_Price in (select max(Total_Price) from cte);

-- 4.What is the top-selling product category based on the total revenue generated? --
with cte as
(
	select category,sum(price) as Total_Price
    from transactions t
	join sustainable_clothing sc on t.product_id = sc.product_id
    join marketing_campaigns mc on sc.product_id = mc.product_id
    group by category
)
, cte_2 as
(
	select c.*,
	rank() over (order by Total_Price desc) 
	as 
	Rank_No 
	from 
	cte c
)
select c.* from cte_2 as c where Rank_No = 1;

-- 5.Which products had a higher quantity sold compared to the average quantity sold? --
with cte as
(
	select t.product_id, product_name,quantity
    from transactions t
	join sustainable_clothing sc on t.product_id = sc.product_id
    group by t.product_id,product_name,quantity
)
select c.* from cte c
where quantity > ( select avg(quantity) from transactions);

-- 6. What is the average revenue generated per day during the marketing campaigns? --
-- v1 --
select purchase_date,campaign_name, avg(quantity*price) as Avg_Sales
from transactions t
join sustainable_clothing s on t.product_id = s.product_id
join marketing_campaigns c on s.product_id = c.product_id
group by purchase_date,campaign_name;
--
-- v2 --
with cte as
(
	select
		purchase_date,
        campaign_name, 
        quantity*price as Daily_Sales
    from transactions t
	join sustainable_clothing s on t.product_id = s.product_id
	join marketing_campaigns c on s.product_id = c.product_id
)
select 
	purchase_date,
	campaign_name,
avg(Daily_Sales) as Avg_Daily_Sales  from cte 
group by purchase_date, campaign_name;
-- Complete --

-- v3 --
with cte as
(
	select 
		t.purchase_date,
        campaign_name,
        quantity*price as Daily_Sales
	from 
    transactions t
    join sustainable_clothing s on t.product_id = s.product_id
    join marketing_campaigns mc on s.product_id = mc.product_id
)
select 
	purchase_date,
    campaign_name,
    avg(Daily_Sales) as Avg_Sales
from cte
group by 
	purchase_date,
    campaign_name;
-- Complete --

-- Creating a view from same -- 
drop view if exists CampaignSalesView;
CREATE VIEW CampaignSalesView AS
WITH CampaignSales AS (
  SELECT
    t.purchase_date,
    c.campaign_name,
    t.quantity * s.price AS daily_sales,
	ROW_NUMBER() OVER (ORDER BY t.purchase_date, c.campaign_name) AS row_num
  FROM
    transactions t
  JOIN
    sustainable_clothing s ON t.product_id = s.product_id
  JOIN
    marketing_campaigns c ON t.product_id = c.product_id
)
SELECT
	row_num as Sr_No,
	purchase_date as Purchase_Date,
	campaign_name as Campaign_Name,
	daily_sales as Daily_Sales
FROM
  CampaignSales
group by
	purchase_date ,campaign_name,daily_sales,row_num;
    
SELECT * FROM CampaignSalesView;
  
-- 7.What is the percentage contribution of each product to the total revenue? -- 
with cte as 
(
	select 
	sc.product_id as Product_Id,
    product_name as Product_Name,
    sum(price * quantity) as Product_Sales
from sustainable_clothing sc
join 
	transactions t on sc.product_id = t.product_id
group by product_id,product_name
),
cte2 as
(
	select sum(price * quantity) as Total_Sales
    from transactions t
    join 
		sustainable_clothing sc on t.product_id = sc.product_id
)
select 
	product_id as Product_Id,
    product_name as Product_Name,
    concat((Product_Sales*100)/Total_Sales,"%") as Contribution
from cte,cte2;

-- 8.Compare the average quantity sold during marketing campaigns to outside the marketing campaigns. --
with AQSDMC as
(
	select
        avg(quantity) as Sold_During_Campaigns
	from 
    transactions t
    join sustainable_clothing s on t.product_id = s.product_id
    join marketing_campaigns mc on t.purchase_date between mc.start_date and mc.end_date and  t.product_id = mc.product_id
),
AQSOMC as
(
	select
        avg(t.quantity) as Total_Sales
	from 
    transactions t
    join sustainable_clothing s on t.product_id = s.product_id
)

select 
	Sold_During_Campaigns,
    Total_Sales,
    (Total_Sales - Sold_During_Campaigns) as Sold_Outside_Campaigns
from AQSOMC,AQSDMC;

-- 9.Compare the revenue generated by products inside the marketing --
with AQSDMC as
(
	select
        sum(quantity * price) as Sold_During_Campaigns
	from 
    transactions t
    join sustainable_clothing s on t.product_id = s.product_id
    join marketing_campaigns mc on t.purchase_date between mc.start_date and mc.end_date and  t.product_id = mc.product_id
),
AQSOMC as
(
	select
        sum(quantity * price) as Total_Sales
	from 
    transactions t
    join sustainable_clothing s on t.product_id = s.product_id
)

select 
	Sold_During_Campaigns,
    Total_Sales,
    (Total_Sales - Sold_During_Campaigns) as Sold_Outside_Campaigns
from AQSOMC,AQSDMC;

-- 10.Rank the products by their average daily quantity sold. --
with cte as 
(
	select 
    product_name as Product_Name,
    sum(quantity) as Number_of_Product_Sold
from sustainable_clothing sc
join 
	transactions t on sc.product_id = t.product_id
group by product_name
) 
select 
    product_name as Product_Name,
    Number_of_Product_Sold,
    dense_rank () over (order by Number_of_Product_Sold desc) as Ranking
from cte;


with cte as 
(select s.product_name,sum(quantity) as Avg_sold_qty
from transactions t
join sustainable_clothing s on t.product_id = s.product_id group by 1)
select product_name,Avg_sold_qty,
dense_rank() over (order by Avg_sold_qty desc) as Rank_avg from cte;

select product_id,COUNT(*) from transactions
GROUP BY product_id
HAVING COUNT(*) > 1 