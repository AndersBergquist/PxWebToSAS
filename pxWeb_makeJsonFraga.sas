/****************************************
Program: pxweb_makeJsonFraga.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Skapar json-fråga till datahämtning
***********************************/
proc ds2;
	package work.pxweb_makeJsonFraga / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		declare package work.pxweb_getMetaData getMetaData();

		method pxweb_makeJsonFraga();
		end;

		method skapaFraga(varchar(500) iUrl);
*			getMetaData.getData(iURL);
*			getMetaData.getAntalFragor();

/* Att göra:
		1. Skapa en optimala kombinationen av variabler i frågorna.
		2. Skapa en hash-lista med frågor.
		3. Hitta på ett sätt att exportera hash-listan utan tabell, om det går.
*/
		end;

	endpackage;
run;quit;