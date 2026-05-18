# Sales Performance Project


## Introduction
This project analyzes approximately 8,800 sales records, including information on customers, revenue, products, and sales teams.
The objective is to provide a comprehensive overview for high-level stakeholders to better understand overall sales performance and identify key business insights.


## Data Used
This project utilizes a fictional dataset from a public Kaggle data source, consisting of four separate tables.

Website: https://www.kaggle.com/datasets/innocentmfa/crm-sales-opportunities?select=data_dictionary.csv


## Tool Used
* Data Modeler for ER diagram design
* MySQL for data cleaning and exploratory data analysis
* Tableau for data visualization and dashboard development


## Data ER Modeling
![ER Model](<ER model.png>)


## Data Analysis

**Business Question 1: What is the overall win & loss rate across the sales pipeline, and are there significant inactive deals that reduce overall resource efficiency?**

````sql
SELECT
    deal_stage,
    COUNT(opportunity_id) AS num_cases,
    ROUND(COUNT(opportunity_id) * 100.0 / SUM(COUNT(opportunity_id)) OVER(), 2) AS stage_percentage,
    ROUND(AVG(CASE WHEN deal_stage = 'Engaging' THEN DATEDIFF('2017-12-31', engage_date) 
				   WHEN deal_stage IN ('Won', 'Lost') THEN DATEDIFF(close_date, engage_date) 
                   ELSE 'NA' END), 1) AS avg_cycle_days
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY num_cases DESC;
````

**Answer:**

<img src="https://github.com/user-attachments/assets/0396e621-1fe4-45dd-9c2b-f1dbcfdd56c0" width="400" alt="Image">

The overall win rate is 51.8%, and the loss rate is 41.5%, indicating a moderate conversion performance. The average sales cycle duration is approximately 40–50 days. Notably, opportunities in the “Engaging” stage experience a significantly prolonged duration, averaging 198.8 days, suggesting a potential bottleneck in the sales process.

***

**Business Question 2: How does revenue performance vary across geographic markets, and which global regions present the highest potential for future expansion?**

````sql
SELECT 
    a.office_location AS location,
    COUNT(sp.opportunity_id) AS closed_deals_count,
    ROUND(SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100.0 / COUNT(sp.opportunity_id), 1) AS win_rate,
    SUM(sp.close_value) AS total_value
FROM sales_pipeline AS sp
JOIN accounts a USING (account)
WHERE sp.deal_stage IN ('Won', 'Lost')
GROUP BY location
ORDER BY total_value DESC, win_rate DESC;
````

**Answer:**

<img src="https://github.com/user-attachments/assets/1c1c6c74-9c25-47fd-85da-b8a29718ce4a" width="400" alt="Image">

Revenue performance is highly concentrated in the United States. Panama and Germany demonstrate strong expansion potential based on their high win rates and relatively balanced deal volumes.

***

**Business Question 3: How do sales agents perform in terms of revenue, deal volume, and conversion rates?**

````sql
SELECT 
    st.sales_agent,
    COUNT(sp.opportunity_id) AS total_assigned_deals,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS total_revenue_generated,
    ROUND(SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100.0 / SUM(CASE WHEN sp.deal_stage IN ('Won', 'Lost') THEN 1 ELSE 0 END), 1) AS win_rate_pct
FROM sales_pipeline sp
JOIN sales_teams st USING (sales_agent)
GROUP BY st.sales_agent
ORDER BY total_revenue_generated DESC;
````
**Answer:**

<img src="https://github.com/user-attachments/assets/56026600-5709-481e-a77b-d2fa4a4b8442" width="400" alt="Image">


<img src="https://github.com/user-attachments/assets/1dfcfc74-d362-4267-ac63-0b9fd7eb8e46" width="400" alt="Image">


High Revenue: Darcel Schlecht generates the highest revenue (1.15M) with the largest deal volume (747) and moderate win rate.

High Conversion: Maureen Marcano (70.0%), Hayden Neloms (70.4%), and Wilburn Farren (69.6%) achieve the highest win rates
Despite lower deal volumes, they demonstrate strong sales effectiveness.

Low Efficiency: Lajuana Vencill (55.0%) handle a moderate number of deals but exhibit lower conversion rates.

***

**Business Question 4: Which products and product series generate the highest revenue?**

````sql
WITH product_sales AS (
    SELECT 
        s.product as product,
        p.series AS series,
        COUNT(s.opportunity_id) AS won_deals_count,
        SUM(s.close_value) AS total_revenue
    FROM sales_pipeline AS s
    JOIN products AS p USING(product)
    WHERE s.deal_stage = 'Won'
    GROUP BY product
)
SELECT 
    series,
    product,
    won_deals_count,
    total_revenue,
    ROUND((total_revenue) * 100.0 / SUM(total_revenue) OVER (), 1) AS pct_of_total
FROM product_sales
GROUP BY series, product
ORDER BY pct_of_total DESC;
````
**Answer:**

<img src="https://github.com/user-attachments/assets/710bad30-30b3-4c02-b5a6-73fbef1c66de" width="400" alt="Image">

GTX Plus Pro is the leading product, followed by MG Advanced, with these two products contributing nearly 75% of total revenue.


***

**Business Question 5: How does revenue evolve over time, and what trends or seasonal patterns can be observed?**

````sql
WITH Monthly_Revenue AS (
    SELECT 
        DATE_FORMAT(close_date, '%Y-%m') AS y_month,
        SUM(close_value) AS monthly_rev
    FROM sales_pipeline
    WHERE deal_stage = 'Won' AND close_date IS NOT NULL
    GROUP BY y_month
)
SELECT 
    y_month,
    monthly_rev,
    LAG(monthly_rev) OVER (ORDER BY y_month) AS prev_month_rev,
    ROUND((monthly_rev - LAG(monthly_rev) OVER (ORDER BY y_month)) * 100.0 / 
          LAG(monthly_rev) OVER (ORDER BY y_month), 1) AS mom_growth_pct,
    SUM(monthly_rev) OVER (ORDER BY y_month) AS cumulative_rev
FROM Monthly_Revenue
ORDER BY y_month;
````
**Answer:**

<img src="https://github.com/user-attachments/assets/a0bfecfc-6e36-4ef0-a7d2-f552300ce317" width="400" alt="Image">

Revenue exhibits clear regular fluctuations over time, with a recurring pattern of decline at the beginning of each quarter (April, July, and October) followed by recovery in the subsequent months.

***

**Tableau Dashboard**

Designed for executive stakeholders, this dashboard delivers a comprehensive overview of strategic sales performance. It tracks high-level KPIs, including total revenue and win/loss ratios. The sales funnel visualization demonstrates conversion cycle efficiencies and pipeline bottlenecks. Furthermore, the trend line uncovers recurring revenue fluctuations, the pie chart breaks down product series contributions, and the geographic map pinpoints strategic markets with high expansion potential based on regional win rates.


![Strategic Sales Performance Overview](<Strategic Sales Performance Overview.png>)
