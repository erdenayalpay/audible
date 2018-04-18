DROP TABLE IF EXISTS stg_stores;

--#####################################################
--# First load all tables as varchar entries.
--#####################################################
CREATE TABLE stg_stores 
  ( 
     store VARCHAR, 
     type  VARCHAR, 
     size  VARCHAR 
  ); 
  
DROP TABLE IF EXISTS stg_features;
CREATE TABLE stg_features 
  ( 
     store        VARCHAR, 
     date         VARCHAR, 
     temperature  VARCHAR, 
     fuel_price   VARCHAR, 
     markdown1    VARCHAR, 
     markdown2    VARCHAR, 
     markdown3    VARCHAR, 
     markdown4    VARCHAR, 
     markdown5    VARCHAR, 
     cpi          VARCHAR, 
     unemployment VARCHAR, 
     isholiday    VARCHAR 
  ); 

DROP TABLE IF EXISTS stg_sales;
CREATE TABLE stg_sales 
  ( 
     store        VARCHAR, 
     dept         VARCHAR, 
     date         VARCHAR, 
     weekly_sales VARCHAR, 
     isholiday    VARCHAR 
  ); 

COPY stg_stores FROM 'C:\Users\C45873\Documents\audible\stores.csv' delimiter ',' csv header; 
COPY stg_features FROM 'C:\Users\C45873\Documents\audible\features.csv' delimiter ',' csv header; 
COPY stg_sales FROM 'C:\Users\C45873\Documents\audible\sales.csv' delimiter ',' csv header; 

--#####################################################
--# Then create a new table from stating table
--# after correcting each column with relevant data type.
--#####################################################

DROP TABLE IF EXISTS stores;
CREATE TABLE stores AS 
  SELECT store, 
         type, 
         Cast(size AS INT) AS size 
  FROM   stg_stores; 

DROP TABLE IF EXISTS features;
CREATE TABLE features AS 
  SELECT store, 
         TO_DATE(date, 'DD/MM/YYYY')  AS date, 
         Cast(temperature AS DECIMAL) AS temperature, 
         Cast(fuel_price AS DECIMAL)  AS fuel_price, 
         CASE 
           WHEN markdown1 = 'NA' THEN NULL 
           ELSE Cast(markdown1 AS DECIMAL) 
         END                          AS markdown1, 
         CASE 
           WHEN markdown2 = 'NA' THEN NULL 
           ELSE Cast(markdown2 AS DECIMAL) 
         END                          AS markdown2, 
         CASE 
           WHEN markdown3 = 'NA' THEN NULL 
           ELSE Cast(markdown3 AS DECIMAL) 
         END                          AS markdown3, 
         CASE 
           WHEN markdown4 = 'NA' THEN NULL 
           ELSE Cast(markdown4 AS DECIMAL) 
         END                          AS markdown4, 
         CASE 
           WHEN markdown5 = 'NA' THEN NULL 
           ELSE Cast(markdown5 AS DECIMAL) 
         END                          AS markdown5, 
         CASE 
           WHEN cpi = 'NA' THEN NULL 
           ELSE Cast(cpi AS DECIMAL) 
         END                          AS cpi, 
         CASE 
           WHEN unemployment = 'NA' THEN NULL 
           ELSE Cast(unemployment AS DECIMAL) 
         END                          AS unemployment, 
         Cast(isholiday AS BOOL)      AS isholiday 
  FROM   stg_features; 

DROP TABLE IF EXISTS sales;
CREATE TABLE sales AS 
  SELECT store, 
         dept, 
         TO_DATE(date, 'DD/MM/YYYY')   AS date, 
         Cast(weekly_sales AS DECIMAL) AS weekly_sales, 
         Cast(isholiday AS BOOL)       AS isholiday 
  FROM   stg_sales; 

--#####################################################
--#	Average department and store sales per week
--#####################################################
SELECT date, 
       Sum(sum_dept_sales) / Count(nmbr_of_depts) AS store_average_per_week, 
       Sum(sum_dept_sales) / Sum(nmbr_of_depts)   AS dept_average_per_week 
FROM   (SELECT store, 
               date, 
               Sum(weekly_sales)   AS sum_dept_sales, 
               Count(weekly_sales) AS nmbr_of_depts 
        FROM   sales 
        GROUP  BY store, 
                  date) a 
GROUP  BY date 
ORDER  BY date ASC; 

--#####################################################
--#	Average department and store sales per temperature
--#####################################################
SELECT round_temp,
       Sum(sum_dept_sales) / Count(sum_dept_sales) AS store_average_per_temperature,
       Sum(sum_dept_sales) / Sum(nmbr_of_depts)    AS dept_average_per_temperature
FROM   (SELECT store,
               temperature,
               Round(temperature, 0) AS round_temp,
               Sum(weekly_sales)     AS sum_dept_sales,
               Count(weekly_sales)   AS nmbr_of_depts
        FROM   (SELECT a.*,
                       b.temperature
                FROM   sales a
                       LEFT JOIN features b
                              ON a.store = b.store
                                 AND a.date = b.date) c
        GROUP  BY store,
                  date,
                  temperature) d
GROUP  BY round_temp
ORDER  BY round_temp ASC; 

--#####################################################
--# Store with highest sales per week
--#####################################################
SELECT *
FROM   (SELECT a.*,
               RANK()
                 OVER (
                   partition BY date
                   ORDER BY sum_dept_sales DESC) AS rnk
        FROM   (SELECT store,
                       date,
                       Sum(weekly_sales) AS sum_dept_sales
                FROM   sales
                GROUP  BY store,
                          date) a) b
WHERE  rnk = 1
ORDER  BY date ASC;
