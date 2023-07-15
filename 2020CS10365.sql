--1-- 
SELECT DISTINCT batting. playerid, namefirst, namelast, coalesce(sum(cs),0) as total_caught_stealing
FROM batting,people                                           
WHERE batting.playerID=people.playerID
GROUP BY batting.playerID,namefirst,namelast
ORDER BY total_caught_stealing DESC, namefirst, namelast, playerID
LIMIT 10;

--2--
SELECT playerid, namefirst,coalesce(sum(h2b),0)*2+coalesce(sum(h3b),0)*3+coalesce(sum(hr),0)*4 as runscore 
FROM people join batting using (playerid)
GROUP BY playerid,namefirst
ORDER BY runscore DESC, namefirst DESC, playerID
LIMIT 10;

--3--
SELECT awardsshareplayers.playerid, 
    case 
    when namefirst is null and namelast is null then ''
    else coalesce(namefirst,'')||' '||coalesce(namelast,'')
    end as playername
    , coalesce(sum(pointswon),0) as total_points
FROM awardsshareplayers,people
WHERE awardsshareplayers.playerID=people.playerid and yearid>=2000
GROUP BY awardsshareplayers.playerID, playername
ORDER BY total_points DESC, playerid
LIMIT 10;

--4--
SELECT batting.playerid, namefirst, namelast, ((1.0*sum(h))/(1.0*sum(ab))) as career_batting_average
FROM batting,people                                  
WHERE batting.playerID=people.playerID and h is not null and ab is not null and ab != 0 
GROUP BY batting.playerID, namefirst, namelast
HAVING count(distinct yearid)>=10
ORDER BY career_batting_average DESC, playerid, namefirst, namelast
LIMIT 10;

--5--
SELECT playerid, namefirst,namelast,case
    when birthyear is null or birthday is null or birthmonth is null then ''
    else birthyear||'-'||birthmonth||'-'||birthday
    end as date_of_birth,
num_seasons
FROM people join
    (SELECT playerid, count(*) as num_seasons
    FROM 
        (SELECT DISTINCT playerid,yearid
        FROM batting
        UNION
        SELECT DISTINCT playerid,yearid
        FROM pitching
        UNION
        SELECT DISTINCT playerid,yearid
        FROM fielding)as t1
    GROUP BY playerid)as t2
    using (playerid)
ORDER BY num_seasons DESC,playerid,namefirst,namelast,date_of_birth;

--6--
SELECT teamid, teams.name, franchname, max(w) as num_wins
FROM teams,teamsfranchises
WHERE teams.franchid=teamsfranchises.franchid and divwin=true
GROUP BY teamid , teams.name , franchname
ORDER BY num_wins DESC, teamid, teams.name, franchname;

--7--
create view temp1 as(
    (select  max(wp) as wp ,teamid
    from (select  (w*1.0/g)*100 as wp, yearid,teamid
        from teams  
        where teamid in 
        (select teamid 
        from (select teamid, sum(w) as wins 
        from teams 
        group by teamid) as t1
        where wins>19)) 
        as t2
        group by teamid));
with temp2 as
(select (w::decimal/g)*100 as wp ,teamid,yearid
from teams 
where teamid in 
    (select teamid 
    from (select sum(w) as numwins,teamid
        from teams 
        group by teamid) as t3
    where numwins>19))
select temp3.teamid, teamname, seasonid, wp as winning_percentage 
from
    (select yearid as seasonid, temp1.wp ,temp1.teamid
    from temp1 join temp2  using(teamid,wp)) as temp3 join
        (select t.teamid, name as teamname 
        from teams 
        join (select teamid, max(yearid) from teams group by teamid) as t on t.teamid = teams.teamid and t.max = teams.yearid) as temp4 on temp3.teamid = temp4.teamid
    order by wp desc, temp3.teamid , teamname , seasonid 
limit 5;

--8--
SELECT DISTINCT compute.teamid, teams.name, compute.yearid, compute.playerid,namefirst,namelast,compute.salary
FROM people,teams,
    (SELECT s1.teamid,s1.yearid, s1.playerid, s1.salary
    FROM salaries s1
    LEFT JOIN salaries s2 ON s1.salary < s2.salary 
        AND s1.teamid=s2.teamid 
        AND s1.yearid=s2.yearid
    WHERE s2.teamid is NULL) as compute
WHERE teams.teamid=compute.teamid AND people.playerid=compute.playerid
ORDER BY teamid,teams.name,yearid,playerid,namefirst,namelast,salary DESC;

--9--
SELECT *
FROM  (SELECT 'batsman' as player_category,avg(salary) as avg_salary
    FROM((SELECT playerid,sum(salary)as salary
        FROM salaries
        GROUP BY playerid) as t1
        JOIN
        (SELECT DISTINCT playerid
        FROM batting) as t2
        USING (playerid)) as t3
    UNION
    SELECT 'pitcher' as player_category,avg(salary) as avg_salary
    FROM((SELECT playerid,sum(salary)as salary
        FROM salaries
        GROUP BY playerid) as t4
        JOIN
        (SELECT DISTINCT playerid
        FROM pitching) as t5
        USING (playerid)) as t6) as t7
ORDER BY avg_salary DESC
LIMIT 1;

--10--
drop view if exists fname;
CREATE VIEW fname AS
SELECT playerid,case 
    when namefirst is null and namelast is null then ''
    else coalesce(namefirst,'')||' '||coalesce(namelast,'')
    end as namefull
FROM people;

SELECT t1.playerid,fname.namefull as playername,t1.number_of_batchmates
FROM fname,
    (SELECT s1.playerid, count(*) as number_of_batchmates
    FROM collegeplaying s1
        JOIN collegeplaying s2 ON  
            s1.schoolid=s2.schoolid 
            AND s1.yearid=s2.yearid
            AND s1.playerid!=s2.playerid
    GROUP BY s1.playerid) as t1
WHERE t1.playerid=fname.playerid
ORDER BY number_of_batchmates DESC, t1.playerid;

--11--
SELECT teamid, name, count(*) as total_WS_wins
FROM teams
WHERE WSwin=TRUE and g>110
GROUP BY teamid,name
ORDER BY total_WS_wins DESC, teamid,name
LIMIT 5;

--12--
SELECT pid as playerid, namefirst,namelast, career_saves,num_seasons
FROM people join
    (   (SELECT playerID,count(*) as num_seasons
        FROM (SELECT DISTINCT playerid,yearid
            FROM pitching) as t1
        GROUP BY playerID
        HAVING count(*)>=15) as t2
    JOIN (SELECT playerID as pid,sum(sv) as career_saves
        FROM  pitching
        GROUP BY playerID) as t3
    ON pid =t2.playerid) as t4
ON t4.pid=people.playerid
ORDER BY career_saves DESC,num_seasons DESC,pid,namefirst,namelast
LIMIT 10;

--13--

--14--   
BEGIN;
INSERT INTO people(playerid,namefirst,namelast)
VALUES('dunphil02','Phil','Dunphy');
INSERT INTO people(playerid,namefirst,namelast)
VALUES('tuckcam01','Cameron','Tucker');
INSERT INTO people(playerid,namefirst,namelast)
VALUES('scottm02','Michael','Scott');
INSERT INTO people(playerid,namefirst,namelast)
VALUES('waltjoe','Joe','Walt');
COMMIT;

BEGIN;
INSERT INTO awardsplayers(awardid,playerid,lgid,yearid,tie)
VALUES ('Best Baseman','dunphil02','',2014,true);
INSERT INTO awardsplayers(awardid,playerid,lgid,yearid,tie)
VALUES ('Best Baseman','tuckcam01','',2014,true);
INSERT INTO awardsplayers(awardid,playerid,lgid,yearid,tie)
VALUES ('ALCS MVP','scottm02','AA',2015,false);
INSERT INTO awardsplayers(awardid,playerid,lgid,yearid,tie)
VALUES ('Triple Crown','waltjoe','',2016,null);
INSERT INTO awardsplayers(awardid,playerid,lgid,yearid,tie)
VALUES ('Gold Glove','adamswi01','',2017,false);
INSERT INTO awardsplayers(awardid,playerid,lgid,yearid,tie)
VALUES ('ALCS MVP','yostne01','',2017,null);
COMMIT;

SELECT awardid,playerid,namefirst,namelast,num_wins
FROM (SELECT awardid,playerid,namefirst,namelast,num_wins, RANK() OVER(PARTITION BY awardid ORDER BY num_wins DESC,playerid)as rnk
    FROM  (SELECT awardid,people.playerid,namefirst,namelast,count(*)as num_wins
        FROM awardsplayers join people on awardsplayers.playerid=people.playerid
        GROUP BY awardid,people.playerid,namefirst,namelast) as t1)as t2
WHERE rnk=1
ORDER BY awardid,num_wins DESC;

--15--
SELECT DISTINCT managers.teamid, name,managers.yearid as seasonid,managers.playerid as managerid,namefirst as managerfirstname,namelast as managerlastname
FROM managers,teams,people
WHERE managers.playerid=people.playerid AND managers.teamid=teams.teamid AND (inseason=0 or inseason=1)AND managers.yearid>=2000 AND managers.yearid<=2010 
ORDER BY  teamid, name,seasonid DESC,managerid, managerfirstname,managerlastname;

--16--
SELECT DISTINCT playerid,coalesce(schoolname,'') as colleges_name,total_awards
FROM schools right join
    (SELECT playerid,schoolid,total_awards,RANK() OVER(PARTITION BY playerid ORDER BY yearid)as rnk
    FROM 
        (SELECT playerid,count(*) as total_awards
        FROM awardsplayers
        GROUP BY playerid
        ORDER BY total_awards DESC,playerid
        LIMIT 10) AS t1
        LEFT JOIN
        collegeplaying
        using(playerid))as t2
    using(schoolid)
WHERE rnk=1
ORDER BY total_awards DESC,colleges_name,playerid;

--17--
SELECT playerid,namefirst,namelast, playerawardid, playerawardyear, managerawardid, managerawardyear
FROM people JOIN
    (SELECT DISTINCT *
    FROM (SELECT playerid,playerawardid,playerawardyear
        FROM (SELECT playerid,awardid as playerawardid, yearid as playerawardyear,RANK() OVER(PARTITION BY playerid ORDER BY yearid,awardid)as rnk
            FROM awardsplayers) as t1
        WHERE rnk=1) as t2
    JOIN
        (SELECT playerid,managerawardid,managerawardyear
        FROM (SELECT playerid,awardid as managerawardid, yearid as managerawardyear,RANK() OVER(PARTITION BY playerid ORDER BY yearid,awardid)as rnk
            FROM awardsmanagers) as t3
        WHERE rnk=1) as t4
    USING (playerid)) as t5
USING (playerid)
ORDER BY playerid,namefirst,namelast;

--18--
SELECT playerid, namefirst, namelast, num_honored_categories, seasonid
FROM people
    JOIN
    (SELECT *
    FROM  (SELECT playerid,min(yearid) as seasonid
        FROM allstarfull
        WHERE gp=1
        GROUP BY playerid)as t1
        JOIN
        (SELECT playerid, num_honored_categories
        FROM (SELECT playerid,count(DISTINCT category)as num_honored_categories
            FROM halloffame
            GROUP BY playerid
            ) as t1
        WHERE num_honored_categories>=2) as t2
        using(playerid)) as t3
    using(playerid)
ORDER BY num_honored_categories DESC ,playerid ,namefirst,namelast,seasonid;

--19--
SELECT playerid, namefirst,namelast,G_all, G_1b, G_2b, G_3b
FROM people 
    JOIN (SELECT playerid, sum(G_all) as G_all, sum(G_1b) as G_1b, sum(G_2b) as G_2b,sum(G_3b) as G_3b
        FROM appearances
        GROUP BY playerid) as t1
    USING (playerid)
WHERE (G_1b!=0 AND G_2b!=0 AND G_3b=0) OR (G_1b!=0 AND G_2b=0 AND G_3b!=0) OR (G_1b=0 AND G_2b!=0 AND G_3b!=0) OR (G_1b!=0 AND G_2b!=0 AND G_3b!=0)
ORDER BY  G_all DESC, playerid, namefirst,namelast, G_1b DESC, G_2b DESC,G_3b DESC;

--20--
SELECT DISTINCT t4.schoolid, schoolname,LOWER(schoolcity||' '||schoolstate)as schooladdr, t4.playerid, namefirst, namelast
FROM people,schools,(SELECT schoolid,playerid
    FROM collegeplaying JOIN
        (SELECT schoolid
        FROM (SELECT schoolid, count(*) as num_students
            FROM (SELECT DISTINCT schoolid,playerid
                FROM collegeplaying) as t1
            GROUP BY schoolid
            ORDER BY num_students DESC
            LIMIT 5) as t2) as t3
        USING (schoolid)) as t4
WHERE schools.schoolid=t4.schoolid AND t4.playerid=people.playerid
ORDER BY schoolid, schoolname, schooladdr,playerid,namefirst,namelast;

--21--
SELECT player1_id,player2_id,birthcity,birthstate,CASE 
    WHEN pitching is not NULL and batting is not NULL THEN 'both'
    WHEN pitching is NULL and batting is not NULL THEN 'batted'
    WHEN pitching is not NULL and batting is NULL THEN 'pitched'
    END AS role
FROM
    ((SELECT DISTINCT t1.playerid as player1_id,t2.playerid as player2_id,birthcity,birthstate
    FROM people t1 JOIN people t2 USING(birthcity,birthstate)
    WHERE t1.playerid!=t2.playerid)as subquery2
    LEFT JOIN
    (SELECT p1.playerid as player1_id,p2.playerid as player2_id,true as pitching
    FROM pitching p1 JOIN pitching p2 USING(teamid)
    WHERE p1.playerid!=p2.playerid)as subquery3
    USING(player1_id,player2_id))
    LEFT JOIN
    (SELECT  b1.playerid as player1_id,b2.playerid as player2_id,true as batting
    FROM batting b1 JOIN batting b2 USING(teamid)
    WHERE b1.playerid!=b2.playerid)as subquery
    USING(player1_id,player2_id);

--22--
SELECT awardid,yearid as seasonid, playerid,pointswon as playerpoints,averagepoints
FROM (SELECT awardid,yearid ,avg(pointswon) as averagepoints
    FROM awardsshareplayers
    GROUP BY awardid,yearid) as t1
    JOIN
    awardsshareplayers
    USING(awardid,yearid)
WHERE pointswon>=averagepoints
ORDER BY awardid,yearid,pointswon DESC, playerid;

--23--
SELECT playerid,namefull as playername,CASE
    WHEN deathday is NULL and deathyear is NULL and deathmonth is NULL THEN true
    ELSE false
    END as alive
FROM fname join ((people
    LEFT JOIN
    awardsmanagers
    USING(playerid))as t1
    LEFT JOIN
    awardsplayers ap
    USING(playerid)) using (playerid)
WHERE ap.awardid is NULL and t1.awardid is NULL
ORDER BY playerid,namefull;

--24--
drop view if exists g12_nodes;
CREATE VIEW g12_nodes AS
    SELECT DISTINCT playerid,teamid,yearid
    FROM pitching
    UNION
    SELECT playerid,teamid,yearid
    FROM allstarfull
    WHERE GP>0;

drop view if exists g12_edges;
CREATE VIEW g12_edges AS
SELECT p1,p2,count(*)as wt
FROM
    (SELECT t1.playerid as p1,teamid,yearid,t2.playerid as p2
    FROM g12_nodes t1 JOIN g12_nodes t2 USING(teamid,yearid)
    WHERE t1.playerid!=t2.playerid) as t3
GROUP BY p1,p2--check reversal
ORDER BY wt DESC;

WITH RECURSIVE rec_q1 (p1, p2, l,path) 
as
( 
  select p1, p2, wt as l,ARRAY[p1]::text[] as path
  from g12_edges
  where p1 = 'webbbr01' -- start node
  union all
  select g12_edges.p1, g12_edges.p2,prv.l +wt ,prv.path || g12_edges.p1::text--array_append(prv.path, g12_edges.p1)
  from g12_edges, rec_q1 prv
  where g12_edges.p1 = prv.p2
  and g12_edges.p1 != ALL(prv.path)
)
SELECT CASE 
    WHEN count(*)>0 THEN true
    ELSE false
    END AS pathexists
FROM 
    (select l--,array_append(path, p2::text),
    from rec_q1
    where p2 = 'clemero02')as t2 -- goal node;)
WHERE l>=3;

--25--
WITH RECURSIVE rec_q2 (p1, p2, l,path) 
as
( 
  select p1, p2, wt as l,ARRAY[p1]::text[] as path
  from g12_edges
  where p1 = 'garcifr02' -- start node
  union all
  select g12_edges.p1, g12_edges.p2,prv.l+wt ,prv.path || g12_edges.p1::text--array_append(prv.path, g12_edges.p1)
  from g12_edges, rec_q2 prv
  where g12_edges.p1 = prv.p2
  and g12_edges.p1 != ALL(prv.path)
)
select coalesce(min(l),0)as pathlength--,array_append(path, p2::text),
from rec_q2
where p2 = 'leagubr01'; -- goal node;

--26--
drop view if exists g2_edges;
CREATE VIEW g2_edges AS
SELECT DISTINCT teamidwinner as p1,teamidloser as p2
FROM seriespost;

WITH RECURSIVE rec_q3 (p1, p2, depth,path) 
as
( 
  select p1, p2,0,ARRAY[p1]::text[] as path
  from g2_edges
  where p1 = 'ARI' -- start node
  union all
  select g2_edges.p1, g2_edges.p2,prv.depth+1 ,prv.path || g2_edges.p1::text--array_append(prv.path, g2_edges.p1)
  from g2_edges, rec_q3 prv
  where g2_edges.p1 = prv.p2
  and g2_edges.p1 != ALL(prv.path)
)
select count(*) as count
from rec_q3
where p2 = 'DET'; -- goal node;

--27--
WITH RECURSIVE rec_q4 (p1, p2, depth,path) 
as
( 
  select p1, p2,0,ARRAY[p1]::text[] as path
  from g2_edges
  where p1 = 'HOU' -- start node
  union all
  select g2_edges.p1, g2_edges.p2,prv.depth+1 ,prv.path || g2_edges.p1::text--array_append(prv.path, g2_edges.p1)
  from g2_edges, rec_q4 prv
  where g2_edges.p1 = prv.p2
  and g2_edges.p1 != ALL(prv.path)
)
select p2 as teamid,max(depth)as num_hops--,array_append(path, p2::text),
from rec_q4
where depth!=0 and depth<=3
group by p2
order by teamid;

--28--
WITH RECURSIVE rec_q5 (p1, p2, depth,path) 
as
( 
  select p1, p2,0,ARRAY[p1]::text[] as path
  from g2_edges
  where p1 = 'WS1' -- start node
  union all
  select g2_edges.p1, g2_edges.p2,prv.depth+1 ,prv.path || g2_edges.p1::text--array_append(prv.path, g2_edges.p1)
  from g2_edges, rec_q5 prv
  where g2_edges.p1 = prv.p2
  and g2_edges.p1 != ALL(prv.path)
)
select teamid, name as teamname, pathlength
FROM (select p2 as teamid,depth as pathlength--,array_append(path, p2::text),
    from rec_q5
    where depth= (select max(depth) from rec_q5)) as table1
    JOIN
    teams
    USING(teamid)
ORDER BY teamid,teamname;

--29--
drop view if exists g3_edges;
CREATE VIEW g3_edges AS
SELECT DISTINCT teamidloser as p1,teamidwinner as p2
FROM seriespost;

WITH RECURSIVE rec_q7 (p1, p2, depth,path) 
as
( 
  select p1, p2,0,ARRAY[p1]::text[] as path
  from g3_edges
  where p1 = 'NYA' -- start node
  union all
  select g3_edges.p1, g3_edges.p2,prv.depth+1 ,prv.path || g3_edges.p1::text
  from g3_edges, rec_q7 prv
  where g3_edges.p1 = prv.p2
  and g3_edges.p1 != ALL(prv.path)
)

SELECT teamidwinner as teamid,min(depth) as pathlength
FROM rec_q7,
    (SELECT DISTINCT teamidwinner
    FROM seriespost
    WHERE ties>losses) as t1
WHERE rec_q7.p2=t1.teamidwinner
GROUP BY teamid
order by teamid,pathlength;
--30--
WITH RECURSIVE rec_q6 (p1, p2, depth,path,cycle) 
as
( 
  select p1, p2,0,ARRAY[p1]::text[] as path,false
  from g2_edges
  where p1 = 'DET' -- start node
  union all
  select g2_edges.p1, g2_edges.p2,prv.depth+1 ,prv.path || g2_edges.p1::text,g2_edges.p1=ANY(prv.path)
  from g2_edges, rec_q6 prv
  where g2_edges.p1 = prv.p2
  and g2_edges.p1 != ALL(prv.path)
)
SELECT max(depth)+1 as cyclelength,count(*) as numcycles
from rec_q6
where cycle=true
GROUP BY p2;
    