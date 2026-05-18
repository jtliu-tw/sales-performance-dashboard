# Business Question 1: What is the overall win & loss rate across the sales pipeline, and are there significant inactive deals that reduce overall resource efficiency?

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




# Business Question 2: How does revenue performance vary across geographic markets, and which global regions present the highest potential for future expansion?

SELECT 
    a.office_location AS location,
    COUNT(sp.opportunity_id) AS closed_deals_count,
    ROUND(SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100.0 / COUNT(sp.opportunity_id), 1) AS win_rate,
    SUM(sp.close_value) AS total_value
FROM sales_pipeline AS sp
JOIN accounts a USING (account)
WHERE sp.deal_stage IN ('Won', 'Lost')
GROUP BY location
ORDER BY total_value DESC;




# Business Question 3: How do sales agents perform in terms of revenue, deal volume, and conversion rates?

SELECT 
    st.sales_agent,
    COUNT(sp.opportunity_id) AS total_assigned_deals,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS total_revenue_generated,
    ROUND(SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100.0 / SUM(CASE WHEN sp.deal_stage IN ('Won', 'Lost') THEN 1 ELSE 0 END), 1) AS win_rate_pct
FROM sales_pipeline sp
JOIN sales_teams st USING (sales_agent)
GROUP BY st.sales_agent
ORDER BY total_revenue_generated DESC;




# 	Business Question 4: Which products and product series generate the highest revenue?

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




# 	Business Question 5: How does revenue evolve over time, and what trends or seasonal patterns can be observed?

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