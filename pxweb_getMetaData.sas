/****************************************
Program: pxweb_getMetaData.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.4
Uppgift:
- Hämtar metadata från SCB/PX-Web.
Följande externa metoder finns;
- metaDataFirst(in_out varchar(250) io_title, in_out varchar(250) io_code, in_out varchar(250) io_text, in_out varchar(250) io_values, in_out varchar(250) io_valueTexts, in_out varchar(250) io_elimination, in_out varchar(250) io_time)
- metaDataNext(in_out varchar(250) io_title, in_out varchar(250) io_code, in_out varchar(250) io_text, in_out varchar(250) io_values, in_out varchar(250) io_valueTexts, in_out varchar(250) io_elimination, in_out varchar(250) io_time)
- metaDataNumItem() returns integer
- dataStorlekFirst(in_out varchar(250) io_code, in_out integer io_radNr, in_out integer io_CellerPerValue)
- dataStorlekNext(in_out varchar(250) io_code, in_out integer io_radNr, in_out integer io_CellerPerValue)
- hi_dataStorlek.next([code, radNr,CellerPerValue])

***********************************/
proc ds2;
	package &prgLib..pxweb_getMetaData / overwrite=yes;
		declare package &prgLib..pxweb_GemensammaMetoder g();
		declare package hash h_metaData();
		declare package hiter hi_metaData(h_metaData);
		declare package hash h_dataStorlek();
		declare package hiter hi_dataStorlek(h_dataStorlek);
		declare package hash h_dimensionerSum();
		declare package hiter hi_dimensionerSum(h_dimensionerSum);
		declare package hash h_contentSum();
		declare package hiter hi_contentSum(h_contentSum);
		declare integer radNr antal antalCeller cellerPerValue antalVar;
		declare varchar(250) title code text values valueTexts elimination "time" subCode oldCode;
		declare varchar(25000) subFraga;

		forward getJsonMeta parseJsonMeta printData skapaMetadataSamling skapaFrageStorlek;
		method pxweb_getMetaData();
		end;

		method getData(varchar(500) iUrl, integer maxCells, varchar(41) fullTabellNamn, varchar(32) tmpTable);
			declare varchar(25000) respons;
			respons=g.getData(iUrl);
			parseJsonMeta(respons, maxCells, fullTabellNamn);
			skapaMetadataSamling();
			skapaFrageStorlek(maxCells);
			h_metaData.output('work.meta_' || tmpTable);
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
			h_metaData.output(libTable);
		end;
** Skriver ut metadatatabellen, slut **;

** Metoder för att hämta data från package, start **;
		method getAntalCodes() returns integer;
			declare integer antalCodes;
			antalCodes=h_datastorlek.num_items;
			return antalCodes;
		end;

		method getAntalCeller() returns integer;
			declare integer m_antalCeller;
			antalCeller=1;
			hi_dataStorlek.first([code,radNr, antalCeller]);
			do until(hi_dataStorlek.next([code,radNr, antalCeller]));
				m_antalCeller=m_antalCeller*radNr;
			end;
			return antalCeller;
		end;

		method getAntalFragor() returns integer;
			declare integer antalCeller antalFragor maxCeller;
			maxCeller=100000;
			antalCeller=getAntalCeller();
			antalFragor=round((antalCeller/maxCeller)+0.5);
			return antalFragor;
		end;
** dataStorlek, start;
	**************** VARFÖR BEHÖVS TVÅ EX AV DESSA************************************;
		method dataStorlekFirst(in_out varchar io_code, in_out integer io_radNr, in_out integer io_CellerPerValue);
			hi_dataStorlek.first([code, radNr,CellerPerValue]);
			io_code=code;
			io_radNr=radNr;
			io_CellerPerValue=CellerPerValue;
		end;
		method dataStorlekFirst(in_out varchar i_code, in_out integer i_antalCeller);
			code=i_code;
			antalCeller=i_antalCeller;
			hi_dataStorlek.first([code, antal, antalCeller]);
			i_code=code;
			i_antalCeller=antalCeller;
		end;
		method dataStorlekNext(in_out varchar io_code, in_out integer io_radNr, in_out integer io_CellerPerValue);
		declare integer rc;
			hi_dataStorlek.next([code, radNr, CellerPerValue]);
			io_code=code;
			io_radNr=radNr;
			io_CellerPerValue=CellerPerValue;
		end;

		method dataStorlekNext(in_out varchar i_code, in_out integer i_antalCeller);
			code=i_code;
			antalCeller=i_antalCeller;
			hi_dataStorlek.next([code, antal, antalCeller]);
			i_code=code;
			i_antalCeller=antalCeller;
		end;
		method dataStorlekNumItem() returns integer;
			declare integer numItem;
				numItem=h_dataStorlek.num_items;
				hi_dataStorlek.next([code, antal, antalCeller]);
				do until(hi_dataStorlek.next([code, antal, antalCeller]));
*put 'Datastorlek: ' code antal antalCeller numItem;
				end;
			return numItem;
		end;
		method getLevelCode(integer level) returns varchar(250);
			declare integer i;
			do i=1 to level;
				if i=1 then do;
					hi_dataStorlek.first([code, radNr, CellerPerValue]);
				end;
				if i^=1 then do;
					hi_dataStorlek.next([code, radNr, CellerPerValue]);
				end;
			end;
			return code;
		end;
** datastorlek, slut;

*** Metoder för att hämta data ur hashtabellerna. start;
** metaData, start;
		method metaDataFirst(in_out varchar io_title, in_out varchar io_code, in_out varchar io_text, in_out varchar io_values, in_out varchar io_valueTexts, in_out varchar io_elimination, in_out varchar io_time);
			hi_metaData.first([title, code, text, values, valueTexts, elimination, "time"]);
			io_title=title;
			io_code=code;
			io_text=text;
			io_values=values;
			io_valueTexts=valueTexts;
			io_elimination=elimination;
			io_time="time";
		end;
		method metaDataNext(in_out varchar io_title, in_out varchar io_code, in_out varchar io_text, in_out varchar io_values, in_out varchar io_valueTexts, in_out varchar io_elimination, in_out varchar io_time);
		declare integer rc;
			hi_metaData.next([title, code, text, values, valueTexts, elimination, "time"]);
			io_title=title;
			io_code=code;
			io_text=text;
			io_values=values;
			io_valueTexts=valueTexts;
			io_elimination=elimination;
			io_time="time";
		end;
		method metaDataNumItem() returns integer;
			declare integer numItem;
				numItem=h_metaData.num_items;
			return numItem;
		end;
** metaData, start;

*** Metoder för att hämta data ur hashtabellerna. slut;
		method skapaMetadataSamling();

			h_dimensionerSum.keys([code]);
			h_dimensionerSum.data([code, antalVar]);
			h_dimensionerSum.ordered('A');
			h_dimensionerSum.DefineDone();

			h_contentSum.keys([code]);
			h_contentSum.data([code, antalVar]);
			h_contentSum.ordered('A');
			h_contentSum.DefineDone();

			hi_metaData.first([title, code, text, values, valueTexts, elimination, "time"]);
			antalVar=0;
			oldCode=code;
			do until(hi_metaData.next([title, code, text, values, valueTexts, elimination, "time"]));
				if oldCode=code then do;
					antalVar=antalVar+1;
				end;
				else do;
					if oldCode ^= 'ContentsCode' then do;
						h_dimensionerSum.ref([oldCode],[oldCode, antalVar]);
					end;
					else do;
						h_contentSum.ref([oldCode],[oldCode, antalVar]);
					end;
					antalVar=1;
					oldCode=code;
				end;
			end;
			if oldCode ^= 'ContentsCode' then do;
				h_dimensionerSum.ref([oldCode],[oldCode, antalVar]);
			end;
			else do;
				h_contentSum.ref([oldCode],[oldCode, antalVar]);
			end;
		end;

		method skapaFrageStorlek( integer maxCells);
			declare integer rc antalDimCeller antalDimCeller_old divisor tmpCeller;
			h_dataStorlek.keys([code]);
			h_dataStorlek.data([code,radNr,cellerPerValue]);
			h_dataStorlek.ordered('A');
			h_dataStorlek.defineDone();

			radNr=0;
			rc=hi_contentSum.first([code, antalVar]);
			antalDimCeller=round((maxCells/antalVar)-0.5);
			rc=hi_dimensionerSum.first([code, antalVar]);
			do until(hi_dimensionerSum.next([code, antalVar]));
				if antalVar=1 then do;
					cellerPerValue=1;
					radNr=1;
					h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
					radNr=0;
				end;
				else if antalVar<=antalDimCeller then do;
					cellerPerValue=antalVar;
					radNr=antalVar;
					h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
					antalDimCeller_old=antalDimCeller;
					antalDimCeller=antalDimCeller_old/cellerPerValue;
					radNr=0;
				end;
				else if antalVar > antalDimCeller then do;
					divisor=1;
					do until(tmpCeller<=antalDimCeller);
						divisor=divisor+1;
						tmpCeller=round((antalVar/divisor)-0.5)*(antalDimCeller);
						radNr=radNr+1;
					end;
					cellerPerValue=tmpCeller;
					h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
					antalDimCeller_old=antalDimCeller;
					antalDimCeller=antalDimCeller_old/cellerPerValue;
					radNr=0;
				end;
				radNr=radNr+1;
			end;
		end;



** Metoder för att hämta data från package, slut **;

		method parseJsonMeta(varchar(25000) iRespons, integer maxCells, varchar(41) fullTabellNamn);
			declare package hash parsMeta();
			declare package hiter hi_parsMeta(parsMeta);
			declare package json j();
			declare varchar(250) token;
			declare varchar(25) senasteTid;
			declare integer rc tokenType parseFlags tmpCeller divisor;
*Senaste tid är där laghämtningen ska styras ifrån. Bra att redan nu hämtas bara senate data.;
			senasteTid=g.getSenasteTid(fullTabellNamn);
			antalCeller=1;

			parsMeta.keys([radNr]);
			parsMeta.data([title, code, text, values, valueTexts]);
			parsMeta.ordered('A');
			parsMeta.defineDone();

			h_metaData.keys([code, values]);
			h_metaData.data([title, code, text, values, valueTexts, elimination, "time"]);
			h_metaData.ordered('A');
			h_metaData.defineDone();

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
						hi_parsmeta.first([title, code, text, values, valueTexts]);
						do until(hi_parsmeta.next([title, code, text, values, valueTexts]));
							if("time"='true' and (senasteTid<values)) then do;* and (senasteTid='' or senasteTid > values)) then do;
								h_metaData.ref([code, values],[title, code, text, values, valueTexts,elimination, "time"]);
							end;
							else if "time" ^= 'true' then do;
								h_metaData.ref([code, values],[title, code, text, values, valueTexts,elimination, "time"]);
							end;
						end;
						parsmeta.clear();
						j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				end;
				j.getNextToken(rc,token,tokenType,parseFlags);
			end;
		end;*parseJsonMeta;



	endpackage;
run;quit;