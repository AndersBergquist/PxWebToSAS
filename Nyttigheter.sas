proc ds2;
	package &instprog..prg_nyttigheter / overwrite=yes;
		dcl private varchar(8) lib;
		dcl private varchar(2000) tabell;
		dcl private integer antal;

		method prg_nyttigheter();
		end; *rumprg_nyttigheter;

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

		method nastaSCBKvartal(char(6) kvartal) returns char(6);
			dcl char(6) nastaKvartal;
			dcl char(4) ar_nm;
			dcl char(1) kvartal_nm;
			dcl integer ar;

			kvartal_nm=substr(kvartal,6,1);
			ar_nm=substr(kvartal,1,4);

			if kvartal_nm='1' then kvartal_nm='2';
				else if kvartal_nm='2' then kvartal_nm='3';
				else if kvartal_nm='3' then kvartal_nm='4';
				else if kvartal_nm='4' then do;
					kvartal_nm='1';
					ar=ar_nm;
					ar=ar+1;
					ar_nm=ar;
				end;
			nastaKvartal=ar_nm || 'K' || kvartal_nm;
		return nastaKvartal;
		end;*nastaSCBKvartal;


	endpackage;
run;quit;