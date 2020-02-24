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
		forward parseSCBRespons;
		
		method pxweb_getData();
		end;

		method hamtaData(varchar(500) iUrl, nvarchar(100000) jsonFraga, varchar(32) tmpTable);
			declare nvarchar(5000000) respons;
			respons=g.getData(iUrl, jsonFraga);
			parseSCBRespons(respons);
		end;

		method parseSCBRespons(nvarchar(5000000) respons);
*put respons;
		end;

	endpackage;
run;quit;