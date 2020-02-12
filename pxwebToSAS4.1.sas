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
			declare varchar(23) SASTabell;

			SASTabell=scan(inUrl, -1, '/');
			getDataStart(inUrl, 'work', SASTabell);
		end;

		method getData(varchar(500) inUrl, varchar(8) SASLib, varchar(32) SASTabell);
			getDataStart(inUrl, SASLib, SASTabell);
		end;

		method getDataStart(varchar(500) iUrl, varchar(8) SASLib, varchar(32) SASTabell);
			declare double tableUpdated dbUpdate;
			declare varchar(41) fullTabellNamn;
			fullTabellNamn=SASLib || '.' || SASTabell;
			tableUpdated=SCB_Date.getSCBDate(iUrl);
			dbUpdate=SCB_Date.getDBDate(fullTabellNamn);
put 'SCB= ' tableUpdated;
put 'SAS= ' dbUpdate;
			if dbUpdate < tableUpdated then do;
put 'Tabellen ska uppdateras';
			end;
			else do;
				put 'Det finns ingen uppdatering';
			end;
		end;

	endpackage ;
run;quit;
/*
2019-03-21T09:30:00
*/