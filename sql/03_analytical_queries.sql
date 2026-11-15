USE marketing_db;

-- Q1: Headline KPIs
SELECT COUNT(*) AS customers,
       ROUND(100 * AVG(response), 2) AS response_rate_pct,
       ROUND(AVG(total_spend), 1) AS avg_spend,
       ROUND(AVG(num_web_visits_month), 2) AS avg_web_visits
FROM vw_customer_360;

-- Q2: Countries ranked by response rate, with the gap to the all-country average
SELECT category AS country, customers, response_rate_pct,
       RANK() OVER (ORDER BY response_rate_pct DESC) AS response_rank,
       ROUND(response_rate_pct - AVG(response_rate_pct) OVER (), 2) AS gap_vs_avg
FROM vw_demographic_kpis
WHERE dimension = 'Country'
ORDER BY response_rank;

-- Q3: Spend deciles. Decile 1 is the top 10 percent of spenders.
-- Shows how much revenue and response each decile carries.
WITH ranked AS (
    SELECT customer_id, total_spend, response,
           NTILE(10) OVER (ORDER BY total_spend DESC) AS spend_decile
    FROM vw_customer_360
)
SELECT spend_decile,
       COUNT(*) AS customers,
       MIN(total_spend) AS min_spend,
       MAX(total_spend) AS max_spend,
       ROUND(100 * AVG(response), 1) AS response_rate_pct,
       ROUND(100 * SUM(total_spend) / SUM(SUM(total_spend)) OVER (), 1) AS share_of_total_spend
FROM ranked
GROUP BY spend_decile
ORDER BY spend_decile;

-- Q4: CASE-based income tier by family type
SELECT CASE WHEN income > 75000 THEN '1-High (>75k)'
            WHEN income >= 40000 THEN '2-Medium (40-75k)'
            ELSE '3-Low (<40k)' END AS income_tier,
       CASE WHEN children > 0 THEN 'Family' ELSE 'No children' END AS family_type,
       COUNT(*) AS customers,
       ROUND(100 * AVG(response), 1) AS response_rate_pct,
       ROUND(AVG(total_spend), 1) AS avg_spend
FROM vw_customer_360
GROUP BY income_tier, family_type
ORDER BY income_tier, family_type;

-- Q5: Channel usage, high spenders versus everyone else
SELECT CASE WHEN seg_high_spender = 1 THEN 'High spender' ELSE 'Other' END AS customer_group,
       ROUND(AVG(num_web_purchases), 2) AS web,
       ROUND(AVG(num_store_purchases), 2) AS store,
       ROUND(AVG(num_catalog_purchases), 2) AS catalog,
       ROUND(AVG(num_deals_purchases), 2) AS deals,
       ROUND(AVG(num_web_visits_month), 2) AS web_visits
FROM vw_customer_360
GROUP BY customer_group;

-- Q6: Under-served customers (low spend, high visits, no response) by country
SELECT country,
       COUNT(*) AS customers,
       SUM(seg_underserved) AS underserved,
       ROUND(100 * SUM(seg_underserved) / COUNT(*), 1) AS underserved_pct,
       RANK() OVER (ORDER BY SUM(seg_underserved) / COUNT(*) DESC) AS rank_by_share
FROM vw_customer_360
GROUP BY country
ORDER BY rank_by_share;

-- Q7: Ideal-target profile. The ten age, income and family cells with the highest
-- response rate, ignoring cells with fewer than 200 customers.
SELECT age_band, income_band,
       CASE WHEN children > 0 THEN 'Family' ELSE 'No children' END AS family_type,
       COUNT(*) AS customers,
       ROUND(100 * AVG(response), 1) AS response_rate_pct,
       ROUND(AVG(total_spend), 1) AS avg_spend
FROM vw_customer_360
GROUP BY age_band, income_band, family_type
HAVING COUNT(*) >= 200
ORDER BY response_rate_pct DESC
LIMIT 10;

-- Q8: Top 3 customers by spend inside each country
SELECT country, customer_id, total_spend, spend_rank
FROM (
    SELECT country, customer_id, total_spend,
           ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_spend DESC) AS spend_rank
    FROM vw_customer_360
) t
WHERE spend_rank <= 3
ORDER BY country, spend_rank;