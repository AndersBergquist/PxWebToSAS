/****************************************
Program: pxweb_makeJsonFraga.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Skapar json-fr�ga till datah�mtning
***********************************/
proc ds2;
	package work.pxweb_makeJsonFraga / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		declare package work.pxweb_getMetaData getMetaData();
		declare package hash h_subFragor();
		declare varchar(250) subCode;
		declare varchar(25000) subFraga;
		forward skapaSubFraga skapaFraga skapaFragaHelper;

		method pxweb_makeJsonFraga();
		end;

		method skapaFraga(varchar(500) iUrl, integer maxCells, varchar(41) fullTabellNamn);
			declare integer antalCodes;
			getMetaData.getData(iURL, maxCells, fullTabellNamn);
			skapaSubFraga();
*			getMetaData.printMetaData('work.pxWeb_meta');
*			antalCodes=getMetaData.getAntalCodes();
*put 'antalCodes=' antalCodes;

/* Att g�ra:
		1. Skapa en optimala kombinationen av variabler i fr�gorna.
		2. Skapa en hash-lista med fr�gor.
		3. Hitta p� ett s�tt att exportera hash-listan utan tabell, om det g�r.
*/
		end;

		method skapaFraga();
			skapaFragaHelper();
		end;

		method skapaFragaHelper();

		end;

		method skapaSubFraga();
			declare varchar(25000) stubFraga;
			declare varchar(250) title code text values valueTexts elimination "time";
			declare integer rundaNr iDataStorlek sizeDataStorlek iMetaData sizeMetaData antal cellerPerValue;

 			h_subFragor.keys([subCode, subFraga]);
			h_subFragor.data([subCode, subFraga]);
			h_subFragor.ordered('A');
			h_subFragor.defineDone();

			iDataStorlek=1;
			sizeDataStorlek=getMetaData.dataStorlekNumItem();
			getMetaData.dataStorlekFirst(subCode,antal,cellerPerValue);
			do until(iDataStorlek=sizeDataStorlek);
			getMetaData.dataStorlekNext(subCode,antal,cellerPerValue);
				if antal=cellerPerValue then do;
					subFraga='{"code":' || subCode || '", "selection":{"filter":"all", "values":["*"]}}';
					h_subFragor.ref([subCode, subFraga],[subCode, subFraga]);
				end;
				else if cellerPerValue=1 then do;
					iMetaData=1;
					sizeMetaData=getMetaData.metaDataNumItem();
					getMetaData.metaDataFirst(title, code, text, values, valueTexts, elimination, "time");
					do until(iMetaData=sizeMetaData);
					getMetaData.metaDataNext(title, code, text, values, valueTexts, elimination, "time");
						if subCode=code then do;
							stubFraga='{"code":' || subCode || '", "selection":{"filter":"item", "values":["';
							subFraga=stubFraga || values || '"]';
							subFraga=subFraga || '}}';
							h_subFragor.ref([subCode, subFraga],[subCode, subFraga]);
						end;
					iMetaData=iMetaData+1;
					end;
				end;
				else do;
					rundaNr=0;
					stubFraga='{"code":' || subCode || '", "selection":{"filter":"item", "values":"';
					iMetaData=1;
					sizeMetaData=getMetaData.metaDataNumItem();
					getMetaData.metaDataFirst(title, code, text, values, valueTexts, elimination, "time");
					do until(iMetaData=sizeMetaData);
					getMetaData.metaDataNext(title, code, text, values, valueTexts, elimination, "time");
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
					iMetaData=iMetaData+1;
					end;
					if rundaNr^=cellerPerValue then do;
						stubFraga=stubFraga || '}}';
						subFraga=stubFraga;
						h_subFragor.ref([subCode, subFraga],[subCode, subFraga]);
						rundaNr=0;
						stubFraga='{"code":' || subCode || '", "selection":{"filter":"item", "values":"';
					end;
				end;
			iDataStorlek=iDataStorlek+1;
			end;
*h_subFragor.output('work.subfraga');
		end;*skapaSubFraga;

	endpackage;
run;quit;