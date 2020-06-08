/****************************************
Program: pxweb_getData.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.0
Uppgift:
- Hämtar SCB:s Json, tolkar den och lägger resultatet i en tabell.
Innehåller:
***********************************/


proc ds2;
	package &prgLib..pxweb_getData / overwrite=yes;
		declare package &prgLib..pxweb_GemensammaMetoder g();
		declare package &prgLib..pxweb_skapaOutputTabell skapaOutputTabell();
		declare package &prgLib..pxweb_skapaStmtFraga skapaStmtFraga(); 
		declare package hash h_valuesdata();
		declare package hash h_valuesIndex();
		declare package sqlstmt s_updateTmpTable;
		declare char(1) dtype;
		declare varchar(250) values valuetexts code kolNamn kolTexts;
		declare varchar(1000) sqlInsert;
		declare integer h_exist c_exist c_index s_updateTmpTable_exist c d;

		forward parseSCBRespons cretateTidsvariabler prepare_s;

		method pxweb_getData();
			h_exist=0;
			c_exist=0;
			s_updateTmpTable_exist=0;
		end;
		method hamtaData(varchar(500) iUrl, nvarchar(100000) jsonFraga, varchar(32) tmpTable, varchar(40) fullTabellNamn);
			declare nvarchar(15000000) respons;
			declare varchar(150) loadMetadata;
			declare integer tmpTableFinns fullTabellFinns p;
			tmpTableFinns=g.finnsTabell('work', tmpTable);
			fullTabellFinns=g.finnsTabell(fullTabellNamn);

			if h_exist=0 then do;
				h_valuesdata.keys([code values]);
				h_valuesdata.data([code values valuetexts]);
				h_valuesdata.dataset('{select strip(code) as code, strip("values") as "values", strip(valuetexts) as valuetexts from work.meta_' || tmpTable || ';}');
				h_valuesdata.definedone();
				h_exist=1;
*				h_valuesdata.output('work.hashlookup');
			end;
			if tmpTableFinns=0 then do;
				skapaOutputTabell.skapaOutputTabell(tmpTable, fullTabellNamn);
			end;
			respons=g.getData(iUrl, jsonFraga);
			if substr(respons,1,38)='pxweb_GemensammaMetoder.getData(post):' then put respons;
			if s_updateTmpTable_exist = 0 then do;
				skapaStmtFraga.prepare_s(respons, tmpTable, sqlInsert, d, c);
				s_updateTmpTable_exist=1;
				s_updateTmpTable = _new_ sqlstmt(sqlInsert);
			end;
			parseSCBRespons(respons, tmpTable);
		end;

		method parseSCBRespons(nvarchar(15000000) iRespons, varchar(32) tmpTable);
			declare package json j();
			declare integer rc tokenType parseFlags i sc;
			declare double tid_dt;
			*declare double tid;
			declare nvarchar(500) token;
			rc=j.createParser(iRespons);
*			j.getNextToken(rc, token, tokenType, parseFlags);
			do while(rc=0);
				if token='columns' and c_exist=0 then do;
					c_index=0;
					h_valuesIndex.keys([c_index]);
					h_valuesIndex.data([c_index kolNamn kolTexts dtype]);
					h_valuesIndex.definedone();
					do until(j.ISRIGHTBRACKET(tokenType));
						do until(j.ISRIGHTBRACE(tokenType));
							if token='code' then do;
								dtype='d';
								c_index=c_index+1;
								j.getNextToken(rc, token, tokenType, parseFlags);
								kolNamn=token;
	*							h_valuesIndex.add([c_index],[c_index values dtype]);
							end;
							if token='type' then do;
								j.getNextToken(rc, token, tokenType, parseFlags);
								dtype=token;
	*							h_valuesIndex.replace([c_index],[c_index values dtype]);
							end;
							if token='text' then do;
								j.getNextToken(rc, token, tokenType, parseFlags);
								kolTexts=token;

							end;
							j.getNextToken(rc, token, tokenType, parseFlags);
						end;
						h_valuesIndex.add([c_index],[c_index kolNamn kolTexts dtype]);
						j.getNextToken(rc, token, tokenType, parseFlags);
					end;
*				h_valuesIndex.output('work.valuesIndex');
				c_exist=1;
				end;
				if token='data' then do;
					do until(j.ISRIGHTBRACKET(tokenType));
						if token='key' then do;

							i=1;
							c_index=1;
							j.getNextToken(rc, token, tokenType, parseFlags);
							if j.ISLEFTBRACKET(tokenType) then j.getNextToken(rc, token, tokenType, parseFlags);
							do until(j.ISRIGHTBRACKET(tokenType));
								h_valuesIndex.find([c_index],[c_index kolNamn kolTexts dtype]);
								values=token;
								sc=h_valuesdata.find([kolNamn values],[code values valuetexts]);
								sc=s_updateTmpTable.setvarchar(i, values);
								i=i+1;
								sc=s_updateTmpTable.setvarchar(i, valueTexts);
								i=i+1;
								if dtype='t' and lowCase(kolTexts) in ('år', 'kvartal', 'månad') then do;
									tid_dt=cretateTidsvariabler(values, kolTexts);
									sc=s_updateTmpTable.setdouble(i, tid_dt);
									i=i+1;
								end;
								c_index=c_index+1;
								j.getNextToken(rc, token, tokenType, parseFlags);
							end;
						end;
						if token='values' then do;
							j.getNextToken(rc, token, tokenType, parseFlags);
							if j.ISLEFTBRACKET(tokenType) then j.getNextToken(rc, token, tokenType, parseFlags);
							do until(j.ISRIGHTBRACKET(tokenType));
								if notdigit(token)=1 then token=.;
								s_updateTmpTable.setdouble(i, token);
								i=i+1;
								c_index=c_index+1;
								j.getNextToken(rc, token, tokenType, parseFlags);
							end;
						sc=s_updateTmpTable.execute();
						end;
						j.getNextToken(rc, token, tokenType, parseFlags);
					end;
				end;
			j.getNextToken(rc, token, tokenType, parseFlags);
			end;
		end;

		method cretateTidsvariabler(varchar(250) tid_cd, varchar(250) tid_nm) returns double;
		declare double manad ar tid_dt;
			ar=substr(tid_cd,1,4);
			if lowCase(tid_nm) = 'år' then do;
				manad=1;
			end;
			else if lowCase(tid_nm) = 'kvartal' then do;
				manad=substr(tid_cd,6,2)*3-2;
			end;
			else if lowCase(tid_nm) = 'månad' then do;
				manad=substr(tid_cd,6,2);
			end;
			tid_dt=mdy(manad,1,ar);
			return tid_dt;
		end; *cretateTidsvariabler;

		method closeTable();
			s_updateTmpTable.delete();
		end; *closeTable;


	endpackage;
run;quit;
