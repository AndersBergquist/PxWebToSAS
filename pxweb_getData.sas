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
		declare package hash h_metadata();
		declare package hiter hi_metadata(h_metadata);
		declare varchar(250) code elimination text "time" title values valueTexts;

		forward parseSCBRespons cretateTidsvariabler;
		
		method pxweb_getData();
		end;

		method hamtaData(varchar(500) iUrl, nvarchar(100000) jsonFraga, varchar(32) tmpTable, varchar(40) fullTabellNamn);
			declare nvarchar(5000000) respons;
			declare integer tmpTableFinns fullTabellFinns;

			tmpTableFinns=g.finnsTabell('work', tmpTable);
			fullTabellFinns=g.finnsTabell(fullTabellNamn);

			if tmpTableFinns=0 then do;
				skapaOutputTabell.skapaOutputTabell(tmpTable, fullTabellNamn);
			end;
			
			respons=g.getData(iUrl, jsonFraga);
			parseSCBRespons(respons);
		end;

		method parseSCBRespons(nvarchar(5000000) respons);
*put respons;
		end;

		method cretateTidsvariabler();
**Skapar och returnerar tidsvariabeler med variationer. t.ex år ger tid_dt och tid_cd och tid_num, månad ger tid_dt och tid_cd o.s.v.;
		end;

	endpackage;
run;quit;