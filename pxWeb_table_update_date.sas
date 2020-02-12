/****************************************
Program: pxWeb_table_update_date.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- H�mtar datum f�r tabellens uppdatering p� SCB/PxWeb-site
***********************************/


proc ds2;
	package work.pxweb_UppdateTableDate / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		forward askSCB extractSCBDate;

		method pxweb_UppdateTableDate();

		end;

		method getSCBDate(varchar(500) iUrl) returns double;
			declare double datum dtime;
			declare varchar(100000) respons;
			declare char(19) datetext;
			respons=g.getData(iURL);
			datetext=extractSCBDate(iURL,respons);
put 'UpdateTableDate: ' datetext;
			datum=mdy(put(substr(datetext,6,2),2.),put(substr(datetext,9,2),2.),put(substr(datetext,1,4),4.));
			dtime=dhms(datum,put(substr(datetext,12,2),2.),put(substr(datetext,15,2),2.),put(substr(datetext,18,2),2.));
		return dtime;
		end; *getSCBDate;;

		method extractSCBDate(varchar(500) iURL, varchar(100000) respons) returns char(19);
			declare varchar(500) tableName;
			declare char(19) updateDatum;
			declare package json j();
			declare integer tokenType parseFlags rc;
			declare nvarchar(250) token;

			tableName=scan(iUrl,-1,'/');
			updateDatum='';
			rc=j.createParser(respons);
* H�r b�rjar en loop som letar datum i resonsfilen;
			do while (rc=0);
				j.getNextToken(rc, token, tokenType, parseFlags);
				if token='id' then do;
					j.getNextToken(rc, token, tokenType, parseFlags);
					if token=tableName then do;
						do until(token='updated');
							j.getNextToken(rc, token, tokenType, parseFlags);

						end;
						j.getNextToken(rc, token, tokenType, parseFlags);
						updateDatum=token;
						rc=99;
					end;
				end;
			end;
* H�r slutar loopen;
put 'extract SCB: ' updateDatum;
			return updateDatum;
		end;*extractSCBDate;


		method getDBDate(varchar(40) fullTabellNamn) returns double;
			declare double dbUpdated;

			dbUpdated=1890639000-1000000;
		return dbUpdated;
		end;*getDBDate;

	endpackage ;
run;quit;
