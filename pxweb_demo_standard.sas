/* Demo på nornmal användningen av pxWebToSAS4.
   Glöm inte att ändra work till det library där programmet är sparat.*/
proc ds2;
	data _null_;
		declare package work.pxWebToSAS4 px();
		declare varchar(500) url0 url1 url2 url3 url4 urlKonj;
		declare varchar(8) bibl;
		declare integer upd;
	
		method run();
			url4='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/AM/AM0401/AM0401A/NAKUBefolkning2M';
			url3='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101J/Flyttningar97';
			url2='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101H/FoddaK';
			url1='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/UF/UF0301/UF0301A/FoUSverigeRegion';
			url0='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/AM/AM0207/AM0207E/AMPAK1';
			urlKonj='http://prognos.konj.se/PXWeb/api/v1/sv/SenastePrognosen/f21_arbetsmarknad/F2101.px';

			bibl='work';

			px.getData(url4, bibl);
		end;
	enddata;
run;quit;
