/****************************************
Program: pxwebToSAS2
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 2 beta
Installation: �ndra p� sasuser om du vill ha filen i ett annan bibliotek.
Anv�ndning:
Classen best�r av tv� funktioner. getData() och skrivTillTabell();
getData(url, post) h�mtar data fr�n SCB, eller annat pxweb API. Har dock inte testat det.
	url=adressen och post �r jsonfr�gan.
skrivTillTabell(tabellnamn) skriver ut resultatet till en sas-tabell och nollst�ller h�mtningen. Denna anv�nds efter getData().
	funktionen �r separta eftersom den anv�nds efter evt. loop som h�mtar mer data �n 50000 rader.
OBS! SCB till�ter max 50000 celler vid en h�mtning. F�r att h�mta mer m�ste programmet loopas. Se exempel fil. Anv�ndaren ansvarar
sj�lv f�r detta.
***********************************/

proc ds2;
	package &instprog..pxwebToSAS2 / overwrite=yes;
		declare package http pxwebContent();
		declare package hash h_metadata();
		declare package hiter hi_metadata('h_metadata');
		declare package hash h_metadata_tmp();
		declare package hiter hi_metadata_tmp('h_metadata_tmp');
		declare package hash h_antalCeller();
		declare package hiter hi_antalCeller('h_antalCeller');
		declare package hash h_antalCeller_product();
		declare package hiter hi_antalCeller_product('h_antalCeller_product');
		declare package hash h_valdaKoder();
		declare package hash h_ickeValdaKoder();
		declare package hiter hi_ickeValdaKoder('h_ickeValdaKoder');
		declare package hash h_jsonVarKoder();
		declare package hiter hi_jsonVarKoder('h_jsonVarKoder');

		declare varchar(1000) url;
		declare integer radNr cells optCells batchSize antal hashDefined updateExist;
		declare varchar(250) optCodes[10];
		declare varchar(250) titel code text elimination tid values valueTexts cellName jsonQ cellCode varLista;
		declare varchar(50000) startJson;
		declare varchar(8) lib;
		declare varchar(2000) tabell;

		dcl private varchar(5000000) character set "utf-8" respons;
		dcl private varchar(50000) post;
		*dcl private varchar(25) tabell;
        dcl integer rc sc myrc;
		vararray varchar(100) d[20];
		vararray double c[20];
		dcl integer antal;
		dcl varchar(8) lib;

	    dcl package http pxwebQuery();
		dcl package hash h_scbIndata();


		forward getMetaData parseMetaData makeCombTabell findOptCombination arrayEmpty arrayChooseVar existUpdate;
		forward makeStartJson makeLoopJson questionPxWeb questionPxWebHelper finnsTabell saveMetaData endFetching parseData requestData getScBData;

		method pxwebToSAS2();*Konstruktor;
			h_metadata.keys([radNr]);
			h_metadata.data([radNr titel code text elimination tid values valueTexts]);
			h_metadata.ordered('A');
			h_metadata.defineDone();
			hashDefined=0;
		end;

		method getData(varchar(1000) iUrl, integer maxCells) returns integer;*Huvudfunktionen utan tidsbegr�nsning;
			declare varchar(1000000) respons;
			declare varchar(32) tabellNamn;
			declare integer updateFinns;

			tabellNamn=scan(iUrl,-1);
			if finnsTabell('work', tabellNamn)=1 then do;
				sqlexec('drop table work.' || tabellNamn);
			end;
			if finnsTabell('work', 'meta_' || tabellNamn)=1 then do;
				sqlexec('drop table work.meta_' || tabellNamn);
			end;
			respons=getMetaData(iUrl);
			parseMetaData(respons, '');
			if existUpdate()=1 then do;
				makeCombTabell(maxCells);
				makeStartJson();
				makeLoopJson(maxCells, optCells);
				questionPxWeb(iUrl);
				endFetching(tabellNamn);
				saveMetaData(iUrl);
				updateFinns=1;
			end;
			else do;
				put 'Ingen uppdatering finns.';
				updateFinns=0;
			end;
			return updateFinns;
		end;


		method getData(varchar(1000) iUrl, integer maxCells, varchar(30) iFromTid) returns integer;*Huvudfunktionen med tidsbegr�nsning;
			declare varchar(1000000) respons;
			declare varchar(32) tabellNamn;
			declare integer updateFinns;

			tabellNamn=scan(iUrl,-1);
			if finnsTabell('work', tabellNamn)=1 then do;
				sqlexec('drop table work.' || tabellNamn);
			end;
			if finnsTabell('work', 'meta_' || tabellNamn)=1 then do;
				sqlexec('drop table work.meta_' || tabellNamn);
			end;
			respons=getMetaData(iUrl);
			parseMetaData(respons, iFromTid);
			if existUpdate()=1 then do;
				makeCombTabell(maxCells);
				makeStartJson();
				makeLoopJson(maxCells, optCells);
				questionPxWeb(iUrl);
				endFetching(tabellNamn);
				saveMetaData(iUrl);
				updateFinns=1;
			end;
			else do;
				put 'Ingen uppdatering finns.';
				updateFinns=0;
			end;
			return updateFinns;
		end;

		method saveMetaData(varchar(1000) iUrl);
			declare varchar(32) metaTabellNamn;
			MetaTabellNamn='meta_' || scan(iUrl,-1);
			if finnsTabell('work', metaTabellNamn)=1 then do;
				sqlexec('drop table work.' || metaTabellNamn);
			end;
			h_metadata.output('work.' || metaTabellNamn);
			
		end;

		method existUpdate() returns integer;*1=Uppdatering finns, 0=Uppdatering saknas;
			declare package hiter hi_findTid('h_metadata');
			declare integer tidTrue;
			tidTrue=0;
			hi_findTid.first([radNr titel code text elimination tid values valueTexts]);
			do until(hi_findTid.next([radNr titel code text elimination tid values valueTexts]));
				if tid='true' then tidTrue=1;
			end;
			return tidTrue;
		end;

		method questionPxWeb(varchar(1000) iUrl);
			declare varchar(250) mittV[dim(optCodes)];
			declare varchar(32) tabellNamn;
			declare integer i rc;

			rc=hi_ickeValdaKoder.first([cellName]);
			if rc=0 then do;
				i=1;
				do until(hi_ickeValdaKoder.next([cellName]));
					mittV[i]=cellName;
					i=i+1;
				end;
				questionPxWebHelper(mittV, startJson, iUrl);
			end;
			else do;
				startJson=startJson || '], "response": {"format": "json"}}';
				tabellNamn=scan(iUrl,-1);
				getScBData(iUrl,startJson,tabellNamn);
			end;
		end;

		method questionPxWebHelper(varchar(250) mittV[*], varchar(50000) startCode, varchar(1000) iUrl);
			declare integer i empty;
			declare varchar(250) actCode;
			declare varchar(50000) startCode2;
			declare varchar(32) tabellNamn;
			declare package hiter hi_jsonVarKoderL('h_jsonVarKoder');
			tabellNamn=scan(iUrl,-1);
			empty=arrayEmpty(mittV);
			if empty=1 then do;
			startCode=startCode || '], "response": {"format": "json"}}';

			getScBData(iUrl,startCode,tabellNamn);
			end;
			else do;
				actCode=mittV[1];
			***** arrayRemoveFirst actCode ************;
				do i=1 to dim(mittV);
					if i = dim(mittV) then mittV[i]='';
					else mittV[i]=mittV[i+1];
				end;
			***** end ****************************;
		
				hi_jsonVarKoderL.first([code jsonQ]);
				do until(hi_jsonVarKoderL.next([code jsonQ]));
					if code=actCode then do;
						startCode2=startCode || jsonQ;
						questionPxWebHelper(mittV, startCode2, iUrl);
					end;
				end;
		****** L�gger tillbaka, unchoice **********************;

				do i=dim(mittV) to 2 by -1;
					mittV[i]=mittV[i-1];
				end;
				mittV[1]=actCode;
			end;
		end;

		method makeLoopJson(integer maxCells, integer optCells);
			declare integer i j rc batchSize;
			declare varchar(250) v;

			h_valdaKoder.keys([cellName]);
			h_valdaKoder.defineDone();
			h_ickeValdaKoder.keys([cellName]);
			h_ickeValdaKoder.data([cellName]);
			h_ickeValdaKoder.defineDone();
			h_jsonVarKoder.keys([code jsonQ]);
			h_jsonVarKoder.data([code jsonQ]);
			h_jsonVarKoder.defineDone();

			batchSize=int(maxCells/optCells);
	**** L�gger alla valda koder i en hash ***;
			cellName='ContentsCode';
			h_valdaKoder.add([cellName]);
			do i=1 to dim(optCodes);
				if optCodes[i]^='' then do;
					cellName=optCodes[i];
					h_valdaKoder.add([cellName]);
				end;
			end;
	**** Identifierar icke valda koder, plus deras antal celler ****;
			hi_antalCeller.first([code cells]);
			do until(hi_antalCeller.next([code cells]));
				if h_valdaKoder.find([code])^= 0 then do;
					h_ickeValdaKoder.add([code],[code]);
				end;
			end;
			j=1;
			rc=hi_ickeValdaKoder.first([cellName]);
			if rc=0 then do;
				do until(hi_ickeValdaKoder.next([cellName]));
					hi_metadata.first([radNr titel code text elimination tid values valueTexts]);
					do until(hi_metadata.next([radNr titel code text elimination tid values valueTexts]));
						if cellName=code then do;
							if j=1 and j=batchSize then do;
								jsonQ=', {"code":"' || code || '", "selection":{"filter":"item", "values":["' || strip(values) || '"]}}';
								j=1;
								h_jsonVarKoder.add([code jsonQ],[code jsonQ]);
							end;
							else if j=1 and j<batchSize then do;
								jsonQ=', {"code":"' || code || '", "selection":{"filter":"item", "values":["' || strip(values) || '"';
								j=j+1;
							end;
							else if j<batchSize then do;
								jsonQ=jsonQ || ',"' || strip(values) || '"';
								j=j+1;
								cellCode=code;
							end;
							else if j=batchSize then do;
								jsonQ=jsonQ || ',"' || strip(values) || '"]}}';
								j=1;			
								h_jsonVarKoder.add([code jsonQ],[code jsonQ]);
							end;
						end;
					end;
					if substr(jsonQ,length(jsonQ)-2)^=']}}' then do;
						jsonQ=jsonQ || ']}}';
						h_jsonVarKoder.add([cellCode jsonQ],[cellCode jsonQ]);
					end;
				end;
			end;*rc=0;
		end;

		method makeStartJson();
			declare integer i first;

			startJson='{"query": [{"code":"ContentsCode", "selection":{"filter":"all", "values":["*"]}}';
			do i=1 to dim(optCodes);
				if optCodes[i]^='' and optCodes[i] ^= 'Tid' then do;
					startJson=startJson || ', {"code":"' || optCodes[i] || '", "selection":{"filter":"all", "values":["*"]}}';			
				end;
				else if optCodes[i] = 'Tid' then do;
					first=1;
					startJson=startJson || ', {"code":"' || optCodes[i] || '", "selection":{"filter":"item", "values":[';
					hi_metadata.first([radNr titel code text elimination tid values valueTexts]);
					do until(hi_metadata.next([radNr titel code text elimination tid values valueTexts]));
						if first=1 and code = 'Tid' then do;
							startJson = startJson || '"' || values || '"';
							first=0;
						end;
						else if code = 'Tid' then do;
							startJson = startJson || ',"' || values || '"';
						end;
					end;
					startJson = startJson || ']}}';
				end;
			end;
		end;

		method makeCombTabell(integer maxCells);
			declare integer rc i;
			declare varChar(250) varCode[dim(optCodes)] choosen[dim(optCodes)];

			h_antalCeller.keys([cellName]);
			h_antalCeller.data([cellName cells]);
			h_antalCeller.defineDone();
			h_antalCeller_product.keys([cellName]);
			h_antalCeller_product.data([cellName cells]);
			h_antalCeller_product.defineDone();

			hi_metadata.first([radNr titel code text elimination tid values valueTexts]);
			do until(hi_metadata.next([radNr titel code text elimination tid values valueTexts]));
				rc=h_antalCeller.check([code]);
				if rc=0 then do;
					h_antalCeller.find([code],[code cells]);
					cells=cells+1;
					h_antalCeller.replace([code],[code cells]);
				end;
				else do;
					cells=1;
					h_antalCeller.add([code],[code cells]);
				end;
			end;
			hi_antalCeller.first([code cells]);
			do until(hi_antalCeller.next([code cells]));
				if code ^= 'ContentsCode' then do;
					h_antalCeller_product.add([code],[code cells]);
				end;
			end;
			optCells=0;
			i=1;
			hi_antalCeller_product.first([code cells]);
			do until(hi_antalCeller_product.next([code cells]));
				varCode[i]=code;
				i=i+1;
			end;
			code='ContentsCode';
			h_antalCeller.find([code],[code cells]);
			findOptCombination(varCode, choosen, cells, maxCells);

		end;

		method findOptCombination(varChar(250) varCodes[*], varChar(250) choosen[*], integer productSoFar, integer maxCells);
			declare integer i empty position numChoose slut numLocalCells;
			declare varChar(250) actCode ChooseCode;
			empty=arrayEmpty(varCodes);
			if empty=1 or productSoFar > maxCells then do;
				if productSoFar <= maxCells then do;
					if productSoFar > optCells then do;
						optCells=productSoFAr;
						optCodes:=choosen;
					end;
				end;
			end;
			else do;
				actCode=varCodes[1];
				code=actCode;
				h_antalCeller.find([code], [code, cells]);
				numLocalCells=cells;;
				productSoFar=productSoFar*numLocalCells;

		***** arrayRemoveFirst actCode ************;
				do i=1 to dim(varCodes);
					if i = dim(varCodes) then varCodes[i]='';
					else varCodes[i]=varCodes[i+1];
				end;
		***** end ****************************;
		***** arrayAddLast*******************;
				numChoose=0;
				do until(anyalnum(chooseCode)=0);
					numChoose=numChoose+1;
					if numChoose <= dim(choosen);
					ChooseCode=choosen[numChoose];
				end;
				choosen[numChoose]=actCode;
	    ******* end ****************************;
				findOptCombination(varCodes,choosen, productSoFar, maxCells);

				choosen[numChoose]='';
				productSoFar=productSoFar/numLocalCells;
				findOptCombination(varCodes,choosen, productSoFar, maxCells);
		****** L�gger tillbaka, unchoice **********************;

				do i=dim(varCodes) to 2 by -1;
					varCodes[i]=varCodes[i-1];
				end;
				varCodes[1]=actCode;
			end;
		end;

		method arrayEmpty(varchar(250) iArray[*]) returns integer;
			declare integer empty i;
			empty=1;
			do i=1 to dim(iArray);
				if anyalnum(iArray[i])^=0 then empty=0;
			end;
			return empty;
		end;

		method parseMetaData(varchar(1000000) iRespons, varchar(30) iFromTid);*L�ser in pxWebs Json till hash-tabell;
			declare package json j();
			declare varchar(250) token;
			declare integer rc tokenType parseFlags;

			h_metadata_tmp.keys([radNr]);
			h_metadata_tmp.data([radNr code text elimination tid values valueTexts]);
			h_metadata_tmp.ordered('A');
			h_metadata_tmp.defineDone();

			radNr=0;
			rc=j.createParser(iRespons);
			j.getNextToken(rc,token,tokenType,parseFlags);
			do while(rc=0);
				if token='title' then do;
					j.getNextToken(rc,token,tokenType,parseFlags);
					titel=token;
				end;
				else if token='variables' then do;
				code='';
				text='';
				elimination='false';
				tid='false';
					do while(not j.ISRIGHTBRACKET(tokenType));
****************************************************************************;
						do while(not j.ISRIGHTBRACE(tokenType));
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
								hi_metadata_tmp.first([radNr code text elimination tid values valueTexts]);
								do until(hi_metadata_tmp.next([radNr code text elimination tid values valueTexts]));
									elimination=token;	
									h_metadata_tmp.replace([radNr],[radNr code text elimination tid values valueTexts]);								
								end;
								elimination='false';
							end;
							else if token='time' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								tid=token;*loop igenom h_metadata_tmp f�r att l�gga till v�rdet.;
								hi_metadata_tmp.first([radNr code text elimination tid values valueTexts]);
								do until(hi_metadata_tmp.next([radNr code text elimination tid values valueTexts]));
									tid=token;			
									h_metadata_tmp.replace([radNr],[radNr code text elimination tid values valueTexts]);								
								end;
								tid='false';
							end;
							else if token='values' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								do while(not j.ISRIGHTBRACKET(tokenType));
									if(not j.ISLEFTBRACKET(tokenType)) then do;	
										elimination='false';
										tid='false';
										values=token;
										valueTexts='';	
										h_metadata_tmp.add([radNr],[radNr code text elimination tid values valueTexts]);
										radNr=radNr+1;
									end;
								j.getNextToken(rc,token,tokenType,parseFlags);
								end;
							end;
							else if token='valueTexts' then do;
								hi_metadata_tmp.first([radNr code text elimination tid values valueTexts]);
								j.getNextToken(rc,token,tokenType,parseFlags);
								do while(not j.ISRIGHTBRACKET(tokenType));
									if(not j.ISLEFTBRACKET(tokenType)) then do;	
										elimination='false';
										tid='false';
										valueTexts=token;
										h_metadata_tmp.replace([radNr],[radNr code text elimination tid values valueTexts]);
										hi_metadata_tmp.next([radNr code text elimination tid values valueTexts]);
									end;
								j.getNextToken(rc,token,tokenType,parseFlags);
								end;
							end;
						j.getNextToken(rc,token,tokenType,parseFlags);

						end;
						hi_metadata_tmp.first([radNr code text elimination tid values valueTexts]);
						do until(hi_metadata_tmp.next([radNr code text elimination tid values valueTexts]));
							if iFromTid='' then do;
								h_metadata.add([radNr],[radNr titel code text elimination tid values valueTexts]);
							end;
							else ; 
							if iFromTid^='' then do;
								if iFromTid < values and tid='true' then do;
									h_metadata.add([radNr],[radNr titel code text elimination tid values valueTexts]);
								end;
								else;
								if tid='false' then do;
									h_metadata.add([radNr],[radNr titel code text elimination tid values valueTexts]);
								end;
							end;
						end;
					h_metadata_tmp.clear();
					radNr=radNr+1;
****Slut p� loopen********************************************************;
					j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				j.getNextToken(rc,token,tokenType,parseFlags);
				end;
			j.getNextToken(rc,token,tokenType,parseFlags);
			end;
*			h_metadata.output('work.h_metadata');
		end;

		method getMetaData(varchar(1000) iUrl) returns varchar(1000000);*H�mtar metadata fr�n SCB;
			declare varchar(1000000) respons;
			declare integer sc rc;
			pxwebContent.createGetMethod(iUrl);
			pxwebContent.executeMethod();

			sc=pxwebContent.getStatusCode();
	  	    if substr(sc,1,1) not in ('4', '5') then do;
	           	pxwebContent.getResponseBodyAsString(respons, rc);
	 		end;
		   else do;
		   		respons='Error';
		   end;
		return respons;
		end;

		method getScBData(varchar(250) iUrl, varchar(50000) iPost, varchar(200) utTabell);
			dcl varchar(2000) sql;
			dcl double startTid slutTid tid;
			dcl varchar(11) tempFil;
			dcl integer iSize iNum iMemSize;
			startTid=datetime(); * S�tter tid f�r n�r h�mtningen startade;
			requestData(iUrl, iPost);*H�mtar data;
			if respons^='Error' then do;
				parseData(); *parsData;
				myrc= 0;
			end;
			else do;
				myrc= 1;
			end;

			if hashDefined=1 then do;
				tempFil='tmp' || strip(put(time(),8.));
				if finnsTabell('work', utTabell)=0 then do;
					sql='create table ' || utTabell || ' as ' || varLista || ' from ' || tempFil;
				end;
				else do;
					sql='insert into ' || utTabell || ' ' || varLista || '  from ' || tempFil;
				end;
				iSize=h_scbIndata.item_size;
				iNum=h_scbIndata.num_items;
				iMemSize=(iSize*iNum)/(1024*1024);
				if iMemSize > 1100 then do;
					h_scbIndata.output(tempFil);
					sqlexec(sql);
					put 'Item size: ' iSize ' Number items: ' iNum ' total memory used(Mb): ' iMemSize;
					h_scbIndata.clear();
					sqlexec('drop table ' || tempFil);
					hashDefined=1;
				end;
			end;*hashDefined=1;

			do while(datetime()-startTid<1);
			end;*tom loop f�r att undvika att det blir mer �n 10 fr�gor p� 10 sekunder. SCB:s begr�nsning.;
		end;*getData;


		method requestData(varchar(250) iUrl, varchar(50000) iPost);
           pxwebQuery.createPostMethod(iUrl);
           pxwebQuery.setRequestContentType('application/json; charset=utf-8');
           pxwebQuery.setRequestBodyAsString(iPost);
           pxwebQuery.executeMethod();
     
           sc=pxwebQuery.getStatusCode();
           if substr(sc,1,1) not in ('4', '5') then do;
           		pxwebQuery.getResponseBodyAsString(respons, rc);
           end;
		   else do;
		   		respons='Error';
		   end;
		end;

		method parseData();
			dcl int tokenType parseFlags rc typ;
			dcl private nvarchar(300) sql;
			dcl private nvarchar(128) token;
			dcl private nvarchar (500) colname valuesName hKeys hdata;
			dcl private integer loopD loopC raknareD raknareC;* d �r SCB:s kod f�r dimension och c �r SCB:s kod f�r inneh�ll=data;
			dcl private char(2) iKey iData;
			dcl package json j();
		
			rc=j.createParser(respons);
			raknareD=0;
			raknareC=0;
			varLista='';

			do while(rc=0);
				j.getNextToken(rc,token,tokenType,parseFlags);
				if token='columns' then do;
					do while(not j.ISRIGHTBRACKET(tokenType));
						j.getNextToken(rc,token,tokenType,parseFlags);
						if token='code' then do;
							j.getNextToken(rc,token,tokenType,parseFlags);
							/** F�r att undvika numerisk b�rjan p� kollumnnamn **/
							if anydigit(token)=1 then token = 'X' || token;
							token=transtrn(token,'!','z1');
							token=transtrn(token,'�','z3');
							token=transtrn(token,'$','z4');
							token=transtrn(token,'~','z5');
							token=transtrn(token,'�','z6');
							/** Slut **/
							colname=token;
						end;*code;
						if token='type' then do;
							j.getNextToken(rc,token,tokenType,parseFlags);
							if token in ('d' 't') then do;
								raknareD=raknareD+1;
								if varLista='' then do;
									varLista='SELECT d' || raknareD || ' AS ' || colname;
								end; *f�rsta delen i listan;
								else do;
									varLista=varLista || ', d' || raknareD || ' AS ' || colname;
								end;*l�gger till i listan;
							end;
							else if token='c' then do;
								raknareC=raknareC+1;
								if varLista='' then do;
									varLista='SELECT c' || raknareC || ' AS ' || colname;
								end; *f�rsta delen i listan;
								else do;
									varLista=varLista || ', c' || raknareC || ' AS ' || colname;
								end;*l�gger till i listan;
						end;
							else do;
							raknareD=raknareD+1;
								if varLista='' then do;
									varLista='SELECT d' || raknareD || ' AS ' || colname;
								end; *f�rsta delen i listan;
								else do;
									varLista=varLista || ', d' || raknareD || ' AS ' || colname;
								end;*l�gger till i listan;
							end;
						end;*type;
					end;*H�mtar delarna i Columns;
					if hashDefined=0 then do;
						do loopD=1 to raknareD;
							iKey='d' || loopD;
							h_scbIndata.definekey(iKey);
							h_scbIndata.definedata(iKey);
						end;
						do loopC=1 to raknareC;
							iData='c' || loopC;
							h_scbIndata.definedata(iData);
						end;					
						h_scbIndata.ordered('A');
						h_scbIndata.defineDone();
						hashDefined=1;
					end; *hashDefined;
				end;*Columns;

				if token='comment' then do;
					do while(not j.ISRIGHTBRACKET(tokenType));

					j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				end;*comment;

				if token='data' then do;
					raknareD=1;
					raknareC=1;
					do while(not j.isrightbracket(tokenType));
						j.getNextToken(rc,token,tokenType,parseFlags);
							if j.isleftbrace(tokenType) then do;
							do while(not j.isrightbrace(tokenType));
								j.getNextToken(rc,token,tokenType,parseFlags);
								if token='key' then do;
									do while(not j.isrightbracket(tokenType));
									j.getNextToken(rc,token,tokenType,parseFlags);
										if(not j.isrightbracket(tokenType) and not j.isleftbracket(tokenType)) then do;
											d[raknareD]=token;
											raknareD=raknareD+1;
										end;*H�mtar token;
									end;*h�mtar v�rdet i key;
								end;*h�mtar key;
								if token='values' then do;
									do while(not j.isrightbracket(tokenType));
									j.getNextToken(rc,token,tokenType,parseFlags);
										if(not j.isrightbracket(tokenType) and not j.isleftbracket(tokenType)) then do;
											c[raknareC]=token;
											raknareC=raknareC+1;

										end;*H�mtar token;
									end;*H�mtar v�rdet i values;
								h_scbIndata.ref();
								raknareD=1;
								raknareC=1;
								end;*H�mtar values;
							end;*h�mtar kategori, key eller values;
						end;
					end;
				end;*token=data;
			end;*parseLoop;
		end; *parseData;

		method finnsTabell(varchar(8) iLib, varchar(2000) iTabell) returns integer;
			dcl package sqlstmt s('select count(*) as antal from dictionary.tables where TABLE_SCHEM=? AND table_name=?',[lib tabell]);
			tabell=upcase(iTabell);
			lib=upcase(iLib);
			s.execute();
			s.bindresults([antal]);
			s.fetch();
			if antal > 0 then antal=1; else antal=0;
		return antal;
		end;*finnsTabell;

	method endFetching(varchar(200) utTabell);
			dcl varchar(2000) sql;
			dcl varchar(11) tempFil;
			dcl integer iSize iNum iMemSize;

			if hashDefined=1 then do;
				tempFil='tmp' || strip(put(time(),8.));
				if finnsTabell('work', utTabell)=0 then do;
					sql='create table ' || utTabell || ' as ' || varLista || ' from ' || tempFil;
				end;
				else do;
					sql='insert into ' || utTabell || ' ' || varLista || '  from ' || tempFil;
				end;
				h_scbIndata.output(tempFil);
				sqlexec(sql);
				iSize=h_scbIndata.item_size;
				iNum=h_scbIndata.num_items;
				iMemSize=(iSize*iNum)/(1024*1024);
				put 'Item size: ' iSize ' Number items: ' iNum ' total memory used(Mb): ' iMemSize;
				h_scbIndata.clear();
				sqlexec('drop table ' || tempFil);
				hashDefined=1;
			end;*hashDefined=1;
		end; *skrivTillTabell;

	endpackage ;
run;quit;


