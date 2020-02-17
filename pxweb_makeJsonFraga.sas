/****************************************
Program: pxweb_makeJsonFraga.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Skapar json-fr�ga till datah�mtning
***********************************/
proc ds2;
	package work.pxweb_makeJsonFraga / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		declare package work.pxweb_getMetaData getMetaData();

		method pxweb_makeJsonFraga();
		end;

		method skapaFraga(varchar(500) iUrl, integer maxCells);
			declare integer antalCodes;
			getMetaData.getData(iURL);
*			getMetaData.printMetaData('work.pxWeb_meta');
*			antalCodes=getMetaData.getAntalCodes();
*put 'antalCodes=' antalCodes;

/* Att g�ra:
		1. Skapa en optimala kombinationen av variabler i fr�gorna.
		2. Skapa en hash-lista med fr�gor.
		3. Hitta p� ett s�tt att exportera hash-listan utan tabell, om det g�r.
*/
		end;

	endpackage;
run;quit;