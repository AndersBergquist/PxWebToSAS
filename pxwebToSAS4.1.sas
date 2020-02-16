/****************************************
Program: pxwebToSAS4
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1

- output:
	1. Sätter makrot &update till 1 om uppdatering finns och 0 om det inte finns.
***********************************/


proc ds2;
	package work.pxWebToSAS4 / overwrite=yes;
		declare package work.pxweb_UppdateTableDate SCB_Date();
		declare package work.pxweb_makeJsonFraga SCB_GetJsonFraga();

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
			declare integer ud;
			fullTabellNamn=SASLib || '.' || SASTabell;
			tableUpdated=SCB_Date.getSCBDate(iUrl);
			dbUpdate=SCB_Date.getDBDate(fullTabellNamn);

			if dbUpdate < tableUpdated then do;
put 'Tabellen ska uppdateras';
				SCB_GetJsonFraga.skapaFraga(iUrl);
				ud=1;
			end;
			else do;
				put 'Det finns ingen uppdatering';
				ud=0;
			end;
		end;
	endpackage ;
run;quit;
