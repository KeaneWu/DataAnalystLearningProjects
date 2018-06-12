create database if not exists college;
use college;

-- Drop Tables if it exists
DROP TABLE tuition;
DROP TABLE institution;
DROP TABLE temp_tuition;
DROP TABLE temp_change;
DROP TABLE sector;

CREATE TABLE IF NOT EXISTS sector (
 sectorid INT NOT NULL,
 sectorname VARCHAR(50),
 PRIMARY KEY (sectorid)
);

INSERT INTO sector (sectorid, sectorname) VALUES (1, "4-year, public");
INSERT INTO sector (sectorid, sectorname) VALUES (2, "4-year, private not-for-profit");
INSERT INTO sector (sectorid, sectorname) VALUES (3, "4-year, private for-profit ");
INSERT INTO sector (sectorid, sectorname) VALUES (4, "2-year, public");
INSERT INTO sector (sectorid, sectorname) VALUES (5, "2-year, private not-for-profit");
INSERT INTO sector (sectorid, sectorname) VALUES (6, "2-year, private for-profit");
INSERT INTO sector (sectorid, sectorname) VALUES (7, "Less than 2-year, public");
INSERT INTO sector (sectorid, sectorname) VALUES (8, "Less than 2-year, private not-for-profit");
INSERT INTO sector (sectorid, sectorname) VALUES (9,"Less than 2-year, private for-profit");

CREATE TABLE institution (
 sectorid INT NOT NULL,
 unitid INT NOT NULL,
 year INT NOT NULL,
 opeid VARCHAR(10), 
 name VARCHAR(100) NOT NULL,
 state CHAR(2) NOT NULL,
 calendar VARCHAR(12),
PRIMARY KEY (unitid, year),
FOREIGN KEY (sectorid) REFERENCES sector(sectorid)
);

CREATE TABLE tuition (
 unitid INT NOT NULL,
 year INT NOT NULL,
 tuition NUMERIC(8,2),
 netprice NUMERIC(8,2),
 pct NUMERIC(5,2),
 PRIMARY KEY (unitid, year),
 FOREIGN KEY (unitid) REFERENCES institution(unitid)
);


-- create temp tables for importing data
-- tuition+netprice, tchange+nchange
CREATE TABLE  temp_tuition (
 sectorid INT,
 unitid INT,
 opeid VARCHAR(8),
 name VARCHAR(100), 
 state CHAR(2),
 cost NUMERIC(8,2),
 pct NUMERIC(5,2)
);

CREATE TABLE temp_change(
 sectorid INT,
 unitid INT,
 opeid VARCHAR(8),
 name VARCHAR(100), 
 state CHAR(2),
 calendar VARCHAR(12),
 cost1 NUMERIC(8,2),
 cost2 NUMERIC(8,2)
);

-- import data one year at a time; insert the imported data, then delete the data for next import.
LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/tuition2011.csv' 
INTO TABLE temp_tuition 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'  
IGNORE 1 LINES 
(sectorid,unitid,opeid,name,state,@cost,@ignore,@ignore)
SET cost = nullif(@cost, ' ');
-- note, \r, not \n because of Excel!
-- result:
-- Query OK, 4260 rows affected, 17039 warnings (0.02 sec)
-- Records: 4260  Deleted: 0  Skipped: 0  Warnings: 8519

LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/tuitionchange2011.csv' 
INTO TABLE temp_change FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'  
IGNORE 1 LINES 
(sectorid,unitid,opeid,name,state,calendar,cost1,cost2,@ignore,@ignore);
-- results:
-- Query OK, 6822 rows affected, 160 warnings (0.10 sec)
-- Records: 6822  Deleted: 0  Skipped: 0  Warnings: 0

INSERT INTO institution (sectorid ,unitid,year,opeid, name,state,calendar) SELECT sectorid, unitid, 2011, opeid, name, state,calendar FROM temp_change;
--
-- query OK, 6822 rows affected (0.09 sec)
-- Records: 6822  Duplicates: 0  Warnings: 0

select count(*) from institution i inner join temp_tuition t on i.unitid=t.unitid;
-- 4257, so three records in tuition are not included.
select i.unitid from temp_tuition i where i.unitid not in (select unitid from institution);

 -- the following query add the three institutions. 
INSERT IGNORE INTO institution (sectorid ,unitid,year,opeid, name,state ) SELECT sectorid, unitid, 2011, opeid, name, state FROM temp_tuition;
-- Query OK, 3 rows affected (0.02 sec)
-- Records: 4260  Duplicates: 4257  Warnings: 0

-- NOW, insert the tuition data into tuition table.
INSERT INTO tuition (unitid,year,tuition) SELECT unitid,2011,cost FROM temp_tuition;

-- the following query verifies that cost2 matches tuition data in tuition
select t.unitid, i.name, t.tuition, c.cost2 from tuition t, institution i, temp_change c where t.unitid=i.unitid and t.unitid=c.unitid limit 10;

-- temp_change has 2009 tuition, let us add that into tuition table
INSERT INTO tuition (unitid,year,tuition) SELECT unitid,2009,cost1 FROM temp_change;
--
-- Query OK, 6822 rows affected (0.08 sec)
-- Records: 6822  Duplicates: 0  Warnings: 0

-- now we can delete data in temp tables and load 2010 tuition data
delete from temp_tuition;
delete from temp_change;

LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/Catclists2010.csv' 
INTO TABLE temp_tuition 
FIELDS TERMINATED BY ','
 LINES TERMINATED BY '\n'
 IGNORE 1 LINES 
(sectorid,unitid,opeid,name,state,@cost,@ignore,@ignore)
SET cost = nullif(@cost, ' ');
-- Query OK, 4165 rows affected, 36 warnings (0.19 sec)
-- Records: 4165  Deleted: 0  Skipped: 0  Warnings: 35

LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/Catclists2010tuitionchange.csv' 
INTO TABLE temp_change 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES
 (sectorid,unitid,opeid,name,state,calendar,@cost1,@cost2,@ignore,@ignore)
SET cost1 = nullif(@cost1, ' '),
cost2 = nullif(@cost2, ' ');
-- Query OK, 6631 rows affected, 6842 warnings (0.14 sec)
-- Records: 6631  Deleted: 0  Skipped: 0  Warnings: 69

INSERT INTO institution (sectorid ,unitid,year,opeid, name,state,calendar)
 SELECT sectorid, unitid, 2010, opeid, name, state,calendar FROM temp_change;

select count(*) from institution i inner join temp_tuition t on i.unitid=t.unitid and year=2010;
-- 4162, less than 4165 in temp_tuition. 
select i.unitid from temp_tuition i where i.unitid not in (select unitid from institution where year=2010);
-- !!! the same three insituions:
select * from institution where unitid in (216551,417275,419031);

INSERT IGNORE INTO institution (sectorid ,unitid,year,opeid, name,state ) SELECT sectorid, unitid, 2010, opeid, name, state FROM temp_tuition;

INSERT INTO tuition (unitid,year,tuition) SELECT unitid,2010,cost FROM temp_tuition;
INSERT INTO tuition (unitid,year,tuition) SELECT unitid,2008,cost1 FROM temp_change;


-- finally, time to process netprice -----------
-- delete records in temp tables
LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/netprice2011.csv' 
 INTO TABLE temp_tuition 
 FIELDS TERMINATED BY ',' 
 LINES TERMINATED BY '\n'  
 IGNORE 1 LINES 
 (sectorid,unitid,opeid,name,state,cost,pct,@ignore,@ignore);
-- very OK, 4260 rows affected, 187 warnings (0.09 sec)
-- Records: 4260  Deleted: 0  Skipped: 0  Warnings: 0
LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/netpricechange2011.csv' 
INTO TABLE temp_change 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'  
IGNORE 1 LINES 
(sectorid,unitid,opeid,name,state,calendar,cost1,cost2,@ignore,@ignore);
-- Query OK, 6822 rows affected, 909 warnings (0.05 sec)
-- Records: 6822  Deleted: 0  Skipped: 0  Warnings: 0

-- the institutions in temp_change (2010) should be the same as institution’s 2011
select i.sectorid, i.name, i.unitid, c.sectorid, c.name from institution i, temp_change c where i.year=2011 and i.unitid=c.unitid and (i.sectorid != c.sectorid or i.name !=c.name);
-- empty set 
select count(*) from institution i, temp_change c where i.year=2011 and i.unitid=c.unitid;
-- 6822 

-- t11, n10 t09, n08
-- t10 n09 t08 n07
-- So, for tuition:  08 09 10 11
-- for netprice: 07 08 09 10

UPDATE tuition t JOIN temp_tuition  tm ON t.unitid = tm.unitid AND t.year=2010 set t.netprice= tm.cost, t.pct=tm.pct;
-- Query OK, 4103 rows affected (0.04 sec)
-- Rows matched: 4103  Changed: 4103  Warnings: 0
-- there should be 4260 records…
select t.unitid from tuition t where t.year=2010 and t.unitid not in (select unitid from temp_tuition);
-- 62

-- list the instituition;
select t.unitid, i.name, i.sectorid from tuition t join institution i on t.unitid=i.unitid and i.year=2010 and t.year=2010 and t.unitid not in (select unitid from temp_tuition);

select t.unitid from tuition t where t.year=2010 and t.unitid not in (select unitid from temp_tuition);
-- 62
select unitid from temp_tuition where unitid not in (select t.unitid from tuition t where t.year=2010);
-- 157
select unitid from temp_tuition where cost is not null and unitid not in (select t.unitid from tuition t where t.year=2010);

-- not good!!! Turned everything null
LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/netprice2011.csv' 
INTO TABLE temp_tuition FIELDS TERMINATED BY ',' ESCAPED BY ',' 
LINES TERMINATED BY '\n' IGNORE 1 LINES 
(sectorid,unitid,opeid,name,state,cost,pct,@ignore,@ignore);

-- all empty files are not turned into 0.0. 

select unitid from temp_tuition where (cost !=0 or pct!=0) and unitid not in (select t.unitid from tuition t where t.year=2010);
-- there are 100 that can be inserted into tuition table; they have nectprice but not tuition
INSERT INTO TUITION (unitid, year, netprice, pct) 
SELECT unitid, 2010, cost, pct from temp_tuition where (cost !=0 or pct!=0) and unitid not in (select t.unitid from tuition t where t.year=2010);
-- Query OK, 100 rows affected (0.01 sec)
-- Records: 100  Duplicates: 0  Warnings: 0

-- verify the 2010’s netprice in change tab is the same netprice tab.
select t.year, t.unitid, i.name, t.netprice, c.cost2 from tuition t, institution i, temp_change c 
where t.year=2010 and t.unitid=i.unitid and t.unitid=c.unitid and i.year=2010 limit 10;

UPDATE tuition t JOIN temp_change  tm ON t.unitid = tm.unitid 
AND t.year=2008 set t.netprice= tm.cost1; -- pct is messing for 07 and 08
-- Query OK, 6522 rows affected (0.12 sec)
-- Rows matched: 6522  Changed: 6522  Warnings: 0

INSERT INTO TUITION (unitid, year, netprice) 
SELECT unitid, 2008, cost1 from temp_change 
where (cost1 !=0) and unitid not in (select t.unitid from tuition t where t.year=2008);
-- Query OK, 49 rows affected (0.02 sec)
-- Records: 49  Duplicates: 0  Warnings: 0

LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/Catclists2010NetPrice.csv' 
INTO TABLE temp_tuition FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'  
IGNORE 1 LINES (sectorid,@ignore,unitid,opeid,name,state,cost,pct,@ignore,@ignore);
-- Query OK, 4165 rows affected, 237 warnings (0.06 sec)
-- Records: 4165  Deleted: 0  Skipped: 0  Warnings: 35
-- Catclists2010NetPriceChange.csv
LOAD DATA LOCAL INFILE '/Users/wuzirong/Documents/UMLMSBA/DataQuality/Project/Catclists2010NetPriceChange.csv' 
INTO TABLE temp_change FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'  
IGNORE 1 LINES (sectorid,unitid,opeid,name,state,calendar,cost1,cost2,@ignore,@ignore);
-- Query OK, 6631 rows affected, 1024 warnings (0.02 sec)
-- Records: 6631  Deleted: 0  Skipped: 0  Warnings: 69

UPDATE tuition t JOIN temp_tuition  tm ON t.unitid = tm.unitid AND t.year=2009 set t.netprice= tm.cost, t.pct=tm.pct;
-- Query OK, 4120 rows affected (0.05 sec)
-- Rows matched: 4120  Changed: 4120  Warnings: 0

-- add more 2009 data to tuition table
INSERT IGNORE INTO TUITION (unitid, year, netprice, pct) 
SELECT unitid, 2009, cost, pct from temp_tuition where (cost !=0 or pct!=0) 
and 
unitid not in (select t.unitid from tuition t where t.year=2009);
-- Query OK, 29 rows affected (0.02 sec)
-- Records: 29  Duplicates: 0  Warnings: 0



INSERT IGNORE INTO TUITION (unitid, year, netprice) SELECT unitid, 2007, cost1 from temp_change where (cost1 !=0) ;
-- Query OK, 5864 rows affected (0.02 sec)
-- Records: 5864  Duplicates: 0  Warnings: 0

-- set some 0’s to null
update  tuition set tuition=null where tuition=0;
-- Query OK, 316 rows affected (0.00 sec)
-- Rows matched: 316  Changed: 316  Warnings: 0

update  tuition set netprice=null where netprice=0;
-- Query OK, 652 rows affected (0.01 sec)
-- Rows matched: 652  Changed: 652  Warnings: 0

drop table temp_change;
drop table temp_tuition;
drop table tuition2;

SELECT COUNT(*) FROM tuition;