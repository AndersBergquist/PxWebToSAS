/****************************************
Program: pxweb_getMetaData.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Skapar json-fråga till datahämtning
***********************************/
proc ds2;
	package work.pxweb_getMetaData / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		declare package hash metaData();
		declare package hiter hi_metaData(metaData);
		declare package hash h_dataStorlek();
		declare package hiter hi_dataStorlek(h_dataStorlek);
		declare integer radNr antal antalCeller cellerPerValue;
		declare varchar(250) title code text values valueTexts elimination "time" subCode;
		declare varchar(25000) subFraga;

		forward getJsonMeta parseJsonMeta printData;
		method pxweb_getMetaData();
		end;

		method getData(varchar(500) iUrl, integer maxCells, varchar(41) fullTabellNamn);
			declare varchar(25000) respons;
			respons=g.getData(iUrl);
			parseJsonMeta(respons, maxCells, fullTabellNamn);
		end;*skapaFraga;

** Skriver ut metadatatabellen, start **;
		method printMetaData(varchar(40) libTable);
			printData(libTable);
		end;

		method printMetaData(varchar(8) lib, varchar(32) tabell);
			declare varchar(40) libTable;
			libTable=lib || '.' || tabell;
			printData(libTable);
		end;

		method printData(varchar(40) libTable);
			metaData.output(libTable);
		end;
** Skriver ut metadatatabellen, slut **;

		method getAntalCodes() returns integer;
			declare integer antalCodes;
			antalCodes=h_datastorlek.num_items;
			return antalCodes;
		end;

		method getAntalCeller() returns integer;
			declare integer antalCeller;
			antalCeller=1;
			hi_dataStorlek.first([code,radNr]);
			do until(hi_dataStorlek.next([code,radNr]));
				antalCeller=antalCeller*radNr;
			end;
			return antalCeller;
		end;

		method getAntalFragor() returns integer;
			declare integer antalCeller antalFragor;

			antalCeller=getAntalCeller();
			antalFragor=round((antalCeller/50000)+0.5);
			return antalFragor;
		end;

		method parseJsonMeta(varchar(25000) iRespons, integer maxCells, varchar(41) fullTabellNamn);
			declare package hash parsMeta();
			declare package hiter hiparsMeta(parsMeta);
			declare package json j();
			declare varchar(250) token;
			declare varchar(25) senasteTid;
			declare integer rc tokenType parseFlags tmpCeller divisor;

			senasteTid=g.getSenasteTid(fullTabellNamn);
			antalCeller=1;

			parsMeta.keys([radNr]);
			parsMeta.data([title, code, text, values, valueTexts]);
			parsMeta.ordered('A');
			parsMeta.defineDone();

			metaData.keys([code, values]);
			metaData.data([title, code, text, values, valueTexts, elimination, "time"]);
			metaData.ordered('A');
			metaData.defineDone();

			h_dataStorlek.keys([code]);
			h_dataStorlek.data([code antal, antalCeller]);
			h_dataStorlek.defineDone();

			rc=j.createparser(iRespons);
			j.getNextToken(rc,token,tokenType,parseFlags);
			do while(rc=0);
				if token='title' then do;
					j.getNextToken(rc,token,tokenType,parseFlags);
					title=token;
				end;
				if token='variables' then do;
					j.getNextToken(rc,token,tokenType,parseFlags);
					do until(j.ISRIGHTBRACKET(tokenType));
						elimination='false';
						"time"='false';
						do until(j.ISRIGHTBRACE(tokenType));
							if token='code' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								code=token;
							end;
							else if token='text' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								text=token;
							end;
							else if token='elimination' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								elimination=token;
							end;
							else if token='time' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								"time"=token;
							end;
							else if token='values' then do;
								radNr=0;
								j.getNextToken(rc,token,tokenType,parseFlags);
								do until(j.isrightbracket(tokenType));
									if j.isleftbracket(tokenType) then do;
									end;
									else do;
										radNr=radNr+1;
										values=token;
										parsMeta.ref([radNr],[title, code, text, values, valueTexts]);
									end;
									j.getNextToken(rc,token,tokenType,parseFlags);
								end;
							end;
							else if token='valueTexts' then do;
								radNr=0;
								j.getNextToken(rc,token,tokenType,parseFlags);
								do until(j.isrightbracket(tokenType));
									if j.isleftbracket(tokenType) then do;
									end;
									else do;
										radNr=radNr+1;
										parsMeta.find([radNr],[title, code, text, values, valueTexts]);
										valueTexts=token;
										parsMeta.replace([radNr],[title, code, text, values, valueTexts]);
									end;
									j.getNextToken(rc,token,tokenType,parseFlags);
								end;
							end;
							j.getNextToken(rc,token,tokenType,parseFlags);
						end;
						hiparsmeta.first([title, code, text, values, valueTexts]);
						do until(hiparsmeta.next([title, code, text, values, valueTexts]));
							if("time"='true' and (senasteTid<values)) then do;* and (senasteTid='' or senasteTid > values)) then do;
								metaData.ref([code, values],[title, code, text, values, valueTexts,elimination, "time"]);
							end;
							else if "time" ^= 'true' then do;
								metaData.ref([code, values],[title, code, text, values, valueTexts,elimination, "time"]);
							end;
						end;
** Beräknar tabell som visar antal värden en variable ska ha i varje fråga för att inte gå över maxCells (50000), start;
						antalCeller=radNr*antalCeller;
						if antalCeller=0 then do;
							cellerPerValue=1;
							h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
						end;
						else if antalCeller<=maxCells then do;
							cellerPerValue=radNr;
							h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
						end;
						else if antalCeller> maxCells then do;
							antalCeller=antalCeller/radNr;
							divisor=1;
							do until(tmpCeller<=50000);
								divisor=divisor+1;
								tmpCeller=round((radNr/divisor)+0.5)*(antalCeller);
							end;
								cellerPerValue=radNr/divisor;
								h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
								antalCeller=0;
						end;
** Beräknar tabell som visar antal värden en variable ska ha i varje fråga för att inte gå över maxCells (50000), slut;
						parsmeta.clear();
						j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				end;
				j.getNextToken(rc,token,tokenType,parseFlags);
			end;
		end;*parseJsonMeta;

		method skapaSubFraga();
			declare package hash h_subFragor();
			declare varchar(25000) stubFraga;
			declare integer rundaNr;

 			h_subFragor.keys([subCode, subFraga]);
			h_subFragor.data([subCode, subFraga]);
			h_subFragor.ordered('A');
			h_subFragor.defineDone();

			hi_dataStorlek.first([subCode,antal,cellerPerValue]);
			do until(hi_dataStorlek.next([subCode,antal,cellerPerValue]));
				if antal=cellerPerValue then do;
					subFraga='{"code":' || subCode || '", "selection":{"filter":"all", "values":["*"]}}';
					h_subFragor.ref([subCode, subFraga],[subCode, subFraga]);
				end;
				else do;
					if cellerPerValue=1 then do;
						hi_metaData.first([title, code, text, values, valueTexts, elimination, "time"]);
						do until(hi_metaData.next([title, code, text, values, valueTexts, elimination, "time"]));
							if subCode=code then do;
								stubFraga='{"code":' || subCode || '", "selection":{"filter":"item", "values":["';
								subFraga=stubFraga || values || '"]';
								subFraga=subFraga || '}}';
								h_subFragor.ref([subCode, subFraga],[subCode, subFraga]);
							end;
						end;
					end;
					else do;
						rundaNr=0;
						hi_metaData.first([title, code, text, values, valueTexts, elimination, "time"]);
						stubFraga='{"code":' || subCode || '", "selection":{"filter":"item", "values":"';
						do until(hi_metaData.next([title, code, text, values, valueTexts, elimination, "time"]));
							if subCode=code then do;
								rundaNr=rundaNr+1;
								if rundaNr=cellerPerValue then do;
									stubFraga=stubFraga || ', ["' || values || '"]}}';
									subFraga=stubFraga;
									h_subFragor.ref([subCode, subFraga],[subCode, subFraga]);
									rundaNr=0;
									stubFraga='{"code":' || subCode || '", "selection":{"filter":"item", "values":"';
								end;
								else if rundaNr=1 then do;
									stubFraga=stubFraga || '["' || values || '"]';
								end;
								else do;
									stubFraga=stubFraga || ', ["' || values || '"]';
								end;
							end;
							if rundaNr=cellerPerValue then do;
								stubFraga=stubFraga || ', ["' || values || '"]';
								h_subFragor.ref([subCode, subFraga],[subCode, subFraga]);
								rundaNr=0;
								stubFraga='{"code":' || subCode || '", "selection":{"filter":"item", "values":"';
							end;
						end;
					end;
				end;
			end;
h_subFragor.output('work.subfraga');
		end;*skapaSubFraga;

	endpackage;
run;quit;