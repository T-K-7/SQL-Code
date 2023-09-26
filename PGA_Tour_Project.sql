---Questions 2018-2022 PGA Tour

--Delete duplicate rows

WITH delete_dupes AS (
	select 
		player,
		date,
		tournament_id,
		ROW_NUMBER()OVER(PARTITION BY player, date, tournament_id ORDER BY player) AS RN
	from Golf_Project.dbo.GolfData)

DELETE FROM delete_dupes 
WHERE RN = 2;

--Seperate course from city & state

select
	CASE WHEN CHARINDEX('-',course)>0 THEN
		SUBSTRING(course, 1, CHARINDEX('-', course)-1)
		ELSE SUBSTRING(course, 1, CHARINDEX(',', course)-1) END AS Course_Name
from Golf_Project.dbo.GolfData

ALTER TABLE Golf_Project.dbo.GolfData
ADD Course_Name Nvarchar(255);

--Create Course column
UPDATE Golf_Project.dbo.GolfData
SET Course_Name = 	CASE WHEN CHARINDEX('-',course)>0 THEN
						SUBSTRING(course, 1, CHARINDEX('-', course)-1)
						ELSE SUBSTRING(course, 1, CHARINDEX(',', course)-1) END

select
	CASE WHEN CHARINDEX('-',course)>0 THEN
		SUBSTRING(course, CHARINDEX('-', course)+2, ((CHARINDEX(',', course)-2)-CHARINDEX('-', course)))
		ELSE SUBSTRING(course, CHARINDEX(',', course)+2, CHARINDEX(',', course, CHARINDEX(',', course)+1)-CHARINDEX(',', course)-2) END AS City_Name
from Golf_Project.dbo.GolfData

ALTER TABLE Golf_Project.dbo.GolfData
ADD City_Name Nvarchar(255);

--Create City column
UPDATE Golf_Project.dbo.GolfData
SET City_Name =  CASE WHEN CHARINDEX('-',course)>0 THEN
					SUBSTRING(course, CHARINDEX('-', course)+2, ((CHARINDEX(',', course)-2)-CHARINDEX('-', course)))
					ELSE SUBSTRING(course, CHARINDEX(',', course)+2, CHARINDEX(',', course, CHARINDEX(',', course)+1)-CHARINDEX(',', course)-2) END

--Create Territory column
	
select
	CASE WHEN CHARINDEX('-',course)>0 THEN
		SUBSTRING(course, CHARINDEX(',', course)+2, LEN(course))
		ELSE TRIM(SUBSTRING(course, CHARINDEX(',', course, CHARINDEX(',', course)+1)+1, LEN(course) - CHARINDEX(',', course, CHARINDEX(',', course)+1))) END AS Territory
from Golf_Project.dbo.GolfData

ALTER TABLE Golf_Project.dbo.GolfData
ADD Territory Nvarchar(255);

UPDATE Golf_Project.dbo.GolfData
SET Territory =  CASE WHEN CHARINDEX('-',course)>0 THEN
					SUBSTRING(course, CHARINDEX(',', course)+2, LEN(course))
					ELSE TRIM(SUBSTRING(course, CHARINDEX(',', course, CHARINDEX(',', course)+1)+1, LEN(course) - CHARINDEX(',', course, CHARINDEX(',', course)+1))) END

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Who won the most number of tournaments, each year?

WITH wins AS (
select *
from Golf_Project.dbo.GolfData
where Finish = 1
)

select 
	season,
	player,
	COUNT(*) AS TotalWins
from wins
group by player, season
order by season, TotalWins DESC;
   
select
	AVG(age)
from Golf_Project.dbo.GolfData;

--Young Man or Old Man's game?
WITH old_young AS(
select 
	player,
	Age,
	season,
	CASE WHEN Age < 33 THEN 'Young Player'
		ELSE 'Seasoned Player'END AS Age_Category,
	CASE WHEN Finish = 1 THEN 1
		ELSE 0 END AS Num_Wins,
	CASE WHEN Finish = 0 THEN 1
		ELSE 0 END AS Missed_Cuts,
	Finish
from Golf_Project.dbo.GolfData)

select
	 season,
	 Age_Category,
	 AVG(Finish) AS Avg_Finish,
	 SUM(Num_Wins) AS Total_Wins,
	 SUM(Missed_Cuts) As Missed_Cuts,
	 Count(player) AS Players
from old_young
where Finish <> 0
group by Age_Category, season;

--How many unique winners, each year?

WITH unique_wins AS (
select distinct player,
	season
from Golf_Project.dbo.GolfData
where Finish = 1
)

select 
	season,
	COUNT(*) AS UniqueWinners
from unique_wins
group by season;

--Which player had the most Top 10s, each year (Do a rank and take 1,2,3 from each year)?

WITH top10s AS (
select 
	player,
	season
from Golf_Project.dbo.GolfData
where Finish <= 10 AND Finish <> 0
)

select 
	player,
	season,
	COUNT(*) AS Top10s
from top10s
group by player,
	season
order by Top10s DESC;


--Drive for show or Putt for dough?

--Drive

WITH Drive AS(
select 
	player,
	AVG(Finish) AS Avg_Finish,
	AVG(sg_ott) AS Avg_Ott,
	AVG(Drive_Yards) AS Distance,
	Finish
from Golf_Project.dbo.GolfData
group by player, Finish
),

Drive_Rank AS (
select 
	player,
	Avg_Ott,
	RANK()OVER(ORDER BY Avg_Ott DESC) AS OTT_Rank,
	Distance,
	RANK()OVER(ORDER BY Distance DESC) AS Distance_Rank,
	Avg_Finish,
	CASE WHEN Finish = 1 THEN 'Winner'
	ELSE 'No' END As Winner
from Drive),

Wins AS(
select 
	player,
	Avg_Ott,
	OTT_Rank,
	Distance,
	Distance_Rank,
	(OTT_Rank+Distance_Rank)/2 AS Avg_Rank,
	Avg_Finish,
	Winner
from Drive_Rank)

select *
from Wins
where Winner = 'Winner'

--Putt
WITH Putt AS(
select 
	player,
	AVG(Finish) AS Avg_Finish,
	AVG(sg_putt) AS Avg_putt,
	AVG(PUTTS_HOLE) AS Avg_putt_hole,
	Finish
from Golf_Project.dbo.GolfData
group by player, Finish
),
Putt_Rank AS (
select 
	player,
	Avg_putt,
	RANK()OVER(ORDER BY Avg_putt DESC) AS Putt_Rank,
	Avg_putt_hole,
	RANK()OVER(ORDER BY Avg_putt_hole) AS Putts_Hole_Rank,
	Avg_Finish,
	CASE WHEN Finish = 1 THEN 'Winner'
	ELSE 'No' END As Winner
from Putt),

Wins2 AS(
select 
	player,
	Avg_putt,
	Putt_Rank,
	Avg_putt_hole,
	Putts_Hole_Rank,
	(Putt_Rank+Putts_Hole_Rank)/2 AS Avg_Rank,
	Avg_Finish,
	Winner
from Putt_Rank)

select *
from Wins2
where Winner = 'Winner'

--Who performs the best in heat and cold?
	
WITH temp AS(
select 
	player,
	date,
	season,
	finish,
	tempC,
	CASE WHEN tempC >= 27 THEN 'Hot'
	WHEN tempC <= 13 THEN 'Cold'
	ELSE 'Normal' END AS Temp_Cat
from Golf_Project.dbo.GolfData)

select
	Temp_Cat,
	Count(DISTINCT date) As Number_Tournaments
from temp
group by Temp_Cat;


WITH temp2 AS(
select 
	player,
	date,
	season,
	finish,
	tempC,
	CASE WHEN tempC >= 27 THEN 'Hot'
	WHEN tempC <= 13 THEN 'Cold'
	ELSE 'Normal' END AS Temp_Cat
from Golf_Project.dbo.GolfData)

select 
	player,
	AVG(finish) as Avg_Finish,
	AVG(tempC) as Avg_Temp,
	COUNT(*) as Num_Tournaments
from temp2
where Temp_Cat = 'Cold' AND Finish <> 0
group by player
order by Avg_Finish;


WITH temp3 AS(
select 
	player,
	date,
	season,
	finish,
	tempC,
	CASE WHEN tempC >= 27 THEN 'Hot'
	WHEN tempC <= 13 THEN 'Cold'
	ELSE 'Normal' END AS Temp_Cat
from Golf_Project.dbo.GolfData)

select 
	player,
	AVG(finish) as Avg_Finish,
	AVG(tempC) as Avg_Temp,
	COUNT(*) as Num_Tournaments
from temp3
where Temp_Cat = 'Hot' AND Finish <> 0
group by player
order by Avg_Finish;

--Who is the king of CA?

WITH state_abv AS(
select
	player,
	finish,
	season,
	RIGHT(course, 2) as State
from Golf_Project.dbo.GolfData),

state_int AS (
select *
from state_abv
where cast(State as varbinary(120)) != cast(lower(State) as varbinary(120)))

select *
from state_int
where State = 'CA' and Finish !=0

--Tallest Player, Smallest Player, Average?

WITH height AS (
select distinct player,
	Height_cm
from Golf_Project.dbo.GolfData),

height_rank AS (
select 
	player,
	Height_cm,
	RANK()OVER(ORDER BY Height_cm DESC) AS Height_Order
from height)

--Tallest
select 
	player, 
	Height_cm
from height_rank
where Height_Order = 1

--Smallest
WITH height2 AS (
select distinct player,
	Height_cm
from Golf_Project.dbo.GolfData),

height_rank2 AS (
select 
	player,
	Height_cm,
	RANK()OVER(ORDER BY Height_cm) AS Height_Order
from height2)

select 
	player, 
	Height_cm
from height_rank2
where Height_Order = 1

--Average
	
select
	AVG(Height_cm)
from Golf_Project.dbo.GolfData
