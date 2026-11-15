-- Views used by the Streamlit dashboard and the analytical queries.
USE marketing_db;

-- One wide row per customer: joins all five tables
CREATE OR REPLACE VIEW vw_customer_360 AS
SELECT c.customer_id, c.year_birth, c.age, c.age_band, c.education,
       c.marital_status, c.country, c.income, c.income_band, c.kidhome,
       c.teenhome, c.children, c.dt_customer, c.tenure_days, c.recency,
       c.complain,
       s.mnt_wines, s.mnt_fruits, s.mnt_meat_products, s.mnt_fish_products,
       s.mnt_sweet_products, s.mnt_gold_prods, s.total_spend,
       ch.num_deals_purchases, ch.num_web_purchases, ch.num_catalog_purchases,
       ch.num_store_purchases, ch.num_web_visits_month, ch.total_purchases,
       cr.accepted_cmp1, cr.accepted_cmp2, cr.accepted_cmp3, cr.accepted_cmp4,
       cr.accepted_cmp5, cr.response, cr.campaigns_accepted,
       sg.seg_high_income, sg.seg_young_customer, sg.seg_campaign_responder,
       sg.seg_high_web_engagement, sg.seg_family_customer,
       sg.seg_high_spender, sg.seg_underserved
FROM customers c
JOIN spending s            ON s.customer_id  = c.customer_id
JOIN channel_activity ch   ON ch.customer_id = c.customer_id
JOIN campaign_responses cr ON cr.customer_id = c.customer_id
JOIN customer_segments sg  ON sg.customer_id = c.customer_id;

-- KPIs per rule-based segment, plus an "All customers" baseline row
CREATE OR REPLACE VIEW vw_segment_kpis AS
SELECT 'All customers' AS segment, COUNT(*) AS customers,
       ROUND(100 * AVG(response), 2) AS response_rate_pct,
       ROUND(AVG(total_spend), 1) AS avg_spend,
       ROUND(AVG(num_web_visits_month), 2) AS avg_web_visits
FROM vw_customer_360
UNION ALL
SELECT 'High Income', COUNT(*), ROUND(100 * AVG(response), 2),
       ROUND(AVG(total_spend), 1), ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 WHERE seg_high_income = 1
UNION ALL
SELECT 'Young Customer', COUNT(*), ROUND(100 * AVG(response), 2),
       ROUND(AVG(total_spend), 1), ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 WHERE seg_young_customer = 1
UNION ALL
SELECT 'Campaign Responder', COUNT(*), ROUND(100 * AVG(response), 2),
       ROUND(AVG(total_spend), 1), ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 WHERE seg_campaign_responder = 1
UNION ALL
SELECT 'High Web Engagement', COUNT(*), ROUND(100 * AVG(response), 2),
       ROUND(AVG(total_spend), 1), ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 WHERE seg_high_web_engagement = 1
UNION ALL
SELECT 'Family Customer', COUNT(*), ROUND(100 * AVG(response), 2),
       ROUND(AVG(total_spend), 1), ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 WHERE seg_family_customer = 1
UNION ALL
SELECT 'High Spender', COUNT(*), ROUND(100 * AVG(response), 2),
       ROUND(AVG(total_spend), 1), ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 WHERE seg_high_spender = 1
UNION ALL
SELECT 'Under-served', COUNT(*), ROUND(100 * AVG(response), 2),
       ROUND(AVG(total_spend), 1), ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 WHERE seg_underserved = 1;

-- KPIs by demographic dimension (long format, easy to filter in a dashboard)
CREATE OR REPLACE VIEW vw_demographic_kpis AS
SELECT 'Education' AS dimension, education AS category, COUNT(*) AS customers,
       ROUND(100 * AVG(response), 2) AS response_rate_pct,
       ROUND(AVG(total_spend), 1) AS avg_spend,
       ROUND(AVG(num_web_visits_month), 2) AS avg_web_visits
FROM vw_customer_360 GROUP BY education
UNION ALL
SELECT 'Marital_Status', marital_status, COUNT(*),
       ROUND(100 * AVG(response), 2), ROUND(AVG(total_spend), 1),
       ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 GROUP BY marital_status
UNION ALL
SELECT 'Country', country, COUNT(*),
       ROUND(100 * AVG(response), 2), ROUND(AVG(total_spend), 1),
       ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 GROUP BY country
UNION ALL
SELECT 'Age_Band', age_band, COUNT(*),
       ROUND(100 * AVG(response), 2), ROUND(AVG(total_spend), 1),
       ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 GROUP BY age_band
UNION ALL
SELECT 'Income_Band', income_band, COUNT(*),
       ROUND(100 * AVG(response), 2), ROUND(AVG(total_spend), 1),
       ROUND(AVG(num_web_visits_month), 2)
FROM vw_customer_360 GROUP BY income_band;

-- Acceptance rate for each campaign
CREATE OR REPLACE VIEW vw_campaign_kpis AS
SELECT 'Campaign 1' AS campaign, SUM(accepted_cmp1) AS acceptors,
       ROUND(100 * AVG(accepted_cmp1), 2) AS acceptance_rate_pct
FROM campaign_responses
UNION ALL
SELECT 'Campaign 2', SUM(accepted_cmp2), ROUND(100 * AVG(accepted_cmp2), 2)
FROM campaign_responses
UNION ALL
SELECT 'Campaign 3', SUM(accepted_cmp3), ROUND(100 * AVG(accepted_cmp3), 2)
FROM campaign_responses
UNION ALL
SELECT 'Campaign 4', SUM(accepted_cmp4), ROUND(100 * AVG(accepted_cmp4), 2)
FROM campaign_responses
UNION ALL
SELECT 'Campaign 5', SUM(accepted_cmp5), ROUND(100 * AVG(accepted_cmp5), 2)
FROM campaign_responses
UNION ALL
SELECT 'Latest (Response)', SUM(response), ROUND(100 * AVG(response), 2)
FROM campaign_responses;