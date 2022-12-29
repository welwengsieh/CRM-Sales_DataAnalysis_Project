-- [View data]
select * from sales_db.sales_data_sample

-- [Check data]
select distinct status from sales_db.sales_data_sample
select distinct year_id from sales_db.sales_data_sample
select distinct productline from sales_db.sales_data_sample
select distinct country from sales_db.sales_data_sample
select distinct dealsize from sales_db.sales_data_sample

-- [Data Analysis]
-- Revenue for each productline 
select productline,
       round(sum(sales), 2) as revenue
from sales_db.sales_data_sample
group by productline       
order by revenue desc
-- ANS : Classic cars have the highest sales

-- Revenue for each year
select year_id,
       round(sum(sales), 2) as revenue
from sales_db.sales_data_sample
group by year_id       
order by revenue desc
-- ANS : 2004 have the highest sales

-- Revenue for each month on specific year
select month_id,
       round(sum(sales), 2) as revenue
from sales_db.sales_data_sample
where year_id = 2003
group by month_id       
order by revenue desc
-- ANS : Highest sales by month for year 2003 & 2004 is November, 
-- 2005 only have 5 months of record so this year have the lowest sales 

-- Productline's revenue for each year's November
select productline,
       round(sum(sales), 2) as revenue
from sales_db.sales_data_sample
where year_id = 2004 and month_id = 11
group by productline       
order by revenue desc
-- ANS : Classic cars have the highest revenue in Nov2003&2004

-- Best customer to purchase, use RFM method
-- RFM : Recency(last order date), Frequency(count of total orders), Monetary(total spend)
SET sql_mode = 'NO_ENGINE_SUBSTITUTION';
drop temporary table rfm_temp;
create temporary table rfm_temp
with rfm as (
    select 
        customername,
        round(sum(sales), 2) as monetary_value,
        round(avg(sales), 2) as avg_monetary_value,
        count(ordernumber) as frequency,
        max(str_to_date(orderdate,'%m/%d/%Y')) as max_date_cust,
        (select max(str_to_date(orderdate,'%m/%d/%Y')) from sales_db.sales_data_sample) as max_date,
        datediff((select max(str_to_date(orderdate,'%m/%d/%Y')) 
    from sales_db.sales_data_sample),max(str_to_date(orderdate,'%m/%d/%Y'))) as recency
    from sales_db.sales_data_sample
    group by customername
),
rfm_calc as (
    select 
        r.*,
        ntile(4) over(order by recency desc) as rfm_recency,
        ntile(4) over(order by frequency) as rfm_frequency,
        ntile(4) over(order by monetary_value) as rfm_monetary
    from rfm as r
),
rfm_tbl as (
    select 
        c.*,
        concat(cast(rfm_recency as char(50)), cast(rfm_frequency as char(50)), cast(rfm_monetary as char(50))) as rfm_cell_string,
        rfm_recency + rfm_frequency + rfm_monetary as rfm_cell
    from rfm_calc as c
)

select  
    customername,
    monetary_value,
    avg_monetary_value,
    frequency,
    date(max_date_cust) as max_date_cust,
    date(max_date) as max_date,
    recency,
    rfm_recency,
    rfm_frequency,
    rfm_monetary,
    rfm_cell_string,
    rfm_cell
from rfm_tbl

-- Temp table created from cte--
select 
    customername , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose'
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active'
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from rfm_temp

-- What product are most often sold together
select 
    ordernumber,
    group_concat(productcode) as productcode
from sales_db.sales_data_sample as p
where ordernumber in
    (select ordernumber
    from (select 
            ordernumber,
            count(*) as rn
        from sales_db.sales_data_sample
        where status = 'shipped'
        group by ordernumber) t1
    where rn = 3)
group by ordernumber    
