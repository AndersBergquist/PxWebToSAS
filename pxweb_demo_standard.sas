/* Demo på nornmal användningen av pxWebToSAS4.
   Glöm inte att ändra work till det library där programmet är sparat.*/
proc ds2;
	data _null_;
		declare package work.pxWebToSAS4 px();
		declare varchar(500) url0 url1 url2 url3 url4 url5 urlKonj;
		declare varchar(8) bibl;
		declare integer upd;
	
		method run();
			url5='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/PR/PR0101/PR0101A/KPIFastM2';
			url4='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101A/BefolkManad';
			url3='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101J/Flyttningar97';
			url2='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101H/FoddaK';
			url1='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/MI/MI0810/MI0810A/LandarealTatortN';
			url0='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/AM/AM0207/AM0207E/AMPAK1';
			urlKonj='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/FM/FM0103/FM0103A/FirENS2010ofKv';

			bibl='work';

			px.getData(url5, bibl);
		end;
	enddata;
run;quit;
