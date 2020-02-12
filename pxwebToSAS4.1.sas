/****************************************
Program: pxwebToSAS4
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
***********************************/


proc ds2;
	package work.pxWebToSAS4 / overwrite=yes;
		declare package work.pxweb_UppdateTableDate SCB_Date();

		forward getDataStart;
		method pxwebtosas4();

		end;
		method getData(varchar(500) inUrl);
			getDataStart(inUrl);
		end;

		method getDataStart(varchar(500) iUrl);
			declare char(19) tableUpdated;

			tableUpdated=SCB_Date.getSCBDate(iUrl);
*put 'pxWebToSAS4: ' tableUpdated;
		end;

	endpackage ;
run;quit;
/*
2019-03-21T09:30:00
*/