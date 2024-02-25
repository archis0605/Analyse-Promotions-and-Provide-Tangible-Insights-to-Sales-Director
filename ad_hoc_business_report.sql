/* 1. Provide a list of products with a base price greater than 500 and that are featured in promo type
 of 'BOGOF' (Buy One Get One Free). This information will help us identify high-value products that are currently 
being heavily discounted, which can be useful for evaluating our pricing and promotion strategies.*/
select f.product_code, p.product_name, f.base_price, f.promo_type
from fact_events f
join dim_products p using(product_code)
where f.promo_type = "BOGOF" and f.base_price > 500;

/*2.Generate a report that provides an overview of the number of stores in each city. 
The results will be sorted in descending order of store counts, allowing us to identify 
the cities with the highest store presence.The report includes two essential fields: 
city and store count, which will assist in optimizing our retail operations.*/
select city, count(store_id) as store_count
from dim_stores
group by 1
order by 2 desc;

/*3. Generate a report that displays each campaign along with the total revenue generated 
before and after the campaign? The report includes three key fields: campaign_name, 
totaI_revenue(before_promotion), totaI_revenue(after_promotion). This report should help 
in evaluating the financial impact of our promotional campaigns. (Display the values in millions)*/
with cte as (
select event_id, store_id, campaign_id, product_code, 
	base_price*quantity_sold_before_promo as total_revenue_before_promo,
	base_price*quantity_sold_after_promo as total_revenue_after_promo
from fact_events)
select campaign_name, round(sum(total_revenue_before_promo)/1000000,2) as t_rev_before_promo_mln,
	round(sum(total_revenue_after_promo)/1000000,2) as t_rev_after_promo_mln
from cte t
inner join dim_campaigns c using(campaign_id)
group by campaign_name;

/*4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for 
each category during the Diwali campaign. Additionally, provide rankings for the 
categories based on their ISU%. The report will include three key fields: 
category, isu%, and rank order. This information will assist in assessing the 
category-wise success and impact of the Diwali campaign on incremental sales.

Note: ISU% (Incremental Sold Quantity Percentage) is calculated as the percentage 
increase/decrease in quantity sold (after promo) compared to quantity sold (before promo)*/
with cte as (
select category,
	round(((sum(quantity_sold_after_promo)/sum(quantity_sold_before_promo))-1)*100,1) as ISU_prct
from fact_events fe
inner join dim_products p using(product_code)
inner join dim_campaigns c using(campaign_id)
where c.campaign_name = "Diwali"
group by 1)
select *, dense_rank() over(order by ISU_prct desc) as rank_order
from cte;

/*5. Create a report featuring the Top 5 products, ranked by Incremental Revenue 
Percentage (IR%), across all campaigns. The report will provide essential 
information including product name, category, and ir%. This analysis helps identify 
the most successful products in terms of incremental revenue across our campaigns, 
assisting in product optimization.*/
with cte as (
select product_name, category, base_price*quantity_sold_before_promo as revenue_before, 
	base_price*quantity_sold_after_promo as revenue_after
from fact_events fe
inner join dim_products p using(product_code))
select product_name, category, 
	round(sum(revenue_after/revenue_before)-1,1) as IR_prct
from cte
group by 1,2
order by 3 desc
limit 5;