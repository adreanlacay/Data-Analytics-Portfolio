/* Creating a string column that expands education_type, 
and renaming education_type to education_code to ease any 
confusion when reading. */
ALTER TABLE education_attainment
ADD COLUMN education_category VARCHAR(25);

UPDATE education_attainment
SET education_category = 
	CASE
		WHEN education_type = 'BUPPSRY' THEN 'Below Upper-Secondary'
		WHEN education_type = 'UPPSRY' THEN 'Upper-Secondary'
		ELSE 'Tertiary'
	END;

ALTER TABLE education_attainment
RENAME COLUMN education_type TO education_code;

/* Education level of the largest proportion of adults per country.
Creating it as a view to quickly refer to it for other queries. */
CREATE VIEW highest_percentage_group AS
(SELECT ea1.country, country_code, education_category, education_code, 
 	category_percentage
FROM 
	(SELECT country, MAX(percentage) AS category_percentage
	FROM education_attainment
	GROUP BY country) ea1 
	JOIN
	(SELECT *
	FROM education_attainment) ea2
	ON ea1.country = ea2.country AND category_percentage = percentage);

/* Number of countries per education_category */
SELECT education_category, COUNT(*)
FROM highest_percentage_group
GROUP BY education_category;

/* Creating a view to join highest_percentage_group with 
population, GINI, labour force, unemployment rate, life 
expectancy, educational expenditure, and real GDP data. */
CREATE VIEW OECD_data AS
(SELECT hpg.*, population, gini_index, real_gdp, labour_force, 
 	unemployment_rate, life_expectancy, education_expenditure
FROM (SELECT * FROM highest_percentage_group) hpg
	JOIN (SELECT country, population, gini_index, real_gdp, labour_force,
		 	unemployment_rate, life_expectancy, education_expenditure
		 FROM world_factbook) wf
	ON hpg.country = wf.country)

/* Number of countries within certain GINI index ranges
for each education category */
SELECT education_category, 
	SUM(CASE
	   		WHEN gini_index < 30
	   		THEN 1 ELSE 0
	   END) AS below_30,
	SUM(CASE
	   		WHEN gini_index < 40 AND gini_index >= 30
	   		THEN 1 ELSE 0
		END) AS between_30_below_40,
	SUM(CASE
	   		WHEN gini_index >= 40
	   			THEN 1 ELSE 0
	   END) AS above_40
FROM OECD_data
GROUP BY education_category;

/* Income per capita per education category */
SELECT education_category, 
	ROUND((SUM(total_income)/SUM(population)), 2) AS group_income
FROM
	((SELECT country, (avg_income * population) AS total_income
	FROM 
		(SELECT country, country_code, education_category, population
		 FROM OECD_data) oecd
		 JOIN
		 (SELECT country_code, avg_income
		 FROM income_per_capita) ipc
		 ON oecd.country_code = ipc.country_code) oecd_income
	JOIN
	(SELECT *
	FROM OECD_data) country_info
	ON oecd_income.country = country_info.country)
GROUP BY education_category;

/* Distribution of education category per life expectancy */
SELECT education_category, 
	SUM(CASE
	   		WHEN life_expectancy > 82.2
	   		THEN 1 ELSE 0
	   END) AS top_third,
	SUM(CASE
	   		WHEN life_expectancy < 82.2 AND life_expectancy > 78.4
	   		THEN 1 ELSE 0
	   END) AS middle_third,
	SUM(CASE
	   		WHEN life_expectancy < 78.4
	   		THEN 1 ELSE 0
	   END) bottom_third
FROM OECD_data
GROUP BY education_category;

/* Unemployment rate per education category */
SELECT education_category, 
	ROUND((SUM(total_unemployed)/SUM(labour_force))*100, 2) AS group_umemp_rate
FROM 
	(SELECT country, (unemployment_rate/100)*labour_force AS total_unemployed
	FROM OECD_data) oecd1
	JOIN
	(SELECT country, education_category, labour_force
	FROM OECD_data) oecd2
	ON oecd1.country = oecd2.country
GROUP BY education_category;

/* Educational expenditure per education category */
SELECT education_category, 
	ROUND((SUM(total_expenditure)/SUM(real_gdp))*100, 2) AS group_expenditure
FROM 
	(SELECT country, (education_expenditure/100)*real_gdp AS total_expenditure
	FROM OECD_data) oecd1
	JOIN
	(SELECT country, education_category, real_gdp
	FROM OECD_data) oecd2
	ON oecd1.country = oecd2.country
GROUP BY education_category;

/* Educational expenditure, unemployment rate, GINI index,
and life expectancy rankings of South Africa and Costa Rica */
SELECT country, edu_rank, unemp_rank, gini_rank, life_expectancy_rank
FROM
	(SELECT country, education_expenditure,
		RANK() OVER (
			ORDER BY education_expenditure DESC
		) edu_rank,
		RANK() OVER (
			ORDER BY unemployment_rate DESC
		) unemp_rank,
		RANK() OVER (
			ORDER BY gini_index DESC
		) gini_rank,
		RANK() OVER (
			ORDER BY life_expectancy DESC
		) life_expectancy_rank
	FROM OECD_data) AS rankings
WHERE country in ('South Africa', 'Costa Rica')
