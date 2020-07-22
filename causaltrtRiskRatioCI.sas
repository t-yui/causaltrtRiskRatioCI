/*
======================================================================

AUTHOR : Yui Tomo
LAST UPDATE : 2019.08.30
MACRONAME : causaltrtRiskRatioCI
SAS VERSION : 9.4
DESCRIPTION : calculate confidence interval of risk ratio from the result dataset of causaltrt procedure
REFERENCE : https://www.sas.com/content/dam/SAS/ja_jp/doc/event/sas-user-groups/usergroups2017-a-04.pdf

======================================================================

Copyright (c) 2019 Yui Tomo

This software is released under the MIT License.
http://opensource.org/licenses/mit-license.php

======================================================================
*/


%macro causaltrtRiskRatioCI(outdata_causaltrt, column_no, outdata_result, alpha=0.05);
	/*
	parameters
	----------
	outdata_causaltrt : dataset
		Specify CausalEffects dataset from CAUSALTRT procedure.
	column_no : integer
		Specify column number of standard error to be used.
	outdata_result : dataset
		Specify name of dataset to be output.
	alpha : float
		Specify significance level.
	*/
	proc iml;
		/* get estimates and btstd */
		use &outdata_causaltrt.;
		read all into data;
		risk_pom1 = data[1,1];
		risk_pom0 = data[2,1];
		std_pom1 = data[1,&column_no.];
		std_pom0 = data[2,&column_no.];
		std_diff = data[3,&column_no.];
		
		/* calculate var and covar */
		var_pom1 = std_pom1 ** 2;
		var_pom0 = std_pom0 ** 2;
		var_diff = std_diff ** 2;
		covar = (var_pom1 + var_pom0 - var_diff) / 2;
		
		/* calculate var of risk ratio using delta method */
		var_ratio = 0;
		var_ratio = var_ratio + var_pom1 / (risk_pom1 ** 2);
		var_ratio = var_ratio + var_pom0 / (risk_pom0 ** 2);
		var_ratio = var_ratio - 2 * covar / (risk_pom1 * risk_pom0);
		var_ratio = var_ratio * ((risk_pom1 / risk_pom0) ** 2);
		
		/* calculate 95%CI */
		risk_ratio = risk_pom1 / risk_pom0;
		alpha = &alpha.;
		percent = 1 - alpha / 2;
		percentile = quantile("normal", percent);
		low_ci = risk_ratio - percentile * sqrt(var_ratio);
		up_ci = risk_ratio + percentile * sqrt(var_ratio);
		
		/* output */
		print
			risk_pom1
			risk_pom0
			risk_ratio
			var_pom1
			var_pom0
			var_ratio
			low_ci
			up_ci
		;
		
		/* output as dataset*/
		create &outdata_result. 
			var {
				risk_pom1
				risk_pom0
				risk_ratio
				var_pom1
				var_pom0
				var_ratio
				low_ci
				up_ci
			};
		append;
		close &outdata_result.;
	quit;
%mend;
