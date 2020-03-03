/****************************************
Program: pxweb_Skapa_Input_Tabell.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Skapar en tabell där indata från SCB lagras.
Innehåller:
***********************************/


proc ds2;
	package work.pxweb_skapaOutputTabell / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		declare package work.pxweb_getMetaData getMeta();
		declare package hash h_metadata();
		declare package hiter hi_metadata(h_metadata);
		declare nvarchar(250) title code text "time" elimination;
		declare integer len_values len_valueTexts;

		forward skapaTabell useExistingTable identifieraTidsvariabler;

		method pxweb_skapaOutputTabell();
		end;

		method skapaOutputTabell(varchar(32) tmpTable, nvarchar(40) fullTabellNamn);
fullTabellNamn='sasuser.aku_ny';			
			if g.finnsTabell('work', tmpTable)=0 then do;
				if g.finnsTabell(fullTabellNamn)=0 then do;
					skapaTabell(tmpTable);
				end;
				else do;
					useExistingTable(tmpTable, fullTabellNamn);
				end;
			end;
		end;

		method skapaTabell( nvarchar(32) tmpTable);
			declare nvarchar(2000) sqlfraga;
			declare nvarchar(250) txtStr;
			declare integer rc;

			h_metadata.keys([title code text "time" elimination]);
			h_metadata.data([title code text "time" elimination len_values len_valueTexts]);
			h_metadata.dataset('{select title, code, text, "time", elimination, max(CHARACTER_LENGTH(trim("values"))) as len_values, max(CHARACTER_LENGTH(trim(valueTexts))) as len_valueTexts from work.meta_' || tmpTable ||' where trim(code) ^= ''ContentsCode'' group by title, code, text, "time", elimination}');
			h_metadata.ordered('A');
			h_metadata.defineDone();
*********** Tänk på: variabelnamn som inte är alphanumeriskt skall skrivas ''variablenamn''n En check måste göras;
*********** Gör det allmänt;

			rc=hi_metadata.first([title code text "time" elimination len_values len_valueTexts]);
			sqlfraga='CREATE TABLE work.' || tmpTable || '{option label=''' || strip(title) || '''} (';
			if strip("time") ^='true' then do;
				sqlfraga=sqlfraga || strip(code) || '_cd varchar(' || len_Values || ') having label ''' || trim(text) || '''';
				sqlfraga=sqlfraga || ',' || strip(code) || '_nm varchar(' || len_ValueTexts || ') having label ''' || trim(text) || '''';
			end;
			else do;
					identifieraTidsvariabler(text, code, text, len_Values, len_ValueTexts,txtStr);
					sqlfraga=sqlfraga || ',' || txtStr;
			end;
			hi_metadata.next([title code text "time" elimination len_values len_valueTexts]);
			do until(hi_metadata.next([title code text "time" elimination len_values len_valueTexts]));
				if strip("time")='true' then do;
					identifieraTidsvariabler(text, code, text, len_Values, len_ValueTexts,txtStr);
					sqlfraga=sqlfraga || ',' || txtStr;
				end;
				else do;
					sqlfraga=sqlfraga || ',' || strip(code) || '_cd varchar(' || len_Values || ') having label ''' || trim(text) || '''';
					sqlfraga=sqlfraga || ',' || strip(code) || '_nm varchar(' || len_ValueTexts || ') having label ''' || trim(text) || '''';
				end;
			end;
			sqlfraga=sqlfraga || ')';
			sqlExec(sqlfraga);

		end;*skapaTabell;

		method identifieraTidsvariabler(varchar(250) tidTyp, varchar(250) code, varchar(250) text, integer len_Values, integer len_valueTexts, in_out varchar(250) tidString);
			if lowCase(tidTyp) in ('år', 'kvartal', 'månad') then do;
					tidString=strip(code) || '_dt date having label ''' || trim(text) || '''';
					tidString=tidString || ',' || strip(code) || '_cd varchar(' || len_Values || ') having label ''' || trim(text) || '''';
					tidString=tidString || ',' || strip(code) || '_nm varchar(' || len_ValueTexts || ') having label ''' || trim(text) || '''';
			end;
**Returnerar en sträng med tidsvariabelns variationer. t.ex år ger tid_dt och tid_cd och tid_num, månad ger tid_dt och tid_cd o.s.v.;
		end;

		method useExistingTable(varchar(32) tmpTable, nvarchar(40) fullTabellNamn);
			declare varchar(250) sqlfraga;
			sqlfraga='create table ' || tmpTable || ' as select * from ' || fullTabellNamn;
			sqlExec(sqlfraga);
		end;
	endpackage;
run;quit;