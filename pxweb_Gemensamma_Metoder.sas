/****************************************
Program: pxweb_GemensammaMetoder.sas
Upphovsperson: Andeputrs Bergquist, anders@fambergquist.se
Version: 4.0.11
Uppgift:
- Samla metoder som anv�nds av flera packet.
Inneh�ller:
- getData; getData(iURL), h�mtar en responsfil fr�n pxWeb med hj�lp av Get.
- finnsTabell, finnsTabell(iLib, iTabell), returnerar 0 om tabell ej finns och 1 om tabell finns.
- getSenasteTid, getSenasteTid(fulltTabellnamn), returnerar senaste tiden f�r data i tabellen. 0 om tabellen inte finns.
- kollaVariabelNamn, kollaVariabelNamn(in_out varchar code), l�gger till _ om f�rsta tecknet i columnnmanet �r ett tal.;
***********************************/


proc ds2;
	package &prgLib..pxweb_GemensammaMetoder / overwrite=yes;
		declare package http pxwebContent();
		declare nvarchar(8) lib;
		declare nvarchar(32) tabell tid maxTid;
		declare nvarchar(15000000) respons;
		declare integer antal ctid;

		forward finnsTabellHelper;

		method pxweb_GemensammaMetoder();

		end;

		method getData(nvarchar(500) iUrl) returns nvarchar(100000);*H�mtar metadata frn SCB;
		declare integer sc rc lenRespons;
		declare nvarchar(500) catalogURL x;

			pxwebContent.createGetMethod(iUrl);
			pxwebContent.executeMethod();
			sc=pxwebContent.getStatusCode();
	  	    if substr(sc,1,1) not in ('4', '5') then do;
	           	pxwebContent.getResponseBodyAsString(respons, rc);
				if substr(respons,1,7)^='[{"id":' then do;
					lenRespons=length(respons);
					put 'Metadatafilen innehåller ' lenRespons nlnum24.-l ' tecken';
				end;
	 		end;
		   else do;
		   		respons='Error';
		   end;
		return respons;
		end;

		method getData(nvarchar(500) iUrl, nvarchar(100000) jsonFraga) returns nvarchar(15000000);
			declare integer sc rc;
			pxwebContent.createPostMethod(iUrl);
			pxwebContent.setRequestContentType('application/json; charset=utf-8');
			pxwebContent.setRequestBodyAsString(jsonFraga);
			pxwebContent.executeMethod();
			sc=pxwebContent.getStatusCode();
			if substr(sc,1,1) not in ('4' '5') then do;
				pxwebContent.getResponseBodyAsString(respons, rc);
				if rc=1 then do;
					respons='pxweb_GemensammaMetoder.getData(post): N�got gick fel f�r att responsstr�ngen kunde inte hittas. Error: 111';
				end;
			end;
			else do;
				respons='pxweb_GemensammaMetoder.getData(post): HTTP Error nr: ' || sc;
			end;
		return respons;
		end;* getData;

**** FinnsTabell metoden start;
		method finnsTabell(nvarchar(40) fullTabellNamn) returns integer;
			declare nvarchar(8) iLib;
			declare nvarchar(32) iTabell;
			declare integer antal;
			
			iLib=scan(fullTabellNamn,1,'.');
			iTabell=scan(fullTabellNamn,2,'.');
			antal=finnsTabellHelper(iLib, iTabell);
			return antal;
		end;

		method finnsTabell(nvarchar(8) iLib, nvarchar(32) iTabell) returns integer;
			declare integer antal;

			antal=finnsTabellHelper(iLib, Itabell);
			return antal;
		end;

		method finnsTabellHelper(nvarchar(8) iLib, nvarchar(32) iTabell) returns integer;
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

		method getSenasteTid(nvarchar(40) fullTabellNamn) returns nvarchar(32);
			declare	package sqlstmt s();
			declare package sqlstmt c();
			declare nvarchar(95) sqlMax sqlCount;
			declare integer tabellFinns rc sc qc xc;

			tabellFinns=finnsTabell(scan(fullTabellNamn,1,'.'), scan(fullTabellNamn,2,'.'));
			if tabellFinns=1 then do;
				sqlCount='select count(tid_cd) as ctid from ' || fullTabellNamn;
				sc=c.prepare(sqlCount);
				qc=c.execute();
				c.bindresults([ctid]);
				rc=c.fetch();
				c.delete();
				if ctid>0 then do;
					sqlMax='select max(tid_cd) as tid from ' || fullTabellNamn;
					sc=s.prepare(sqlMax);
					qc=s.execute();
					xc=s.bindresults([maxTid]);
					rc=s.fetch();
				end;
				else maxTid='0';
			end;
			else do;
				maxTid='0';
			end;
		return maxTid;
		end;*getDBDate;

		method kollaVariabelNamn(in_out varchar code);
			if anydigit(strip(code))=1 then code='_' || strip(code);
		end;*kollaVariabelNamn;

	endpackage ;
run;quit;
