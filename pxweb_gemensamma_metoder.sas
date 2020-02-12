/****************************************
Program: pxweb_GemensammaMetoder.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Samla metoder som anv�nds av flera packet.
Inneh�ller:
- getData; getData(iURL), h�mtar en responsfil fr�n pxWeb med hj�lp av Get.
***********************************/


proc ds2;
	package work.pxweb_GemensammaMetoder / overwrite=yes;
	declare package http pxwebContent();

	method pxweb_GemensammaMetoder();

	end;

	method getData(varchar(500) iUrl) returns varchar(100000);*H�mtar metadata fr�n SCB;
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