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

		method skapaFraga(varchar(500) iUrl, integer maxCells, varchar(41) fullTabellNamn);
			declare integer antalCodes;
			getMetaData.getData(iURL, maxCells, fullTabellNamn);
			getMetaData.skapaSubFraga();
*			getMetaData.printMetaData('work.pxWeb_meta');
*			antalCodes=getMetaData.getAntalCodes();
*put 'antalCodes=' antalCodes;

/* Att göra:
		1. Skapa en optimala kombinationen av variabler i frï¿½gorna.
		2. Skapa en hash-lista med frï¿½gor.
		3. Hitta pï¿½ ett sï¿½tt att exportera hash-listan utan tabell, om det gï¿½r.
*/
		end;

	endpackage;
run;quit;