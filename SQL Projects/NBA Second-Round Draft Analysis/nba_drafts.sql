/* Minutes per game per draft pick */
SELECT overall_pick, ROUND((SUM(total_minutes)::DECIMAL)/SUM(total_games), 1) AS MPG
FROM all_drafts
GROUP BY overall_pick
ORDER BY overall_pick ASC;

/* Minutes per game per round */
SELECT 
	CASE
		WHEN (overall_pick < 30 AND draft_year < 2004) OR (overall_pick < 31 AND draft_year > 2003)
		THEN 'First Round'
		ELSE 'Second Round'
	END draft_round, ROUND((SUM(total_minutes)::DECIMAL)/SUM(total_games), 1) AS MPG
FROM all_drafts
GROUP BY draft_round;

/* Minutes per game per selection category */
SELECT 
	CASE
		WHEN (overall_pick < 14 AND draft_year < 2004) OR (overall_pick < 15 AND draft_year > 2003)
			THEN 'Lottery'
		WHEN (overall_pick > 29 AND draft_year < 2004) OR (overall_pick > 30 AND draft_year > 2003)
			THEN 'Second Round'
		ELSE 'Mid-Late First Round'
	END selection_category, ROUND((SUM(total_minutes)::DECIMAL)/SUM(total_games), 1) AS MPG
FROM all_drafts
GROUP BY selection_category
ORDER BY MPG DESC;

/* Average number of years and games played, points per game (PPG),
rebounds per game (RPG), and assists per game (APG) per draft pick
*/
SELECT overall_pick, ROUND(AVG(years_active), 1) AS avg_years, 
	ROUND(AVG(total_games), 1) AS avg_games, 
	ROUND(SUM(total_points)::DECIMAL/SUM(total_games), 1) AS PPG,
	ROUND(SUM(total_rebounds)::DECIMAL/SUM(total_games), 1) AS RPG, 
	ROUND(SUM(total_assists)::DECIMAL/SUM(total_games), 1) AS APG
FROM all_drafts
GROUP BY overall_pick
ORDER BY overall_pick;

/* Number of draft picks per college */
SELECT college, 
	COUNT(*) FILTER 
		(WHERE (overall_pick < 31 AND draft_year > 2003) OR (overall_pick < 30 AND draft_year < 2004)) AS first_round_picks,
	COUNT(*) FILTER 
		(WHERE (overall_pick > 30 AND draft_year > 2003) OR (overall_pick > 29 AND draft_year < 2004)) AS second_round_picks,
	COUNT(*) AS total_picks
FROM all_drafts
WHERE college IS NOT NULL
GROUP BY college
ORDER BY total_picks DESC;

/* Number of draft picks per team */
SELECT team, 
	COUNT(*) FILTER 
		(WHERE (overall_pick < 31 AND draft_year > 2003) OR (overall_pick < 30 AND draft_year < 2004)) AS first_round_picks,
	COUNT(*) FILTER 
		(WHERE (overall_pick > 30 AND draft_year > 2003) OR (overall_pick > 29 AND draft_year < 2004)) AS second_round_picks,
	COUNT(*) AS total_picks
FROM all_drafts
GROUP BY team
ORDER BY total_picks DESC;

/* Team roles of drafted players
Requirements: 
- More than one (1) active year
- MPG > 10
- Either:
	- 400 or more games played, or
	- played in at least 70% of the regular season
*/
SELECT player_name, draft_year,
		CASE
			WHEN total_games >= 400 THEN 'Rotation'
			WHEN draft_year <= 2011 THEN
				CASE
					-- Played up and until the lockdown-shortened season
					WHEN (draft_year + years_active) < 2012 THEN
						CASE
							WHEN ((total_games::DECIMAL)/(years_active*82)) >= 0.7
							THEN 'Rotation'
						END
					-- Played during the lockdown-shortened season, but before the COVID/"Bubble"-season
					WHEN (draft_year + years_active) < 2020 THEN
						CASE
							WHEN (((total_games::DECIMAL))/((((years_active::DECIMAL)-1)*82)+66)) >= 0.7
							THEN 'Rotation'
						END
					-- Played during both the lockdown-shortened and COVID/"Bubble" season
					-- 70.6 = average number of games teams played in the regular season before COVID and during the "Bubble"
					WHEN 2020 <= (draft_year + years_active) AND (draft_year + years_active) < 2021 THEN
						CASE
							WHEN (((total_games::DECIMAL))/((((years_active::DECIMAL)-2)*82)+66+70.6)) >= 0.7
							THEN 'Rotation'
						END
				END
			WHEN draft_year > 2011 THEN
				CASE
					-- Played briefly before the COVID/"Bubble" season or after the COVID-shortened season
					WHEN ((draft_year + years_active) < 2020) OR (draft_year = 2021) THEN
						CASE
							WHEN (((total_games::DECIMAL))/(((years_active::DECIMAL)*82))) >= 0.7
							THEN 'Rotation'
						END
					-- Played but stopped after the COVID/"Bubble" season
					WHEN (draft_year + years_active) = 2020 THEN
						CASE
							WHEN (((total_games::DECIMAL))/((((years_active::DECIMAL)-1)*82)+70.6)) >= 0.7
							THEN 'Rotation'
						END
					-- Only played during the COVID-shortened season
					WHEN draft_year = 2020 THEN
						CASE
							WHEN (((total_games::DECIMAL))/((((years_active::DECIMAL)-1)*82)+72)) >= 0.7
							THEN 'Rotation'
						END
					-- Played through the COVID/"Bubble" and COVID-shortened season
					WHEN (draft_year + years_active) > 2020 AND draft_year < 2021 THEN
						CASE
							WHEN (((total_games::DECIMAL))/((((years_active::DECIMAL)-2)*82)+72+70.6)) >= 0.7
							THEN 'Rotation'
						END
				END
	END team_role
FROM all_drafts
WHERE years_active > 1
ORDER BY team_role ASC, draft_year;