/********************************************************
Program: pxwebToSAS4
Upphovsperson: Anders Bergquist, Region Uppsala, anders.bergquist@regionupppsala.se/anders@fambergquist.se



**********************************************************/

proc ds2;
	package work.pxwebToSAS4 / overwrite=yes;
		* Allmänna variabler;
		declare nvarchar(8) libmap;
		* createMetaTabell;
		declare package hash h_metadata();
		declare package hiter hi_metadata('h_metadata');
		declare package hash h_metadata_tmp();
		declare package hiter hi_metadata_tmp('h_metadata_tmp');
		declare nvarchar(250) titel code text elimination tid values valueTexts;
		declare varchar(50) tid_cd;
		declare varchar(8) gLib;
		declare varchar(254) gTabell;
		declare varchar(200) scb_title scb_code scb_text scb_value scb_valueType;
		declare integer radNr gAntal;
		*Slut;
		forward getDataHelper getMetaJson skapaMetaTabell finnsTabell;

		method pxwebToSAS4();
			libmap='work';
		end;

		method getData(varchar(300) iUrl, integer maxCeller);
			declare varchar(8) sLib;
			declare varchar(32) sTabell iTidvar;
			
			sLib='WORK';
			sTabell=upcase(scan(iUrl,-1));

			getDataHelper(iUrl,sLib,sTabell);
		end;

		method getData(varchar(300) iUrl, integer maxCeller, varchar(8) sLib, varchar(254) sTabell, varchar(32) iTidVar);
			sLib=upcase(slib);
			sTabell=upcase(sTabell);
			getDataHelper(iUrl,sLib,sTabell);
		end;

		method getDataHelper(varchar(300) iUrl, varchar(8) sLib, varchar(254) sTabell);
			declare nvarchar(1000000) respons;

			respons=getMetaJson(iUrl);
*put respons=;
			if respons^='Error' then do;
				skapaMetaTabell(respons, sLib, sTabell);
			end;
			else do;
				put 'Fel vid hämning av metadata.';
			end;
		end;

		method skapaMetaTabell(varchar(1000000) respons, varchar(8) sLib, varchar(254) sTabell);
			declare package json j();
			declare package hash h_inlasta_tider();
			declare varchar(260) metaTabellNamn;
			declare integer rc tokenType parseFlags;
			declare varchar(250) token;
			declare varchar(25) tid_nm;

			h_metadata_tmp.keys([scb_title scb_code scb_text scb_value scb_valueType]);
			h_metadata_tmp.data([scb_title scb_code scb_text scb_value scb_valueType]);
			h_metadata_tmp.definedone();

			metaTabellNamn='META_' || sTabell;
			tid_nm = 'tid_cd';

			rc=j.createParser(respons);
			if rc=0 then do;
				j.getnexttoken(rc,token,tokenType,parseFlags);
				if j.isleftbrace(tokentype) then do;
					j.getnexttoken(rc,token,tokenType,parseFlags);
					do until(j.isrightbrace(tokentype));
						if lowcase(token)='title' then do;
							j.getnexttoken(rc,token,tokenType,parseFlags);
							scb_title=token;
						end;
						if j.isleftbracket(tokentype) then do;
							j.getnexttoken(rc,token,tokenType,parseFlags);
							do until(j.isrightbracket(tokentype));

								if j.isleftbrace(tokentype) then do;
								j.getnexttoken(rc,token,tokenType,parseFlags);

									do until(j.isrightbrace(tokentype));
******** Här börjar loopen med values och valuestext;
										if lowcase(token) = 'code' then do;
											j.getnexttoken(rc,token,tokenType,parseFlags);
											scb_code=token;
										end;
										if lowcase(token) = 'text' then do;
											j.getnexttoken(rc,token,tokenType,parseFlags);
											scb_text=token;
										end;
										if not j.isleftbracket(tokentype) then scb_valueType = lowcase(token);	
										if j.isleftbracket(tokentype) then do;
											j.getnexttoken(rc,token,tokenType,parseFlags);
											do until(j.isrightbracket(tokentype));
												scb_value=token;
put scb_title= scb_code= scb_text= scb_valueType= scb_value=;
												h_metadata_tmp.add([scb_title scb_code scb_text scb_valueType scb_value], [scb_title scb_code scb_text scb_valueType scb_value]);
												j.getnexttoken(rc,token,tokenType,parseFlags);												
											end;
										end;
										j.getnexttoken(rc,token,tokenType,parseFlags);
									end;
******************************************************;
* 1. Läs in den h_metadata_tmp i en h_metadata_tmp2 som har samma h_metadata_tmp2.keys([code text values valuesText]);
* 2. add h_metadata_tmp2 till h_metadata;
* 3. h_metadata_tmp.clear() h_metadata_tmp2.clear();
*put hv_items=;
									h_metadata_tmp.clear();
******* Här slutar loopen med values och valuestext;
								end;
								j.getnexttoken(rc,token,tokenType,parseFlags);
							end;
						end;
						j.getnexttoken(rc,token,tokenType,parseFlags);
					end;
					j.getnexttoken(rc,token,tokenType,parseFlags);
				end;
			end;

		end;

		method getMetaJson(varchar(300) iUrl) returns varchar(1000000);
			declare package http pxwebContent();
			declare nvarchar(1000000) respons;
			declare integer sc rc;

			pxwebContent.createGetMethod(iUrl);
			pxwebContent.executeMethod();
			sc=pxwebContent.getStatusCode();
	  	    if substr(sc,1,1) not in ('4', '5') then do;
	           	pxwebContent.getResponseBodyAsString(respons, rc);
	 		end;
		    else do;
		   		respons='Error';
				put 'Error: ' sc;
		    end;
		return respons;
		end;

		method finnsTabell(varchar(8) sLib, varchar(254) sTabell) returns integer;
			declare package sqlstmt s('select count(*) as gantal from dictionary.tables where TABLE_SCHEM=? AND table_name=?',[gLib gTabell]);
			declare integer antal;
			gLib=sLib;
			gTabell=sTabell;
			s.execute();
			s.bindresults([gantal]);
			s.fetch();
			antal=gantal;
			if antal > 0 then antal=1; else antal=0;
		return antal;
		end; *finnsTabell;

	endpackage;
run;quit;

