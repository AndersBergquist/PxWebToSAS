/****************************************
Program: pxWeb_table_update_date.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1
Uppgift:
- Hämtar datum för tabellens uppdatering på SCB/PxWeb-site
***********************************/


proc ds2;
	package work.pxweb_UppdateTableDate / overwrite=yes;
		declare package work.pxweb_GemensammaMetoder g();
		forward askSCB extractSCBDate;

		method pxweb_UppdateTableDate();

		end;

		method updateDate(varchar(500) iUrl) returns double;
			declare double datum dtime;
			declare varchar(100000) respons;
			respons=g.getData(iURL);
*			datetext=extractSCBDate(iURL,respons);
put 'UpdateTableDate: ' respons;
*			datum=mdy(put(substr(datetext,6,2),2.),put(substr(datetext,9,2),2.),put(substr(datetext,1,4),4.));
*			dtime=dhms(datum,put(substr(datetext,12,2),2.),put(substr(datetext,15,2),2.),put(substr(datetext,18,2),2.));
		return dtime;
		end; *updateDate;;

		method extractSCBDate(varchar(500) iURL, varchar(100000) respons) returns char(19);
			declare varchar(500) tableName;
			declare char(19) updateDatum;

			tableName=scan(iUrl,-1,'/');

* Här börjar en loop som letar datum i resonsfilen;

* Här slutar loopen;
			return updateDatum;
		end;*extractSCBDate;
	endpackage ;
run;quit;
