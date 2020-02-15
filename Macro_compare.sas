

/************************************************************************************************
Macro name:		tests

Purpose:		read in data set, comparing whether there is a statistical difference in two 
                groups for variables of interest. If the variables of interest are continuous 
                (and the sample size is large), t-test is used to compare the two groups. If 
                the variables of interest are categorical (and the sample size is large), 
                chi-square test is used to compare the two groups. 

Author:			Yuxin Ma

Creation Date:  October 10, 2017
	
Revision Date:  

SAS version:	9.4

Required 
Parameters:		pathname=the path in where the data is stored 
                filename= the name of the file with its extension name
                groupby=the variable help us seperate the data into 2 groups
                varlist=the list of variables of interest
                testlist=the list of test method apply to the corresponding variables (the first
                         method is for the first variable, the second is for the second one,...)
                         0 = Apply the t-test
					     1 = Apply the chi-square test		 

Optional 
Parameters:		

Sub-macros called: 

%tests (pathname=D:\SAS&R\HW\Assignment 5\,
        filename=Berkeley Guidance Data.txt, groupby=sex, varlist=HT2 HT9 SOMA,
        testlist=0 0 1)
		
************************************************************************************************/

%macro tests (pathname=, filename=, groupby=, varlist=, testlist=);
/*Import the data*/
PROC IMPORT OUT= WORK.equaltest
            DATAFILE= "&pathname&filename." 
            DBMS=csv REPLACE;
     GETNAMES=YES;
     DATAROW=2;  
RUN;

  %let i = 1;
  /*Scan until there is no data*/
  %do %until (%scan(&varlist, &i)=);
    /*Acquire the variable and test method from the local input*/
    %let variable=%scan(&varlist,&i);
    %let test=%scan(&testlist,&i);
    /*Choose the method as the user dictated*/
	%if &test=0 %then %do;
	  %let method=T-test;
	  title "&method outcome for &variable";
      PROC TTEST DATA=equaltest plots=none;
      CLASS &groupby;  
      VAR &variable; 
      RUN;
    %end;
    %else %if &test=1 %then %do;
	  %let method=Chi-square test;
	  title "&method outcome for &variable";
      proc freq data=equaltest;
      tables &groupby.*&variable./chisq;
      run;
    %end;
	/*If the input value of the method is not an correct one, output ERROR in the Log*/
	%else %do;
      %put ERROR: &test is not a valid value for test method;
	%end;
	%let i=%eval(&i+1); 
 %end;
%mend tests;

/*
  Test the equality of HT2 and HT9 by gender using t-test; 
  Test the equality of SOMA by gender using chi-square test
*/
    
%tests (pathname=\\Client\C$\Users\ym\Desktop\SAS&R\HW\Assignment 5\,
        filename=Berkeley Guidance Data.txt, groupby=sex, varlist=HT2 HT9 SOMA,
        testlist=0 0 1)

/* Test the equality of SOMA by gender using chi-square test*/
%tests (pathname=\\Client\C$\Users\ym\Desktop\SAS&R\HW\Assignment 5\,
        filename=Berkeley Guidance Data.txt, groupby=sex, varlist=SOMA,
        testlist=1)

/*Test the equality of WT2 WT9 and WT18 by gender using t-test*/
%tests (pathname=\\Client\C$\Users\ym\Desktop\SAS&R\HW\Assignment 5\,
        filename=Berkeley Guidance Data.txt, groupby=sex, varlist=WT2 WT9 WT18,
        testlist=0 0 0)
