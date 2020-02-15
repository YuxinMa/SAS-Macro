/*---------------------------------------
   Date:  Oct/22/2017
   Author:  Yuxin Ma
   - Relate the datasets to each other and creat a dataset with variables we want,
     including creat an indicator variable to a specific disease
   - Plot the distributions of the disease
----------------------------------------*/

/*define the path name*/
%let pathname=\\Client\C$\Users\ym\Desktop\SAS&R\HW\Assignment 6\Assignment 6 Data\;

/*Import the 4 datasets*/
proc import datafile="&pathname.MainPatientFile.csv" DBMS=csv out=main replace;
run;
proc import datafile="&pathname.CohortCrosswalk.csv" DBMS=csv out=cohort_cw replace;
run;
proc import datafile="&pathname.ODiagnosisCrosswalk.csv" DBMS=csv out=od_cw replace;
run;
proc import datafile="&pathname.OutpatientVisits.csv" DBMS=csv out=op_visit replace;
run;

/*Substitute the diagnosis code by the diagnosis name in the OutpatientVisits dataset*/
PROC SQL; CREATE TABLE demo_1 AS 
     SELECT a.siteID,a.visitdate,b.diagnosis 
     FROM op_visit AS a LEFT JOIN od_cw AS b 
     ON a.diagnosis_code=b.diagnosis_code; 
QUIT;   

/*Merge the MainPatientFile, the CohortCrosswalk and the OutpatientVisits (already substituted one)*/
PROC SQL; 
   CREATE TABLE demo_2 AS 
   SELECT b.siteID,b.month_birth,b.day_birth,b.year_birth,b.sex,b.race,b.marital_status,
          b.income_bracket,b.record_month,b.record_day,b.record_year, 
          a.visitdate, a.diagnosis,c.uniqueID 
   FROM main AS b FULL JOIN demo_1 AS a on b.siteID=a.siteID
      FULL JOIN cohort_cw AS c ON b.siteID=c.siteID; 
QUIT; 

/*Select those with disease A1 prior to 2015*/
PROC SQL; 
  CREATE TABLE demo_3 AS 
  SELECT * 
  FROM demo_2 WHERE diagnosis IN("A1","A1.1","A1.2","A1.3","A1.4","A1.5","A1.6") 
                    AND visitdate< mdy(1,1,2015); 
QUIT; 

/*count the times that each individual has outpatient diagnoses of A1*/
PROC SQL; 
  CREATE TABLE demo_4 AS  
  SELECT uniqueID, count(diagnosis) AS N 
  FROM demo_3 
     GROUP BY uniqueID; 
QUIT;  

/*Sort the data by uniqueID as well as the record_date, inorder to update the data for each 
  uniqueID with the newest date of record*/
proc sort data=demo_2; 
  by uniqueID record_year record_month record_day; 
run;  
/*Update the data*/
data demo_5; update demo_4 demo_2; 
  by uniqueID; 
run; 
proc sort data=demo_5; 
  by uniqueID; 
run;  

/*Call for the format*/
options fmtsearch=(work.format);

/*
  1. With the defination, we give a positive indicator only to those who have at least two 
     independent outpatient diagnoses of the A1 
  2. Combine the birth day, month and year in order to get the birthdate
  3. Calculate the age
  4. keep the variables we want
  5. Applu formats to the variables
  6. Creat label to specify some variables
*/
data demo_6;set demo_5;  
  if N>1 then A1_dx=1; else A1_dx=0; 
  birthdate=mdy(month_birth,day_birth,year_birth); 
  age=round((mdy(record_month,record_day,record_year)-mdy(month_birth,day_birth,year_birth))/365.25, 1.0); 
  keep UniqueID Sex birthdate race marital_status income_bracket age A1_dx; 
  format Sex sex. birthdate mmddyy10. race rac. marital_status mar. income_bracket inc. A1_dx adx.;
  label birthdate="Birth Date"; 
  label marital_status="Marital Status"; 
  label income_bracket="Income"; 
run;  

/*change the order of the variables to the order we want*/
data demo; 
  retain UniqueID sex birthdate race marital_status income_bracket age A1_dx;
  set demo_6;
run;

/*Sort the dataset by the uniqueID and display the first 10 observations*/
proc sort data=demo; 
by uniqueID; 
run; 
title"First 10 Observations of Dataset Demo"; 
proc print data=demo(obs=10) label; 
run; 

/*Create plots of the distribution of chronic condition A1, by sex, by race,
  and by marital status, separately*/
title"Distribution of Chronic Condition A1 by Sex"; 
proc sgplot data=demo;
vbar A1_dx/group=sex groupdisplay = cluster; 
run;  

title"Distribution of Chronic Condition A1 by Race"; 
proc sgplot data=demo;
vbar A1_dx/group=race groupdisplay = cluster; 
run;  
 
title"Distribution of Chronic Condition A1 by Marital Status"; 
proc sgplot data=demo;
vbar A1_dx/group=marital_status groupdisplay = cluster; 
run;  


