-- Create a profit, sneaker age, and sneaker model column for analysis
ALTER TABLE stockx_sales
ADD COLUMN profit SMALLINT,
ADD COLUMN sneaker_age INTEGER,
ADD COLUMN sneaker_model VARCHAR(50);

UPDATE stockx_sales
SET profit = sale_price - retail_price;

UPDATE stockx_sales
SET sneaker_age = order_date - release_date;

UPDATE stockx_sales
SET sneaker_model = 
	CASE 
	WHEN sneaker ILIKE 'Air-Jordan-1%'
		THEN 'Off-White Air Jordans'
	WHEN sneaker ILIKE 'Nike-Air-Force-1%'
		THEN 'Off-White Air Forces'
	WHEN sneaker ILIKE 'Nike-Air-Max-90%'
		THEN 'Off-White Air Max 90'
	WHEN sneaker ILIKE 'Nike-Air-Max-97%'
		THEN 'Off-White Air Max 97'
	WHEN sneaker ILIKE 'Nike-Air-Presto%'
		THEN 'Off-White Prestos'
	WHEN sneaker ILIKE 'Nike-Air-VaporMax%'
		THEN 'Off-White VaporMax'
	WHEN sneaker ILIKE 'Nike-Blazer%'
		THEN 'Off-White Blazers'
	WHEN sneaker ILIKE '%Hyperdunk%'
		THEN 'Off-White Hyperdunks'
	WHEN sneaker ILIKE 'Nike-Zoom-Fly%'
		THEN 'Off-White Zoom Fly'
	WHEN sneaker ILIKE '%-V2-%'
		THEN 'Yeezy Boost 350 V2'
	ELSE 'Yeezy Boost 350'
	END;

-- Total pairs sold from each brand
SELECT brand, COUNT(brand) AS total_pairs
FROM stockx_sales
GROUP BY brand;

-- Number of pairs of each sneaker sold
SELECT sneaker, COUNT(*) AS total_pairs
FROM stockx_sales
GROUP BY sneaker
ORDER BY total_pairs DESC;

-- Total pairs sold per shoe size per brand
SELECT shoe_size,
	SUM(CASE
		 	WHEN brand = 'Yeezy' THEN 1
		 	ELSE 0
		 END) AS Yeezy,
	SUM(CASE
		 	WHEN brand = 'Off-White' THEN 1
		 	ELSE 0
		 END) AS Off_White
FROM stockx_sales
GROUP BY shoe_size
ORDER BY shoe_size;

-- Total sales each month per brand
SELECT to_char(order_date, 'Month') AS order_month, 
	SUM(CASE
			WHEN brand = 'Yeezy' 
			THEN sale_price
	   		ELSE 0
	   	END) AS yeezy_sales,
	SUM(CASE
			WHEN brand = 'Off-White' 
			THEN sale_price
	   		ELSE 0
	   	END) AS off_white_sales,
	SUM(sale_price) AS total_sales
FROM stockx_sales
GROUP BY order_month
ORDER BY total_sales DESC;

-- Sales and profit per brand
SELECT brand, SUM(sale_price) AS total_sales, ROUND(AVG(sale_price), 2) AS avg_sales,
	SUM(profit) as total_profit, ROUND(AVG(profit), 2) AS avg_profit
FROM stockx_sales
GROUP BY brand;

-- Sales and profit per region/state
SELECT region, SUM(sale_price) AS total_sales, ROUND(AVG(sale_price), 2) AS avg_sales,
	SUM(profit) as total_profit, ROUND(AVG(profit), 2) AS avg_profit
FROM stockx_sales
GROUP BY region
ORDER BY total_sales DESC;

-- Sales and profit by sneaker model
SELECT sneaker_model, COUNT(*) AS total_pairs, SUM(sale_price) AS total_sales, 
	ROUND(AVG(sale_price), 2) AS avg_sales, SUM(profit) as total_profit, 
	ROUND(AVG(profit), 2) AS avg_profit
FROM stockx_sales
GROUP BY sneaker_model
ORDER BY total_pairs DESC;

-- Average age of sneakers when they were sold and their average profit
SELECT sneaker, ROUND(AVG(sneaker_age), 1) AS avg_age,
	ROUND(AVG(profit), 2) AS avg_profit
FROM stockx_sales
GROUP BY sneaker
ORDER BY avg_age;

-- Average profit per shoe size
SELECT sneaker_model, shoe_size, 
	ROUND(AVG(profit), 2) AS avg_profit
FROM stockx_sales
GROUP BY sneaker_model, shoe_size
ORDER BY sneaker_model, shoe_size ASC;
