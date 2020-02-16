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
		declare integer radNr antal;
		declare varchar(250) title code text values valueTexts elimination "time";

		forward getJsonMeta parseJsonMeta printData;
		method pxweb_getMetaData();
		end;

		method getData(varchar(500) iUrl);
			declare varchar(25000) respons;
			respons=getJsonMeta(iUrl);
			parseJsonMeta(respons);
		end;*skapaFraga;

*Fundera om nedanstående metod behövs;
		method getJsonMeta(varchar(500) iUrl) returns varchar(25000);
			declare varchar(25000) respons;
			respons=g.getData(iUrl);
		return respons;	
		end;*getJsonMeta;

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

		method parseJsonMeta(varchar(25000) iRespons);
			declare package hash parsMeta();
			declare package hiter hiparsMeta(parsMeta);
			declare package json j();
			declare varchar(250) token;
			declare integer rc tokenType parseFlags;

			parsMeta.keys([radNr]);
			parsMeta.data([title, code, text, values, valueTexts]);
			parsMeta.ordered('A');
			parsMeta.defineDone();

			metaData.keys([code, values]);
			metaData.data([title, code, text, values, valueTexts, elimination, "time"]);
			metaData.ordered('A');
			metaData.defineDone();

			h_dataStorlek.keys([code]);
			h_dataStorlek.data([code antal]);
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
							metaData.ref([code, values],[title, code, text, values, valueTexts,elimination, "time"]);
						end;
						h_dataStorlek.ref([code],[code,radNr]);
						parsmeta.clear();
						j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				end;
				j.getNextToken(rc,token,tokenType,parseFlags);
			end;
		end;*parseJsonMeta;
	endpackage;
run;quit;