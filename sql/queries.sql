-- ============================================
-- Retail Analytics: Dashboard Queries
-- One module per Power BI dashboard page
-- ============================================
USE retail_analytics;

-- ============================================
-- Module 1: Revenue & Profit Overview
-- Weekly revenue trend. Units capped at quantity <= 100 to exclude 
-- weight/volume-based items (e.g. fuel) that distort unit counts —
-- revenue is unaffected since it's based on sales_value, not quantity.
-- ============================================
SELECT 
    week_no,
    SUM(net_sales_value) AS total_revenue,
    SUM(CASE WHEN quantity <= 100 THEN quantity ELSE 0 END) AS total_units,
    COUNT(DISTINCT basket_id) AS total_baskets
FROM transactions
GROUP BY week_no
ORDER BY week_no;

-- ============================================
-- Module 2: Store Performance
-- Top 20 stores by revenue
-- ============================================
SELECT 
    store_id,
    SUM(net_sales_value) AS total_revenue,
    COUNT(DISTINCT basket_id) AS total_baskets,
    COUNT(DISTINCT household_key) AS unique_customers,
    SUM(CASE WHEN quantity <= 100 THEN quantity ELSE 0 END) AS total_units
FROM transactions
GROUP BY store_id
ORDER BY total_revenue DESC
LIMIT 20;

-- ============================================
-- Module 3: Product Performance
-- Top 20 categories by revenue. COUPON/MISC ITEMS excluded — 
-- found to be 84% gasoline sales, not genuine grocery products.
-- ============================================
SELECT 
    p.commodity_desc,
    SUM(t.net_sales_value) AS total_revenue,
    SUM(CASE WHEN t.quantity <= 100 THEN t.quantity ELSE 0 END) AS total_units,
    COUNT(DISTINCT t.basket_id) AS total_baskets
FROM transactions t
JOIN products p ON t.product_id = p.product_id
WHERE p.commodity_desc != 'COUPON/MISC ITEMS'
GROUP BY p.commodity_desc
ORDER BY total_revenue DESC
LIMIT 20;

-- ============================================
-- Module 4: Pricing & Promotions
-- Promo effectiveness: average discount depth by promotion type.
-- Note: causal_data only tracks product-store-weeks with some 
-- recorded promo activity, so a true "no promotion" baseline group 
-- doesn't exist in this dataset — comparisons are relative across 
-- promo types (mailer-only, display-only, both).
-- Saved as a permanent summary table for Power BI (avoids a complex 
-- live join between two large fact-like tables).
-- ============================================
CREATE TABLE promo_effectiveness AS
SELECT 
    (ps.pct_weeks_displayed > 0) AS was_displayed,
    (ps.pct_weeks_mailer > 0) AS was_mailered,
    COUNT(*) AS product_store_pairs,
    AVG(t.avg_discount) AS avg_discount_per_pair
FROM promo_summary ps
JOIN (
    SELECT product_id, store_id, AVG(retail_disc + coupon_disc) AS avg_discount
    FROM transactions
    GROUP BY product_id, store_id
) t ON ps.product_id = t.product_id AND ps.store_id = t.store_id
GROUP BY was_displayed, was_mailered;


-- ============================================
-- Module 5: Customer Churn & Segments
-- Segment-level summary: size, RFM averages, total value.
-- Churn defined as no purchase in 90+ days (see notebook for RFM logic).
-- ============================================
SELECT 
    segment,
    COUNT(*) AS customer_count,
    AVG(recency) AS avg_recency,
    AVG(frequency) AS avg_frequency,
    AVG(monetary) AS avg_monetary,
    SUM(monetary) AS total_segment_value
FROM customer_rfm_churn
GROUP BY segment
ORDER BY total_segment_value DESC;

-- ============================================
-- Module 6: Customer Value / At-Risk
-- Top 20 highest-value At Risk / Churned customers — 
-- win-back priority list.
-- ============================================
SELECT 
    household_key,
    recency,
    frequency,
    monetary,
    segment
FROM customer_rfm_churn
WHERE segment IN ('At Risk', 'Churned')
ORDER BY monetary DESC
LIMIT 20;