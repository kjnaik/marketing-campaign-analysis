-- Splits the staging table (stg_marketing, written by src/db_loader.py)
-- into the normalized tables. Parents are loaded before children.
USE marketing_db;

INSERT INTO customers (customer_id, year_birth, age, age_band, education,
    marital_status, country, income, income_band, kidhome, teenhome,
    children, dt_customer, tenure_days, recency, complain)
SELECT ID, Year_Birth, Age, Age_Band, Education, Marital_Status, Country,
       Income, Income_Band, Kidhome, Teenhome, Children,
       DATE(Dt_Customer), Customer_Tenure_Days, Recency, Complain
FROM stg_marketing;

INSERT INTO spending (customer_id, mnt_wines, mnt_fruits, mnt_meat_products,
    mnt_fish_products, mnt_sweet_products, mnt_gold_prods, total_spend)
SELECT ID, MntWines, MntFruits, MntMeatProducts, MntFishProducts,
       MntSweetProducts, MntGoldProds, Total_Spend
FROM stg_marketing;

INSERT INTO channel_activity (customer_id, num_deals_purchases,
    num_web_purchases, num_catalog_purchases, num_store_purchases,
    num_web_visits_month, total_purchases)
SELECT ID, NumDealsPurchases, NumWebPurchases, NumCatalogPurchases,
       NumStorePurchases, NumWebVisitsMonth, Total_Purchases
FROM stg_marketing;

INSERT INTO campaign_responses (customer_id, accepted_cmp1, accepted_cmp2,
    accepted_cmp3, accepted_cmp4, accepted_cmp5, response, campaigns_accepted)
SELECT ID, AcceptedCmp1, AcceptedCmp2, AcceptedCmp3, AcceptedCmp4,
       AcceptedCmp5, Response, Campaigns_Accepted
FROM stg_marketing;

INSERT INTO customer_segments (customer_id, seg_high_income,
    seg_young_customer, seg_campaign_responder, seg_high_web_engagement,
    seg_family_customer, seg_high_spender, seg_underserved)
SELECT ID, Seg_High_Income, Seg_Young_Customer, Seg_Campaign_Responder,
       Seg_High_Web_Engagement, Seg_Family_Customer, Seg_High_Spender,
       Seg_Underserved
FROM stg_marketing;

DROP TABLE IF EXISTS stg_marketing;