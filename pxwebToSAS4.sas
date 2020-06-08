/****************************************
Program: pxwebToSAS4
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.0

- output:
	1. Lämnar returkod till 1 om uppdatering genomförts och 0 om den inte genomförts.
***********************************/
proc ds2;
	package &prgLib..pxWebToSAS4 / overwrite=yes;
		declare package &prgLib..pxweb_UppdateTableDate SCB_Date();
		declare package &prgLib..pxweb_makeJsonFraga SCB_GetJsonFraga();
		declare package &prgLib..pxweb_getData SCB_getData();
		declare package &prgLib..pxweb_gemensammametoder g();
		declare package sqlstmt s_jsonGet;
		declare nvarchar(100000) jsonFraga;
		declare integer defaultMaxCells;

		forward getDataStart;

		method pxwebtosas4();
			defaultMaxCells=50000;
		end;
******** getData varianter för att göra det så flexibelt som möjligt att hämta data. start;
		method getData(varchar(500) inUrl) returns integer;
			declare varchar(32) SASTabell tmpTable libname;
			declare integer maxCells upd;
			maxCells=defaultMaxCells;
			tmpTable=scan(inUrl, -1, '/') || strip(put(time(),8.));
			SASTabell=scan(inUrl, -1, '/');
			upd=getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);
			return upd;
		end;

		method getData(varchar(500) inUrl, varchar(8) SASLib) returns integer;
			declare varchar(32) SASTabell tmpTable libname;
			declare integer maxCells upd;
			maxCells=defaultMaxCells;
			tmpTable=scan(inUrl, -1, '/') || strip(put(time(),8.));
			SASTabell=scan(inUrl, -1, '/');
			upd=getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
			return upd;
		end;

		method getData(varchar(500) inUrl, varchar(8) SASLib, varchar(32) SASTabell) returns integer;
			declare integer maxCells upd;
			declare varchar(32) tmpTable;
			maxCells=defaultMaxCells;
			tmpTable=scan(inUrl, -1, '/') || strip(put(time(),8.));
			upd=getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
			return upd;
		end;

		method getData(varchar(500) inUrl, integer maxCells, varchar(8) SASLib, varchar(32) SASTabell, varchar(32) tmpTable) returns integer;
			declare integer upd;
			upd=getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
			return upd;
		end;

******** getData varianter för att göra det så flexibelt som möjligt att hämta data. start;

		method getDataStart(varchar(500) iUrl, varchar(8) SASLib, varchar(32) SASTabell, integer maxCells, varchar(32) tmpTable) returns integer;
			declare package hash h_jsonFragor();
			declare package hiter hi_jsonFragor(h_jsonFragor);
			declare package sqlstmt s();
			declare double tableUpdated dbUpdate;
			declare varchar(41) fullTabellNamn;
			declare varchar(250) fraga;
			declare integer ud rc i rcGet rcF;
			declare integer starttid runTime loopStart;

			starttid=time();

			fullTabellNamn=SASLib || '.' || SASTabell;
			tableUpdated=SCB_Date.getSCBDate(iUrl);
			dbUpdate=SCB_Date.getDBDate(fullTabellNamn);
			if dbUpdate < tableUpdated then do;
				SCB_GetJsonFraga.skapaFraga(iUrl, maxCells, fullTabellNamn, tmpTable);
				s_jsonGet = _new_ sqlstmt('select jsonFraga from work.json_' || tmpTable);
				s_jsonGet.execute();
				s_jsonGet.fetch();
				s_jsonGet.getvarchar(1,jsonFraga,rcGet);
				i=1;
				do while(rcGet=0);
					loopStart=time();
					if rcGet=0 then SCB_getData.hamtaData(iUrl, jsonFraga, tmpTable, fullTabellNamn);
					do while(time()-loopstart < 1);
					end;
					rcF=s_jsonGet.fetch();
					if rcF=0 then s_jsonGet.getvarchar(1,jsonFraga,rcGet); else rcGet=1;
				end;
				SCB_getData.closeTable();
				s_jsonGet.delete();
				if g.finnsTabell(fullTabellNamn)^=0 then sqlexec('INSERT INTO ' || fullTabellNamn || ' SELECT * FROM work.' || tmpTable);
				else sqlexec('SELECT * INTO ' || fullTabellNamn || ' FROM work.' || tmpTable || '');
				sqlexec('DROP TABLE work.' || tmpTable);
				sqlexec('DROP TABLE work.meta_' || tmpTable || ';');
				sqlexec('DROP TABLE work.json_' || tmpTable || ';');
				ud=1;
*Uppdatera sas-tabellen.;
			end;
			else do;
				put 'pxWebToSAS.getDataStart: Det finns ingen uppdatering till' fullTabellNamn;
				ud=0;
			end;
			runtime=time()-starttid;
			put 'Hämtningen tog' runTime 'sekunder, returkod:' ud;
			return ud;
		end;
	endpackage ;
run;quit;
