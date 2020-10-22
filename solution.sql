--------query 1-----------
create table query1 as
SELECT name as name,COUNT(name) as moviecount
FROM movies
NATURAL JOIN  hasagenre
NATURAL JOIN  genres
GROUP BY name;
---------query 2--------
create table query2 as 
select name as name ,avg(rating) as rating
from ratings
natural join hasagenre
natural join genres
group by name

----------query 3----------
create table query3 as
SELECT movies.title as title,  count(ratings.movieid) as countofratings
FROM movies
INNER JOIN ratings ON movies.movieid = ratings.movieid 
GROUP BY movies.title
HAVING count(ratings.movieid) >= 10

------------query4------------
create table query4 as
select movieid,title
from movies
where movieid in (select hasagenre.movieid
from hasagenre
inner join genres on hasagenre.genreid=genres.genreid
 where name='Comedy')
--------------query5-------------

SELECT MOVIEID, AVG(RATING) INTO TEMP_MOVIES_WITH_RATINGS
FROM RATINGS
GROUP BY MOVIEID;
CREATE TABLE QUERY5(TITLE, AVERAGE) AS
SELECT TITLE, AVG FROM MOVIES
INNER JOIN TEMP_MOVIES_WITH_RATINGS ON TEMP_MOVIES_WITH_RATINGS.MOVIEID = MOVIES.MOVIEID;

---------query6---------------

create table query6 as
select avg(rating.rating)
from ratings
where movieid in (select hasagenre.movieid
from hasagenre
inner join genres on hasagenre.genreid=genres.genreid
where genres.name='Comedy')

----------query7-----------
create table query7 as
Select avg(rating)
FROM ratings R,hasagenre H1,hasagenre H2,genres G1,genres G2
WHERE R.movieid=H1.movieid AND H1.genreid=G1.genreid
AND  R.movieid=H2.movieid AND H2.genreid=G2.genreid
AND (G2.name = 'Comedy' AND G1.name = 'Romance'); 

-----------qery 8--------------

CREATE TABLE query8 AS
SELECT avg(ratings.rating) AS average
FROM movies, hasagenre, genres, ratings
WHERE movies.movieid = hasagenre.movieid
AND hasagenre.genreid = genres.genreid
AND ratings.movieid = movies.movieid
AND genres.name = 'Romance'
AND movies.movieid NOT IN
(
SELECT movies.movieid
FROM movies, hasagenre, genres
WHERE movies.movieid = hasagenre.movieid
AND hasagenre.genreid = genres.genreid
AND genres.name = 'Comedy'
);
-------query9---------
Create table query9 as 
select movieid as movieid, rating as rating
from ratings
where userid = :v1

-----------recommendation table---

---- query 10---------------
CREATE TABLE usermovie AS
SELECT r.movieid, r.rating
FROM ratings r
WHERE r.userid = :v1;

CREATE TABLE query10 AS
SELECT movieid, avg(rating) AS rating
FROM ratings
GROUP BY movieid;

-- Create movie to movie similarity table. Each row has two movies and a similarity
CREATE TABLE movie2movie AS
SELECT q1.movieid as movieid1, q2.movieid as movieid2, (1-(abs(q1.rating - q2.rating)/5)) as sim
FROM query10 q1, query10 q2
WHERE q1.movieid!=q2.movieid;

-- Generate predictions using weighted table
CREATE TABLE prediction AS
SELECT m.movieid1 as candidate,
  CASE SUM(m.sim) WHEN 0.0 THEN 0.0
                  ELSE SUM(m.sim*u.rating)/SUM(m.sim)
  END
AS predictionscore
FROM movie2movie m, usermovie u
WHERE m.movieid2 = u.movieid
AND m.movieid1 NOT IN (SELECT movieid FROM usermovie)
GROUP BY m.movieid1 ORDER BY predictionscore DESC;

-- Generate recommendations using prediction scores
CREATE TABLE recommendation AS
SELECT title
FROM movies, prediction
WHERE movies.movieid = prediction.candidate
AND prediction.predictionscore>3.9;
