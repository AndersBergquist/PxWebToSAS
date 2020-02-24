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
		forward parseSCBRespons skapaOutputTabell cretateTidsvariabler;
		
		method pxweb_getData();
		end;

		method hamtaData(varchar(500) iUrl, nvarchar(100000) jsonFraga, varchar(32) tmpTable);
			declare nvarchar(5000000) respons;
			declare integer filFinns;
			respons=g.getData(iUrl, jsonFraga);

*			filFinns=g.finnsTabell('work', tmpTable);
*			if filFinns=0 then do;
			if g.finnsTabell('work', tmpTable)=0 then do;
				skapaOutputTabell(tmpTable, respons);
			end;
			parseSCBRespons(respons);
		end;

		method parseSCBRespons(nvarchar(5000000) respons);
*put respons;
		end;

		method skapaOutputTabell(varchar(32) tmpTable, nvarchar(5000000) iRespons);
			declare package json j();
			declare varchar(250) token code text type;
			declare integer rc tokenType parseFlags;
			declare varchar(1500) sqlFraga;

			sqlFraga='CREATE TABLE ' || tmpTable || '(';

			rc=j.createparser(iRespons);
			j.getNextToken(rc,token,tokenType,parseFlags);
			do until(j.ISRIGHTBRACKET(tokenType));
				type='';
				do until(j.ISRIGHTBRACE(tokenType));
					if(token='code') then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						code=token;
					end;
					else if(token='text') then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						text=token;
					end;
					else if(token='type') then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						type=token;
					end;
					j.getNextToken(rc,token,tokenType,parseFlags);
				end;
				if type='' then type='d';
				if (substr(sqlFraga,length(sqlFraga),1) ne '(') then do;
					sqlFraga=sqlFraga || ', ';
				end;
				if type='c' then do;
*					sqlFraga=sqlFraga || code || ' double having label ''' || text || '''';
					sqlFraga=sqlFraga || code || ' double having label ''' || text || '''';
				end;
				else if token='t' then do;

				end;
				else do;
					sqlFraga=sqlFraga || code || ' varchar(250) having label ''' || text || '''';
				end;
				if not(j.ISRIGHTBRACKET(tokenType)) then do;
					j.getNextToken(rc,token,tokenType,parseFlags);
				end;
			end;
			sqlFraga=sqlFraga || ', comments varchar(1000) , uppdaterat_dttm datetime having label ''Tidpunkten när raden uppdaterades, mest för interna referenser'' format datetime16.)';
			rc=sqlexec(sqlFraga);
			if (rc ne 0) then put 'pxweb_getdata.skapaOutputTabell Error: Tabellen gick inte att skapa';
		end;

		method identifieraTidsvariabler();
**Returnerar en sträng med tidsvariabelns variationer. t.ex år ger tid_dt och tid_cd och tid_num, månad ger tid_dt och tid_cd o.s.v.;
		end;

		method cretateTidsvariabler();
**Skapar och returnerar tidsvariabeler med variationer. t.ex år ger tid_dt och tid_cd och tid_num, månad ger tid_dt och tid_cd o.s.v.;
		end;

	endpackage;
run;quit;