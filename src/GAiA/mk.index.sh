#!/var/opt/UNItools/bin/bash
#
# Copyright (c) 2001 UNI-C, NTH. All Rights Reserved, see LICENSE
#

# setup environment (FWDIR osv)
for RC in /etc/profile /etc/bashrc $HOME/.profile $HOME/.bashrc $HOME/.bash_profile /tmp/.CPprofile.sh
do
	if [ -f $RC ]; then
		. $RC 2>&1 >/dev/null
	fi
done

#
# Vars
#
MYDIR=/var/opt/UNIfw1lr/
HTMLDIR=${MYDIR}/data/html
ETCDIR=${MYDIR}/etc
CFG=${ETCDIR}/fw1logrotate.conf

test -f "$CFG" || {
	echo "error: file '$CFG' not found. Re-run setup.sh or fw1logrotate.pl"
	exit 1
}

ONLINE_RETENSION=` awk -F: '$1 == "online_retension" { print $2; last }' < $CFG`
OFFLINE_RETENSION=` awk -F: '$1 == "offline_retension" { print $2; last }' < $CFG`


# Name of index.html in $HTMLDIR
INDEX=index.html

/bin/rm -f $HTMLDIR/$INDEX

touch $HTMLDIR/$INDEX; chmod 744 $HTMLDIR/$INDEX

cd $HTMLDIR

(
cat << EOH
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<HTML>
<HEAD>
	<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=iso-8859-1">
	<TITLE>Statistik og Gamle FireWall-1 Logfiler</TITLE>
	<META NAME="GENERATOR" CONTENT="$0">
	<META NAME="AUTHOR" CONTENT="fwsuport@uni-c.dk">
<STYLE TYPE="text/css">
<!--

BODY {
  font-family: sans-serif;
  background-color: white;
  font-size: 12px;
}

P {
  font-family: sans-serif;
  font-size: 12px;
  color: black
}

A {
  color: blue
}

A:hover {
  color: red;
}

LI {
  font-family: sans-serif;
  font-size: 12px;
  color: black
}


H1 {
  font-family: Verdana,Arial,Helvetica,sans-serif;
  font-weight: bold;
  font-size: 16px;
}       

H2 {
  font-family: Verdana,Arial,Helvetica,sans-serif;
  font-weight: bold;
  font-size: 15px;
}

H3 {
  font-family: Verdana,Arial,Helvetica,sans-serif;
  font-weight: bold;
  font-size: 14px;
}

/* For the 2 header table at the start of the report */
.HEADER {
  font-family: Verdana,Arial,Helvetica,sans-serif;
  background-color: #FFEFC6;
  font-size: 12px;
}                        

/* Table Header */
.TH {
  font-family: Verdana,Arial,Helvetica,sans-serif;
  font-size: 12px;
  background-color: #FFEFC6;
  color: blue;
  font-weight: bold;
}

/* Table body */
.TABLE {
  color: black;
  background-color: white;
  font-size: 12px;
}

/* Table body for matched highlights */
.TABLEHIGHL {
  color: green;
  background-color: white;
  font-weight: normal;
  font-size: 12px;
}

/* Table body for alert entries */
.TABLEALERT {
  color: red;
  background-color: white;
  font-weight: bold;
  font-size: 12px;
}

/* Table body for encrypt/decrypt entries */
.TABLECRYPT {
  color: 620694;
  background-color: white;
  font-weight: normal;
  font-size: 12px;
}
-->
</STYLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF">
<BR>
<H1>Oversigt over gamle logfiler</H1>
<P>Denne side viser en oversigt over gamle firewall logfiler. Logfilerne roteres en
gang i døgnet.
<BR>
De roterede logfiler gemmes sammen med en statisktisk oversigt og en tekstuel
eksport samlet i kataloger for en dag ad gangen.
<BR>
Katalogerne bevares i $ONLINE_RETENSION dage, hvorefter de komprimeres og
katalogerne slettes. 
<BR>
De komprimerede arkiver gemmes yderligere i $OFFLINE_RETENSION dage før de slettes.
Antallet af dage kan justeres i det omfang der er diskplads nok.
<BR>
<A HREF="http://www.uni-c.dk/">UNI<FONT COLOR=RED><EM>&middot;</EM></FONT>C 
</A> vil anbefale at dokumenterne
på denne side regelmæssigt kopieres til et sikkert medie af arkivhensyn.
<BR>
De kan gøres automatisk med f.eks. det licensfrie program GNU Weget, der kan hentes på
<A HREF="http://wget.sunsite.dk"> http://wget.sunsite.dk/</A>.
Programmet findes også i en version til Microsoft Windows.
</P>
<H2>Online - bevares i $ONLINE_RETENSION dage</H2>
<P>Online  logfilerne er hardlinkede til dokumenter i FireWall-1 log
kataloget. Dokumenterne kan  derfor  også  læses  med  FireWall-1
logviewer GUI.
<BR>
<TABLE WIDTH=95% BORDER=1 CELLPADDING=5 CELLSPACING=0 CLASS=TABLE>
	<THEAD>
		<TR VALIGN=TOP>
			<TH WIDTH=30% BGCOLOR="#FFEFC6">
				<DIV ALIGN=CENTER>
				Katalognavn</DIV>
			</TH>
			<TH WIDTH=20% BGCOLOR="#FFEFC6">
				<DIV ALIGN=RIGHT>
				St&oslash;rrelse i Mb</DIV>
			</TH>
			<TH WIDTH=50% BGCOLOR="#FFEFC6">
				<DIV ALIGN=CENTER>
				Beskrivelse</DIV>
			</TH>
		</TR>
	</THEAD>
EOH

echo "	<TBODY>"

for FILE in *
do
	FILE=`echo $FILE | sed 's/htdocs.*//'`

if [ -d "${FILE}" -a "${FILE}" != "htdocs" ]; then

DAG=`echo $FILE | awk -F_ '{ print $3 " " $2 " " $1 }'`

SIZE=`du -k $FILE | awk '{ printf("<B>%.2f</B> Mb\n", $1 / 1024 ); }'`

INFO="Rapporter og FireWall-1 logfiler fra logswitch den $DAG"

cat << EOTD
		<TR VALIGN=TOP>
			<TD WIDTH=30%>
				<DIV ALIGN=CENTER>
				<A HREF="$FILE/index.html">$FILE</A></P>
			</TD>
			<TD WIDTH=20%>
				<DIV ALIGN=RIGHT>$SIZE</DIV>
			</TD>
			<TD WIDTH=50%>
				<DIV ALIGN=LEFT>$INFO</DIV>
			</TD>
		</TR>
EOTD

else
	:
fi

done

cat << EOF
	</TBODY>
</TABLE>


<H2>Komprimerede - bevares i $OFFLINE_RETENSION dage</H2>
<P>De komprimerede dokumenter er lavet som Posix Tar arkiver, komprimeret
med GNU zip. De kan dekomprimeres med de fleste PC unzip værktøjer,
f.eks. den gratis <A HREF="http://www.aladdinsys.com/expander/">
http://www.aladdinsys.com/expander - Aladdin Systems' Expander</A>,
der findes til Linux, Mac og Microsoft Windows.
</P>
<TABLE WIDTH=95% BORDER=1 CELLPADDING=5 CELLSPACING=0 CLASS=TABLE>
	<THEAD>
		<TR VALIGN=TOP>
			<TH WIDTH=30% BGCOLOR="#FFEFC6">
				<DIV ALIGN=CENTER>
				Dokumentnavn</DIV>
			</TH>
			<TH WIDTH=20% BGCOLOR="#FFEFC6">
				<DIV ALIGN=CENTER>
				St&oslash;rrelse</DIV>
			</TH>
			<TH WIDTH=50% BGCOLOR="#FFEFC6">
				<DIV ALIGN=CENTER>
				Beskrivelse</DIV>
			</TH>
		</TR>
	</THEAD>
	<TBODY>

EOF

for FILE in *.tar.gz
do

if [ -f $FILE ]; then

DAG=`echo $FILE | awk -F_ '{ print $3 " " $2 " " $1 }'`

SIZE=`du -k $FILE | awk '{ printf("<B>%.2f</B> Mb\n", $1 / 1024 ); }'`

INFO="Komprimeret tar arkiv med rapporter og FireWall-1 logfiler fra logswitch den $DAG"

cat << EOTD
		<TR VALIGN=TOP>
			<TD WIDTH=30%>
				<DIV ALIGN=LEFT>
				<A HREF="$FILE">$FILE</A></DIV>
			</TD>
			<TD WIDTH=20%>
				<DIV ALIGN=RIGHT>
				$SIZE</DIV>
			</TD>
			<TD WIDTH=50%>
				<DIV ALIGN=LEFT>
				$INFO</DIV>
			</TD>
		</TR>

EOTD

else
	:
fi

done

cat << EOF

	</TBODY>
</TABLE>
</P>
</BODY>
</HTML>
EOF

) > $INDEX

chmod -R 444 $INDEX

# Copyright (c) 2001 UNI-C, NTH. All Rights Reserved
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF UNI-C, DENMARK
# The copyright notice above does not evidence  any  actual  or
# intended publication of such source code.
#
# Advarsel:
# Det  følgende er ikke-offentliggjort kildetekst tilhørende UNI-C,
# Danmark. Ovenstående copyright er ikke en tilkendegivelse af  no-
# gen bevist offentliggørelse af kildetekst.
#
# Dette  dokument  indeholder  intern  information fra UNI-C, gjort
# tilgængelig udelukkende i oplysningsøjemed, og kun for den kunde,
# for  hvem  UNI-C  har installeret CheckPoint Firewall-1 og på den
# installation for hvilken kunden har  en  gyldig  driftaftale  med
# UNI-C.
#
# Følgende information er gjort tilgængelig 'som den er'  og UNI-C
# kan  ikke  tage  ansvaret  for  hverken  informationen  eller de
# handlinger og eller beslutninger der tages på baggrund af denne.
# UNI-C kan ligeledes ikke drages til ansvar for programfejl eller
# følgefejl af nogen art.
#

#++
# NAVN
#	mk.index.sh
# RESUME
#	opret index.html for katalogtræ med gamle FireWall-1 logfiler
# SYNOPSIS
#	\fBmk.index.sh\fR
# OPTIONS
# Ingen.
# FORMÅL
#	Oprettelse af en html side, så der ser lidt pænere ud, når
#	man læser gamle FireWall-1 logfiler gemt med
#	\fCfw1logrotate.pl\fR. Mode og ejer sættes ligeledes, så
#	den anvendte httpd server accepterer dokumenterne.
# PROGRAMPAKKE
#       Dette script er en del af UNI\(buCs programpakke
#       \fBUNIfw1lr\fR til rotation af Check Point firewall-1
#       logfiler. Programpakken er afprøvet på NG FP3 men
#       burde også virke på tidligere versioner (3.0b, 4.0 og
#       4.1 på Solaris).
# ANDET
#	Se dokumentation for programpakken UNIfw1lr.
# VERSION
#	$Header: /lan/ssi/shared/software/internal/UNIfw1lr/src/GaIA/mk.index.sh,v 1.1 2016/04/29 13:35:57 root Exp $
# HISTORIE
#	Se \fCrlog $Id$\fR.
# AUTHOR(S)
#       Niels Thomas Haugård
# .br
#       E-mail: thomas@haugaard.net
# .br
#       UNI\(buC
# .br
#       DTU, Building 304
# .br
#       DK-2800 Kgs. Lyngby
# .br
#--
