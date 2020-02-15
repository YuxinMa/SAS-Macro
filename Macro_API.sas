/* Define the name of the Access dataset and the table we need */
%Let database = S:\*****\TN_Member_Quest_Geocleaned.accdb;
%Let table = TN_Member;

/* Import the Access dataset */
proc import table="&table."
			 out=work.Mem_Clean
			 dbms=access repalce;
	database="&database.";
run;

/* Transfer the form of ZIP code from character to numeric (what we need in the geocode step) */
data Mem_Clean; set Mem_Clean;
STD_Zip_num = input(STD_Zip, 8.);
run;

proc sql;
select count(distinct recipid) as idn
from Mem_Clean;
run;
quit;

data _NULL_;
	 if 0 then set Mem_clean nobs=n;
	 call symputx('nobs',n);
	 stop;
run;

%put &nobs.;

proc freq data = mem_clean;
tables STD_ZIP;
run;

option nonotes;

/* Macro to Geocode data by specified variable */
%macro Geocode(dataset = );
*Create datasets to append latitudes and longitudes;
data API_Geocode;
run;
*Acquire the number of observations;
data _NULL_;
	 if 0 then set &dataset. nobs=n;
	 call symputx('nobs',n);
	 stop;
run;
*Create loop to access each observation;
%do i=1 %to &nobs.;
*Assign macro variable needed;
data _null_;
set &dataset.;
if _n_=&i then do;
 call symput('add',translate(catx(',',STD_Address,STD_City,catx(' ',STD_state,STD_Zip)),'+',' '));
 call symput('STD_Address',STD_Address);
 call symput('STD_City',STD_City);
 call symput('STD_State',STD_State);
 call symput('STD_Zip',STD_Zip);
 call symput('Recipid',recipid);
end;
run;

/*%put &STD_Address;*/

/*Find Lattitude and longitude in sitecode*/
*Define Google Maps url with starting addresses;
filename gmaps url "https://maps.google.com/maps?daddr=&add";
*Define sitecode as 1000 character parts of location html for starting address;
data Geocode&i. (drop=sitecode market);
infile gmaps recfm=f lrecl=1000 end=eof;
input sitecode $1000.;
*Find text proceeding latitude and longitude in html code for starting address;
if find(sitecode,'",[null,null,') then do;
*Assign variable to starting location of proceeding text for starting address;
markst=find(sitecode,'",[null,null,');
*Scan substring starting with proceeding text for starting address latitude and longitude;
lat=input(scan(substr(sitecode,markst),4,",]"),best12.);
long=input(scan(substr(sitecode,markst),5,",]"),best12.);
length STD_Address STD_City STD_State STD_Zip $200.;
format STD_Address STD_City STD_State STD_Zip $200.;
STD_Address="&STD_Address";
STD_City="&STD_City";
STD_State="&STD_State";
STD_Zip="&STD_Zip";
Recipid="&Recipid";
Match_status="Address Match";
output;
end;
run;

/*Use zip math if the above doesn't work*/
data _NULL_;
	 if 0 then set Geocode&i. nobs=n;
	 call symputx('ind',n);
	 stop;
run;

%if &ind.=0 or &ind.>1 %then %do;

filename gmaps url "http://maps.google.com/maps?daddr=&STD_Zip";
*Define sitecode as 1000 character parts of location html for starting address;
data Geocode&i. (drop=sitecode markst);
infile gmaps recfm=f lrecl=1000 end=eof;
input sitecode $1000.;
*Find text proceeding latitude and longitude in html code for starting address;
if find(sitecode,'",[null,null,') then do;
*Assign variable to starting location of proceeding text for starting address;
markst=find(sitecode,'",[null,null,');
*Scan substring starting with proceeding text for starting address latitude and longitude;
 lat=input(scan(substr(sitecode,markst),4,",]"),best12.);
 long=input(scan(substr(sitecode,markst),5,",]"),best12.);
 length STD_Address STD_City STD_State STD_Zip $200.;
 format STD_Address STD_City STD_State STD_Zip $200.;
 STD_Address="&STD_Address";
 STD_City="&STD_City";
 STD_State="&STD_State";
 STD_Zip="&STD_Zip";
 Recipid="&Recipid";
 Match_status="Address Match";
 output;
end;
run;

%end;

/*Use City or State math if the above doesn't work*/
data _NULL_;
	 if 0 then set Geocode&i. nobs=n;
	 call symputx('ind',n);
	 stop;
run;

%if &ind.=0 or &ind.>1 %then %do;

filename gmaps url
"http://maps.google.com/maps?daddr=&STD_City.,+&State.";
*Define sitecode as 1000 character parts of location html for starting address;
data Geocode&i. (drop=sitecode markst);
infile gmaps recfm=f lrecl=1000 end=eof;
input sitecode $1000.;
*Find text proceeding latitude and longitude in html code for starting address;
if find(sitecode,'",[null,null,') then do;
*Assign variable to starting location of proceeding text for starting address;
markst=find(sitecode,'",[null,null,');
*Scan substring starting with proceeding text for starting address latitude and longitude;
 lat=input(scan(substr(sitecode,markst),4,",]"),best12.);
 long=input(scan(substr(sitecode,markst),5,",]"),best12.);
 length STD_Address STD_City STD_State STD_Zip $200.;
 format STD_Address STD_City STD_State STD_Zip $200.;
 STD_Address="&STD_Address";
 STD_City="&STD_City";
 STD_State="&STD_State";
 STD_Zip="&STD_Zip";
 Recipid="&Recipid";
 Match_status="City/State Match";
 output;
end;
run;

%end;

*Append observation to dataset of starting address lat/long;
data API_Geocode;
 set API_Geocode
Geocode&i.;
if lat^=.;
 label lat="Latitude"
 long="Longitude";
run;

proc datasets library=work noprint;
   delete Geocode&i.;
run;
quit;
*Disassociate current assigned gmaps;
filename gmaps clear;
%end;
%mend;

%Geocode(dataset = work.Mem_Clean)

/*proc freq data = Mem_Clean;*/
/*tables STD_Zip_num;*/
/*run;*/

%Let pathname = S:\****\;

libname save "&pathname.";

data save.TN_Mem_API; set Work.API_Geocode;
run;
