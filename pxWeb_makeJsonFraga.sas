/****************************************
Program: pxweb_makeJsonFraga.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Skapar json-fråga till datahämtning
***********************************/


proc ds2;
	package work.pxweb_makeJsonFraga / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		forward getJsonMeta parseJsonMeta;
		method pxweb_makeJsonFraga();
		end;

		method skapaFraga(varchar(500) iUrl);
			declare varchar(25000) respons;
			respons=getJsonMeta(iUrl);
			parseJsonMeta(respons);
		end;*skapaFraga;

		method getJsonMeta(varchar(500) iUrl) returns varchar(25000);
			declare varchar(25000) respons;
			respons=g.getData(iUrl);
		return respons;	
		end;*getMeta;

		method parseJsonMeta(varchar(25000) iRespons);
			declare package hash parsMeta();
			declare package hiter hparsMeta(parsMeta);
			declare package hash metaData();
			declare package json j();
			declare varchar(250) token title code text values valueTexts;
			declare integer rc tokenType parseFlags radNr;

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
						do until(j.ISRIGHTBRACE(tokenType));
							if token='code' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								code=token;
							end;
							else if token='text' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								text=token;
							end;
							else if token='values' then do;
								radNr=0;
								j.getNextToken(rc,token,tokenType,parseFlags);
								do until(j.isrightbracket(tokenType));
									if j.isleftbracket(token) then do;
									end;
									else do;
										radNr=radNr+1;
										values=token;
	*Add till hash;
									end;
									j.getNextToken(rc,token,tokenType,parseFlags);
								end;
							end;
							else if token='valueTexts' then do;
								radNr=0;
								j.getNextToken(rc,token,tokenType,parseFlags);
								do until(j.isrightbracket(tokenType));
									if j.isleftbracket(token) then do;
									end;
									else do;
										radNr=radNr+1;
										valueTexts=token;
	*Add till hash;
									end;		
									j.getNextToken(rc,token,tokenType,parseFlags);
								end;
							end;
							j.getNextToken(rc,token,tokenType,parseFlags);
						end;
		*Slinga uppdatear metahashen;
						j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				end;
				j.getNextToken(rc,token,tokenType,parseFlags);
			end;

		end;*parseJsonMeta;
	endpackage;
run;quit;