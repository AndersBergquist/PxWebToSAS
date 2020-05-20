/****************************************
Program: pxweb_getData.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Hämtar SCB:s Json, tolkar den och lägger resultatet i en tabell.
Innehåller:
***********************************/


proc ds2;
	package work.pxweb_getData / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		declare package work.pxweb_skapaOutputTabell skapaOutputTabell();
		declare package pxweb_skapaStmtFraga skapaStmtFraga(); 
		declare package hash h_valuesdata();
		declare package sqlstmt s_updateTmpTable;
		declare varchar(250) values valuetexts code ;
		declare varchar(1000) sqlInsert;
		declare integer h_exist s_updateTmpTable_exist c d;

		forward parseSCBRespons cretateTidsvariabler prepare_s;

		method pxweb_getData();
			h_exist=0;
			s_updateTmpTable_exist=0;
		end;
		method hamtaData(varchar(500) iUrl, nvarchar(100000) jsonFraga, varchar(32) tmpTable, varchar(40) fullTabellNamn);
			declare nvarchar(5000000) respons;
			declare varchar(150) loadMetadata;
			declare integer tmpTableFinns fullTabellFinns p;

			tmpTableFinns=g.finnsTabell('work', tmpTable);
			fullTabellFinns=g.finnsTabell(fullTabellNamn);

			if h_exist=0 then do;
				loadMetadata='{select * from work.meta_' || tmpTable || ';}';
				h_valuesdata.keys([values]);
				h_valuesdata.data([code values valuetexts]);
				h_valuesdata.dataset(loadMetadata);
				h_valuesdata.definedone();
				h_exist=1;
			end;

			if tmpTableFinns=0 then do;
				skapaOutputTabell.skapaOutputTabell(tmpTable, fullTabellNamn);
			end;
			respons=g.getData(iUrl, jsonFraga);
			if substr(respons,1,38)='pxweb_GemensammaMetoder.getData(post):' then put respons;
			if s_updateTmpTable_exist = 0 then do;
				skapaStmtFraga.prepare_s(respons, tmpTable, sqlInsert, d, c);
				s_updateTmpTable_exist=1;
				s_updateTmpTable = _new_ sqlstmt(sqlInsert);
			end;
			parseSCBRespons(respons, tmpTable);
		end;

		method parseSCBRespons(nvarchar(5000000) iRespons, varchar(32) tmpTable);
*put iRespons;
			
		end;



		method cretateTidsvariabler();
**Skapar och returnerar tidsvariabeler med variationer. t.ex år ger tid_dt och tid_cd och tid_num, månad ger tid_dt och tid_cd o.s.v.;
		end;


	endpackage;
run;quit;