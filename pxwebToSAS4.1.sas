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
		declare package work.pxweb_getData SCB_getData();

		forward getDataStart;
		method pxwebtosas4();

		end;

		method getData(varchar(500) inUrl);
			declare varchar(32) SASTabell tmpTable libname;
			declare integer maxCells;
			maxCells=50000;
			tmpTable='work.' || scan(inUrl, -1, '/') || strip(put(time(),8.));
			SASTabell=scan(inUrl, -1, '/');
			getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);

		end;

		method getData(varchar(500) inUrl, varchar(8) SASLib, varchar(32) SASTabell);
			declare integer maxCells;
			declare varchar(32) tmpTable;
			maxCells=50000;
			tmpTable='work.' || scan(inUrl, -1, '/') || strip(put(time(),8.));
			getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
		end;

		method getData(varchar(500) inUrl, integer maxCells, varchar(8) SASLib, varchar(32) SASTabell, varchar(32) tmpTable);
			getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
		end;

		method getData(varchar(500) inUrl, varchar(32) tmpTable);
			declare varchar(32) SASTabell libname;
			declare integer maxCells;
			maxCells=50000;
			getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);
		end;

		method getData(varchar(500) inUrl, integer maxCells, varchar(32) tmpTable);
			declare varchar(32) SASTabell libname;
			getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);
		end;

		method getDataStart(varchar(500) iUrl, varchar(8) SASLib, varchar(32) SASTabell, integer maxCells, varchar(32) tmpTable);
			declare double tableUpdated dbUpdate;
			declare varchar(41) fullTabellNamn;
			declare nvarchar(100000) jsonFraga;
			declare integer ud;
			fullTabellNamn=SASLib || '.' || SASTabell;
			tableUpdated=SCB_Date.getSCBDate(iUrl);
			dbUpdate=SCB_Date.getDBDate(fullTabellNamn);
			if dbUpdate < tableUpdated then do;
put 'Tabellen ska uppdateras';
				SCB_GetJsonFraga.skapaFraga(iUrl, maxCells, fullTabellNamn);
				SCB_GetJsonFraga.getFirstFraga(jsonFraga);
				SCB_getData.hamtaData(iUrl,jsonFraga, tmpTable);
				ud=1;
			end;
			else do;
				put 'pxWebToSAS.getDataStart: Det finns ingen uppdatering till' fullTabellNamn;
				ud=0;
			end;
		end;
	endpackage ;
run;quit;
