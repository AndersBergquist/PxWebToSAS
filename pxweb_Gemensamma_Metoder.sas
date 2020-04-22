
/****************************************
Program: pxweb_GemensammaMetoder.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Samla metoder som används av flera packet.
Innehåller:
- getData; getData(iURL), hämtar en responsfil från pxWeb med hjälp av Get.
- finnsTabell, finnsTabell(iLib, iTabell), returnerar 0 om tabell ej finns och 1 om tabell finns.
***********************************/


proc ds2;
	package work.pxweb_GemensammaMetoder / overwrite=yes;
		declare package http pxwebContent();
		declare varchar(8) lib;
		declare varchar(32) tabell tid;
		declare nvarchar(1000000) respons;
		declare integer antal;

		forward finnsTabellHelper;

		method pxweb_GemensammaMetoder();

		end;

		method getData(varchar(500) iUrl) returns varchar(100000);*Hämtar metadata fr�n SCB;
		declare varchar(5000000) respons;
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
		end;

		method getData(varchar(500) iUrl, varchar(100000) jsonFraga) returns nvarchar(1000000);
			declare integer sc rc;
			pxwebContent.createPostMethod(iUrl);
			pxwebContent.setRequestContentType('application/json; charset=utf-8');
			pxwebContent.setRequestBodyAsString(jsonFraga);
			pxwebContent.executeMethod();
			sc=pxwebContent.getStatusCode();
			if substr(sc,1,1) not in ('4' '5') then do;
				pxwebContent.getResponseBodyAsString(respons, rc);
				if rc=1 then do;
					respons='pxweb_GemensammaMetoder.getData(post): Något gick fel för att responssträngen kunde inte hittas.';
				end;
			end;
			else do;
				respons='pxweb_GemensammaMetoder.getData(post): HTTP Error nr: ' || sc;
			end;

		return respons;
		end;* getData;

**** FinnsTabell metoden start;
		method finnsTabell(varchar(40) fullTabellNamn) returns integer;
			declare varchar(8) iLib;
			declare varchar(32) iTabell;
			declare integer antal;
			
			iLib=scan(fullTabellNamn,1,'.');
			iTabell=scan(fullTabellNamn,2,'.');
			antal=finnsTabellHelper(iLib, iTabell);
			return antal;
		end;

		method finnsTabell(varchar(8) iLib, varchar(32) iTabell) returns integer;
			declare integer antal;

			antal=finnsTabellHelper(iLib, Itabell);
			return antal;
		end;

		method finnsTabellHelper(varchar(8) iLib, varchar(32) iTabell) returns integer;
			declare package sqlstmt s('select count(*) as antal from dictionary.tables where TABLE_SCHEM=? AND table_name=?',[lib tabell]);

			tabell=upcase(iTabell);
			lib=upcase(iLib);
			s.execute();
			s.bindresults([antal]);
			s.fetch();
			if antal > 0 then antal=1; else antal=0;
		return antal;
		end;*finnsTabell;
**** FinnsTabell metoden slut;

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

		method kollaVariabelNamn(in_out varchar code);
put 'Inkod: ' code;
			if anydigit(strip(code))=1 then code='_' || strip(code);
put 'Utkod: ' code;
		end;*kollaVariabelNamn;

	endpackage ;
run;quit;
