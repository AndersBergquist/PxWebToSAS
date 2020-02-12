/****************************************
Program: pxweb_GemensammaMetoder.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Samla metoder som används av flera packet.
Innehåller:
- getData; getData(iURL), hämtar en responsfil från pxWeb med hjälp av Get.
***********************************/


proc ds2;
	package work.pxweb_GemensammaMetoder / overwrite=yes;
	declare package http pxwebContent();

	method pxweb_GemensammaMetoder();

	end;

	method getData(varchar(500) iUrl) returns varchar(100000);*Hämtar metadata från SCB;
	declare varchar(100000) respons;
	declare integer sc rc;
	declare varchar(500) catalogURL;

		catalogUrl=tranwrd(iUrl,scan(iUrl,-1,'/'),'');
		pxwebContent.createGetMethod(catalogUrl);
		pxwebContent.executeMethod();

		sc=pxwebContent.getStatusCode();
  	    if substr(sc,1,1) not in ('4', '5') then do;
           	pxwebContent.getResponseBodyAsString(respons, rc);
 		end;
	   else do;
	   		respons='Error';
	   end;
	return respons;
	end;* getData;
run;quit;