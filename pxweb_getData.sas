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
		declare package work.pxweb_skapaOutputTabell skapaOutputTabell();
		declare package sqlstmt s_updateTmpTable();

		forward parseSCBRespons cretateTidsvariabler prepare_s;
		
		method pxweb_getData();
		end;

		method hamtaData(varchar(500) iUrl, nvarchar(100000) jsonFraga, varchar(32) tmpTable, varchar(40) fullTabellNamn);
			declare nvarchar(5000000) respons;
			declare integer tmpTableFinns fullTabellFinns;

			tmpTableFinns=g.finnsTabell('work', tmpTable);
			fullTabellFinns=g.finnsTabell(fullTabellNamn);

			if tmpTableFinns=0 then do;
				skapaOutputTabell.skapaOutputTabell(tmpTable, fullTabellNamn);
			end;
			respons=g.getData(iUrl, jsonFraga);
			if substr(respons,1,38)='pxweb_GemensammaMetoder.getData(post):' then put respons;

			if s_updateTmpTable.isPrepared()=0 then do;
*				prepare_s(respons, tmpTable);
			end;
*			parseSCBRespons(respons, tmpTable);
		end;

* update tmpTable set col1=?`, col2=?, col3=? ...;

		method parseSCBRespons(nvarchar(5000000) iRespons, varchar(32) tmpTable);
put iRespons;
		end;



		method cretateTidsvariabler();
**Skapar och returnerar tidsvariabeler med variationer. t.ex år ger tid_dt och tid_cd och tid_num, månad ger tid_dt och tid_cd o.s.v.;
		end;

		method prepare_s(nvarchar(5000000) iRespons, varchar(32) tmpTable);
			declare package json j();
			declare varchar(1000) sqlUpdate;
			declare varchar(250) token code text comment type unit;
			declare integer rc tokenType parseFlags tmpCeller divisor loopNr;

			rc=j.createparser(iRespons);
			sqlUpdate='UPDATE ' || tmpTable || ' set ';
			loopNr=1;
			do until(trim(token)='columns');
				j.getNextToken(rc,token,tokenType,parseFlags);

			end;
			do until(j.ISRIGHTBRACKET(tokenType));
				type='d';
				do until(j.isrightbrace(tokenType));
					if trim(token)='code' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						code=trim(token);
					end;
					else if trim(token)='text' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						text=trim(token);
					end;
					else if trim(token)='comment' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						comment=trim(token);
					end;
					else if trim(token)='type' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						type=trim(token);
					end;
					else if trim(token)='unit' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						unit=trim(token);
					end;

					j.getNextToken(rc,token,tokenType,parseFlags);
				end;
				if type='d' then do;
					if loopNr=0 then do;
						sqlUpdate=sqlUpdate || ', ';
					end;
					else loopNr=0;
					sqlUpdate=sqlUpdate || code || '_cd=?' || ', ' || code || '_nm=?';
				end;
				if type='t' then do;
					if loopNr=0 then do;
						sqlUpdate=sqlUpdate || ', ';
					end;
					else loopNr=0;					sqlUpdate=sqlUpdate || code || '_cd=?' || ', ' ||code || '_nm=?';
					if lowCase(text) in ('år', 'kvartal', 'månad') then do;
						sqlUpdate=sqlUpdate || ', ' || code || '_dt=?';
					end;
				end;
				if type='c' then do;
					sqlUpdate=sqlUpdate || ', ' || code || '=?';
				end;
				j.getNextToken(rc,token,tokenType,parseFlags);
			end;
			s_updateTmpTable.prepare(sqlUpdate);
		end;*S_prepare end;

	endpackage;
run;quit;