use gdb023;

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct(market)
from dim_customer
where customer = "Atliq Exclusive" AND region = "APAC"
order by 1;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020, unique_products_2021, percentage_chg

WITH table1 as (
select fiscal_year, count(distinct product_code) As unique_products
from fact_sales_monthly
group by fiscal_year)

select t1.unique_products as unique_products_2020,t2.unique_products as unique_products_2021,
ROUND((t2.unique_products - t1.unique_products)/t1.unique_products,2)*100  as percentage_chg
from  table1 t1
cross join table1 t2 
where t1.fiscal_year = "2020" and t2.fiscal_year = "2021";

-- 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 

select segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by count(distinct product_code) desc;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?

WITH CTE as (
select count(distinct s.product_code) as product_count, s.fiscal_year, p.segment
from fact_sales_monthly as s
join dim_product as p ON s.product_code = p.product_code
group by p.segment, s.fiscal_year)

select t1.segment, t1.product_count as product_count_2020, t2.product_count as product_count_2021, 
t2.product_count - t1.product_count as difference
from CTE as t1
cross join CTE as t2
where t2.segment = t1.segment and t2.fiscal_year > t1.fiscal_year;

-- 5.Get the products that have the highest and lowest manufacturing costs.

SELECT 
    c.product_code AS product_code,
    p.product,
    c.manufacturing_cost
FROM
    fact_manufacturing_cost c
        JOIN
    dim_product p ON c.product_code = p.product_code
WHERE
    manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
-- for the fiscal year 2021 and in the Indian market.

SELECT 
    b.customer_code,
    b.customer,
    ROUND(AVG(a.pre_invoice_discount_pct), 2) AS Avg_discount_pct
FROM
    fact_pre_invoice_deductions a
        JOIN
    dim_customer b ON a.customer_code = b.customer_code
WHERE
    a.fiscal_year = 2021
        AND b.market = "India"
GROUP BY b.customer_code , b.customer
ORDER BY 3 DESC
limit 5;


-- 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.


SELECT 
    month, fiscal_year AS Year, SUM(sales) AS gross_sales
FROM
    (SELECT 
        MONTHNAME(a.date) AS Month,
            a.product_code,
            a.fiscal_year,
            ROUND(a.sold_quantity * b.gross_price, 2) AS sales
    FROM
        fact_sales_monthly a
    JOIN fact_gross_price b ON a.product_code = b.product_code
        AND a.fiscal_year = b.fiscal_year
    JOIN dim_customer c ON a.customer_code = c.customer_code
    WHERE
        c.customer = 'Atliq Exclusive') x
GROUP BY MONTH , fiscal_year
ORDER BY year , STR_TO_DATE(CONCAT('0001 ', month, ' 01'),
        '%Y %M %d') ASC;


-- 8.In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity
-- Quarter, total_sold_quantity

SELECT 
   concat("Q", QUARTER(date)) Quarter,
    SUM(sold_quantity) total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY 1
ORDER BY 2 DESC;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

WITH CTE AS (
select c.channel , ROUND(sum(s.sold_quantity * p.gross_price)/1000000,2) as gross_sales_mn
from fact_sales_monthly s 
join dim_customer c on s.customer_code = c.customer_code
join fact_gross_price p on s.product_code = p.product_code
where s.fiscal_year = 2021
group by c.channel)

select channel, gross_sales_mn, ROUND((gross_sales_mn/sum(gross_sales_mn) over()) *100,2) as percentage
from CTE ;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

WITH CTE AS (
select p.division, s.product_code, p.product, sum(s.sold_quantity) as total_sold_quatity
from fact_sales_monthly s
left join dim_product p on s.product_code = p.product_code
where fiscal_year = 2021  
group by p.division, s.product_code, p.product)

select division , product_code , product, total_sold_quatity,rank_order
from(
select division , product_code , product, total_sold_quatity,
RANK() over(partition by division order by total_sold_quatity desc) as rank_order
from CTE
) x
where rank_order <= 3






