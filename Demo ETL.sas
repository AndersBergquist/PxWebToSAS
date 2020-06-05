/*Demo för användning där returkoden behövs som macro, t.ex. i DI-studio
  Glöm inte att ändara libname. */
proc ds2;
	data _null_;
		declare package work.pxWebToSAS4 px();
		declare varchar(500) url0 url1 url2 url3 url4;
		declare integer upd;
	
		method run();
			url4='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/AM/AM0401/AM0401A/NAKUBefolkning2M';
			url3='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101J/Flyttningar';
			url2='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/NR/NR0103/NR0103E/NR0103ENS2010T01NA';
*			url1='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0401/BE0401B/BefPrognosOversikt14';
			url0='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101A/BefolkningNy';

			upd=px.getData(url4);
			*Returkoden läggs i en fil för att vi ska kunna skapa ett macro;
			sqlexec('CREATE TABLE work.pxweb_upd (upd integer)');
			sqlexec('INSERT INTO work.pxweb_upd (upd) VALUES(' || upd || ')');
		end;
	enddata;
run;quit;
* Nedan skapas macrot och den temporära filen work.pxweb_upd tas bort;
data _null_;
	set work.pxweb_upd;
	call symput('upd', upd);
run;

proc datasets lib=work nolist;
	delete pxweb_upd;
run;

