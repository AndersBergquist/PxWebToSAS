/* Demo på nornmal användningen av pxWebToSAS4.
   Glöm inte att ändra work till det library där programmet är sparat.*/
proc ds2;
	data _null_;
		declare package sasuser.pxWebToSAS4 px();
		declare varchar(500) url0 url1 url2 url3 url4;
		declare integer upd;
	
		method run();
			url4='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/AM/AM0401/AM0401A/NAKUBefolkning2M';
			url3='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101J/Flyttningar';
			url2='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/NR/NR0103/NR0103E/NR0103ENS2010T01NA';
*			url1='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0401/BE0401B/BefPrognosOversikt14';
			url0='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101A/BefolkningNy';

			px.getData(url4,'sasuser');
		end;
	enddata;
run;quit;
