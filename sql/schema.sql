-- ============================================
-- Retail Analytics Database Schema
-- Dunnhumby "Complete Journey" dataset
-- ============================================

CREATE DATABASE IF NOT EXISTS retail_analytics;
USE retail_analytics;

-- Household dimension (demographics available for 801 of 2,500 households)
CREATE TABLE households (
    household_key INT PRIMARY KEY,
    age_desc VARCHAR(20),
    marital_status VARCHAR(5),
    income_desc VARCHAR(20),
    homeowner_desc VARCHAR(30),
    hh_comp_desc VARCHAR(30),
    household_size VARCHAR(10),
    kid_category VARCHAR(20)
);

-- Product dimension
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    manufacturer INT,
    department VARCHAR(50),
    brand VARCHAR(20),
    commodity_desc VARCHAR(100),
    sub_commodity_desc VARCHAR(100),
    curr_size_of_product VARCHAR(30)
);

-- Campaign dimension
CREATE TABLE campaigns (
    campaign INT PRIMARY KEY,
    description VARCHAR(20),
    start_day INT,
    end_day INT
);

-- Transactions fact table (cleaned: zero-quantity rows removed, 
-- net_sales_value added to reflect post-discount revenue)
CREATE TABLE transactions (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    household_key INT,
    basket_id BIGINT,
    day INT,
    product_id INT,
    quantity INT,
    sales_value DECIMAL(10,2),
    store_id INT,
    retail_disc DECIMAL(10,2),
    trans_time INT,
    week_no INT,
    coupon_disc DECIMAL(10,2),
    coupon_match_disc DECIMAL(10,2),
    net_sales_value DECIMAL(10,2),
    INDEX idx_household (household_key),
    INDEX idx_product (product_id),
    INDEX idx_store (store_id),
    INDEX idx_week (week_no)
);

-- Campaign-household bridge
CREATE TABLE campaign_household (
    household_key INT,
    campaign INT,
    description VARCHAR(20),
    INDEX idx_hh (household_key),
    INDEX idx_camp (campaign)
);

-- Coupons
CREATE TABLE coupons (
    coupon_upc BIGINT,
    product_id INT,
    campaign INT,
    INDEX idx_product (product_id),
    INDEX idx_campaign (campaign)
);

-- Coupon redemptions
CREATE TABLE coupon_redemptions (
    household_key INT,
    day INT,
    coupon_upc BIGINT,
    campaign INT,
    INDEX idx_hh (household_key)
);

-- Promo summary: aggregated from 36.7M row-level causal_data records 
-- down to product-store level (% of tracked weeks with display/mailer activity)
CREATE TABLE promo_summary (
    product_id INT,
    store_id INT,
    weeks_tracked INT,
    weeks_displayed INT,
    weeks_mailer INT,
    pct_weeks_displayed DECIMAL(5,4),
    pct_weeks_mailer DECIMAL(5,4),
    INDEX idx_product (product_id),
    INDEX idx_store (store_id)
);

-- customer_rfm_churn is created via Python (pandas .to_sql()) after 
-- RFM analysis, not defined here — see notebooks/01_data_pipeline.ipynb

-- promo_effectiveness is a derived summary table — see queries.sql, 
-- Module 4, for the CREATE TABLE AS SELECT statement
