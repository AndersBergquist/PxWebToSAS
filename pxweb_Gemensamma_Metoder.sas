
/****************************************
Program: pxweb_GemensammaMetoder.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Samla metoder som anv�nds av flera packet.
Inneh�ller:
- getData; getData(iURL), h�mtar en responsfil fr�n pxWeb med hj�lp av Get.
- finnsTabell, finnsTabell(iLib, iTabell), returnerar 0 om tabell ej finns och 1 om tabell finns.
***********************************/


proc ds2;
	package work.pxweb_GemensammaMetoder / overwrite=yes;
		declare package http pxwebContent();
		declare varchar(8) lib;
		declare varchar(32) tabell tid;
		declare integer antal;

		method pxweb_GemensammaMetoder();

		end;

		method getData(varchar(500) iUrl) returns varchar(100000);*H�mtar metadata fr�n SCB;
		declare varchar(100000) respons;
		declare integer sc rc;
		declare varchar(500) catalogURL;

			pxwebContent.createGetMethod(iUrl);
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

		method finnsTabell(varchar(8) iLib, varchar(32) iTabell) returns integer;
			declare package sqlstmt s('select count(*) as antal from dictionary.tables where TABLE_SCHEM=? AND table_name=?',[lib tabell]);

			tabell=upcase(iTabell);
			lib=upcase(iLib);
			s.execute();
			s.bindresults([antal]);
			s.fetch();
			if antal > 0 then antal=1; else antal=0;
		return antal;
		end;*finnsTabell;

		method getSenasteTid(varchar(40) fullTabellNamn) returns varchar(32);
			declare	package sqlstmt s();
			declare varchar(93) sqlMax;
			declare integer tabellFinns rc;

			tabellFinns=finnsTabell(scan(fullTabellNamn,1,'.'), scan(fullTabellNamn,2,'.'));
			if tabellFinns=1 then do;
				sqlMax='select max(tid_cd) as tid from ' || fullTabellNamn;
				s.prepare(sqlMax);
				s.execute();
				s.bindresults([tid]);
				rc=s.fetch();
			end;
			else do;
				tid=0;
			end;

		return tid;
		end;*getDBDate;

	endpackage ;
run;quit;
