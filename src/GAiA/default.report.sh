#!/var/opt/UNItools/bin/bash
#
# Copyright (c) 1995 UNI-C, NTH. All Rights Reserved
#

mungle() {
	sed   "s%__TITLE__%$TITLE%g;
		s%__OVERSKRIFT__%$OVERSKRIFT%g;
	"
}

report() {

	# arguments for fwlogum 5.x
	ARGS="--verbose --html --sortcount --xlateboth --time24 --postresolveip --cachedns --incdomain --svcname --verbose --summary --logexport $INDDATA --trenddir ${TRENDDIR}"
	# arguments for fwlogum 5.10
#	ARGS="--verbose --html --sortcount --xlateboth --time24 --postresolveip --cachedns --svcname --verbose --summary --logexport $INDDATA --trenddir ${TRENDDIR}"

	chmod 755 $DIR
	test -d ${TRENDDIR} || mkdir ${TRENDDIR}

	echo "$ALL_REPORTS" | while read REP
	do
		FILE=`echo $REP | awk -F'|' '{ print $1 }'`
		TYPE=`echo $REP | awk -F'|' '{ print $2 }'`
		DESC=`echo $REP | awk -F'|' '{ print $3 }'`

		for RMFILE in $DIR/${FILE}
		do
			if [ -f "${RMFILE}" ]; then
				/bin/rm -f ${RMFILE}
				echo "removed '$RMFILE' ... "
			fi
		done

		CMD="$REPORT --rpt${TYPE} $ARGS"

		# echo "report command: '${CMD}'"
		VERBOSE_LOGFILE=${FILE}.verbose.log

		# echo "Logging to $VERBOSE_LOGFILE"

		$CMD 2> $VERBOSE_LOGFILE > ${FILE} &
	done

	#
	# Monitor and sleep untill all reports are done
	#
	echo "`date +'%d %B %Y %T'`: Starting report generator ... "
	echo "`date +'%d %B %Y %T'`: Load: `uptime`"
	sleep 5
	SLEEP_TIME=120
	while :;
	do
		DONE=`$MYPS | grep $REPORT | grep -v grep | wc -l | sed 's/ *//'`
		case $DONE in
			0)
				echo "done, `date +'%d %B %Y %T'`"
				break
			;;
			*)
				echo "`date +'%d %B %Y %T'`: Load: `uptime`"
				echo "`date +'%d %B %Y %T'`: Still  $DONE reports to go, sleeping $SLEEP_TIME sec."
				sleep $SLEEP_TIME
			;;
		esac
	done
}

index() {
#
# INDEX.HTML
#

echo "Building index.html ... " >&2

(

cd $DIR

TITLE="Indeks for `basename $DIR`"
OVERSKRIFT="Indeks for FireWall-1 logfiler og rapporter(er)"

echo "Laver index.html ... " >&2

#
#  Fï¿½rste / sidste linie == start / slut
#


FLINE=`head -10 $INDDATA | $NAWK -F';' '$2 == "" { next;}; $2 != "date" {print $2 " "$3 }'| head -1`
LLINE=`tail -10 $INDDATA | $NAWK -F';' '$0 !~ /^$/ { print $2 " "$3 }' | tail -1`

echo "Komprimerer ${INDDATA} med gzip -9 .. " >&2

gzip -v9 ${INDDATA} >&2

EXPORTED=`basename $DIR`.txt

#
# HEAD
#
cat << EOF | mungle
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<!-- $Header: /lan/ssi/shared/software/internal/UNIfw1lr/src/GaIA/default.report.sh,v 1.1 2016/04/29 13:35:57 root Exp $ -->
<HTML>
<HEAD>
<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=iso-8859-1">
<TITLE>__TITLE__</TITLE>
<META NAME="GENERATOR" CONTENT="NTH powered vi">
<STYLE TYPE="text/css">
<!--

BODY {
  font-family: sans-serif;
  background-color: white;
  font-size: 12px;
}

A {
  color: blue
}

A:hover {
  color: red;
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
EOF

#
# BODY
#
cat << EOF | mungle
<BODY BGCOLOR="#FFFFFF">
<H3>__OVERSKRIFT__</H3>
EOF

#
# Start/slut log-dato i tabel
#
cat << EOF
<TABLE WIDTH=100% BORDER=1 CELLPADDING=5 CELLSPACING=0 CLASS=TABLE>
<TD WIDTH=35%>Første loglinie:</TD><TD WIDTH=65% ALIGN=RIGHT>$FLINE</TD></TR>
<TD WIDTH=35%>Sidste loglinie:</TD><TD WIDTH=65% ALIGN=RIGHT>$LLINE</TD></TR>
</TABLE>
<P>
EOF

#
# TABLE HEADER
#
cat << EOF | mungle
<TABLE WIDTH=100% BORDER=1 CELLPADDING=5 CELLSPACING=0 CLASS=TABLE>
<THEAD>
	<TR VALIGN=TOP>
		<TD WIDTH=35% BGCOLOR="#FFEFC6">
                        <P ALIGN=CENTER>
			<B>Dokument</B></P>
		</TD>
		<TD WIDTH=15% BGCOLOR="#FFEFC6">
                        <P ALIGN=RIGHT>
			<B>St&oslash;rrelse i Mb</B></P>
		</TD>
		<TD WIDTH=50% BGCOLOR="#FFEFC6">
                        <P ALIGN=CENTER>
			<B>Beskrivelse</B></P>
		</TD>
	</TR>
</THEAD>
<TBODY>
EOF

#
# TABLE DATA
#
sync; sync; sync	# Nokia besværgelse ?

#
# Først rapporterne *.html
#
echo "$ALL_REPORTS" | while read REP
do
        FILE=`echo $REP | awk -F'|' '{ print $1 }'`
        DESC=`echo $REP | awk -F'|' '{ print $3 }'`

	if [ -f "$FILE" ]; then
		FILE=`basename $FILE`
		SIZE=`du -k $FILE | $NAWK '{ printf("<B>%.3f</B> Mb\n", $1/1024) }'`

		cat << EOF | mungle
	<TR VALIGN=TOP>
		<TD WIDTH=35%>
			<P><A HREF="$FILE">$FILE</A></P>
		</TD>
		<TD WIDTH=15%>
			<P ALIGN=RIGHT>$SIZE</P>
		</TD>
		<TD WIDTH=50%>
			<P>$DESC</P>
		</TD>
	</TR>
EOF
	else 
		:
		# echo "hovsa, filen '$FILE' findes ikke" >&2
fi
done

#
# Så alle andre dokumenter
#
for FILE in `ls | sed '/RGraph/d; /.*.html$/d;'`
do
	case $FILE in
		*.txt.gz)	DESC="Eksporteret log i tekstformat. Der anvendes ';' som skilletegn og felterne er beskrevet i den første linie. Filen skal fÃ¸rst pakkes ud"
		;;
		fw1logrotate.log)
			DESC="Kørselslog for logrotation."
		;;
		*verbose.log)
			DESC="Kørselslog for generering af rapporten `echo $FILE | sed 's/verbose.*//'`html"
		;;
		*_ptr*)	DESC="Logpointer (Binær FireWall-1 logfil)"
		;;
		*.log*)	DESC="Binær FireWall-1 logfil."
		;;
		*.alog*)	DESC="Binær FireWall-1 logfil."
		;;
		*)	DESC="-"
		;;
	esac
	
	SIZE=`du -k $FILE | awk '{ printf("<B>%.3f</B> Mb\n", $1/1024) }'`

cat << EOF | mungle
	<TR VALIGN=TOP>
		<TD WIDTH=35%>
			<P><A HREF="$FILE">$FILE</A></P>
		</TD>
		<TD WIDTH=15%>
			<P ALIGN=RIGHT>$SIZE</P>
		</TD>
		<TD WIDTH=50%>
			<P>$DESC</P>
		</TD>
	</TR>
EOF
done

#
# TABLE END, BODY END, HTML END, END END END.
#
cat << EOF | mungle
</TBODY>
</TABLE>
<H2>Bemærkninger</H2>
<UL>
<LI>Rapporterne er et <EM>udtræk af hvad der logges</EM>. I et forsøg
på at reducere logfilernes størrelse vil man typisk smide information
væk, firewall'en ingen indflydelse har på (f.eks. lokal trafik på samme
interface).
<LI>Rapporterne <EM>kan</EM> vise et skævt billede af trafikmængden;
kun regler i firewall'en der logger med <EM>account</EM> gemmer oplysinger
om den overførte datamængde. Et mere præcist totalbillede fås ved f.eks.
snmp forespørgsel af internet routeren.
<LI>Rapporterne indeholder simple grafer, der vises bedst i IE; Netscape
Opera og Mozilla viser ikke graferne i farve.
<LI>Det er kun muligt, at anvende de binære FireWall-1 logfiler på
en FireWall-1 management station med passende licens. Det er ikke
muligt, at gennemse loggen lokalt med GUI'en.
<LI>Den eksporterede logfil <EM>$EXPORTED</EM>, kan
indlæses i et loganalyseværktøj, regneark eller database for
videre behandling; <EM>men bemærk dens størrelse før det gøres</EM>!
<LI><EM>Logfilerne bør kopieres til et sikkert medie; de vil blive slettet
fra firewall'en efter behov</EM>.
</UL>
<H3>Kørselsstatistik for rapportgenerering</H3>
<P>
<TABLE WIDTH=100% BORDER=1 CELLPADDING=5 CELLSPACING=0 CLASS=TABLE>
<TD WIDTH=35%>Start:</TD><TD WIDTH=66% ALIGN=RIGHT>$START</TD></TR>
<TD WIDTH=35%>Slut:</TD><TD WIDTH=66% ALIGN=RIGHT>`date +'%d %B %Y %T'`</TD></TR>
</TABLE>
</BODY>
</HTML>
EOF
) > $DIR/index.html

}

mode() {
	find $DIR/.. -type d -exec /bin/chmod -R 555 {} \;
	find $DIR/.. -type f -exec /bin/chmod -R 444 {} \;
}

#######################################################################################
#
# MAIN, VARIABLE og andet systemspecifikt skrammel
#
#######################################################################################
#
# usage $0 "" | -{rim}
#
R_REP=FALSE
R_IND=FALSE
R_MOD=FALSE

case $# in
	1)	R_REP=TRUE; R_IND=TRUE; R_MOD=TRUE
	;;
	*) 

	while getopts rim opt
	do
		case ${opt} in
		r)	R_REP=TRUE
		;;
		i)	R_IND=TRUE
		;;
		m)	R_MOD=TRUE
		;;
		esac
	done
	shift `expr $OPTIND - 1`
	;;
esac

START=`date +'%d %B %Y %T'`
ME=`basename $0`

case $# in
	1)
	;;
	*)	echo "$0 dir"
		exit 1
	;;
esac

DIR=$1

NAME=`basename $DIR`
MYDIR=/var/opt/UNIfw1lr/
DATADIR=${MYDIR}/data
TRENDDIR=${DATADIR}/trend_db

REPORT="$MYDIR/fwlogsum/fwlogsum"

EXT="$NAME.html"
INDDATA=$DIR/$NAME.txt

case `uname` in
	IPSO)	MYPS="/bin/ps  -xauww"
		NAWK="awk"
	;;
	SunOS)	MYPS="/usr/ucb/ps -xauww"
		NAWK="nawk"
	;;
	Linux)	MYPS="/bin/ps xauww"
		NAWK="awk"
	;;
	*)	MYPS="ps -xauww"
		NAWK="awk"
	;;
esac

test -d "$DIR" || {
	echo "$DIR -- ikke et dir !"
	exit 1
}
test -x "$REPORT" || {
	echo "rapport generator $REPORT kan ikke udføres"
	exit 1
}

################################################################################
#
# Navne på og beskrivelser af rapporter
# FILE | ARGS | DESCRIPTION
#

R1="$DIR/accepts.$EXT|accepts|Oversigtsrapport over alle tilladte forbindelser, sorteret efter antal, FQDN i stedet for IP adresser, incl. domæne oversigt."

R2="$DIR/dropsrejects.$EXT|dropsrejects|Oversigtsrapport over alle afviste forbindelser, sorteret efter antal, FQDN i stedet for IP adresser, incl. domæne oversigt."

R3="$DIR/attacks.$EXT|attacks|Oversigtsrapport over alle angreb rapporteret af SmartDefence, sorteret efter antal, FQDN i stedet for IP adresser, incl. domæne oversigt. Rapporten kræver NG AI og kan være tom."

#
#
#

ALL_REPORTS="$R1
$R2
$R3"
#

# Nye rapporter med fwlogsum:
#
# R4=" ...|...|... "
#
# ALL_REPORTS="$R1
# $R2
# $R3
# $R4"
#
#
################################################################################

cd `dirname $REPORT`

echo "leder efter '$INDDATA' ... "

if [ ! -f "$INDDATA" ]; then
        if [ -f "${INDDATA}.gz" ]; then
                echo "found ${INDDATA}.gz unzipping it ... "
                gunzip -v ${INDDATA}.gz
        else
                echo "No $INDDATA or ${INDDATA}.gz found, bye"
                exit
        fi
else
        echo "found $INDDATA"
        ls -la $INDDATA
fi

test -f "$INDDATA" || {
	echo "Exported logfile '$INDDATA' not found, bye"
	exit
}

if [ $R_REP = "TRUE" ]; then
	report
	echo "rapport done"
fi

if [ $R_IND = "TRUE" ]; then
	index
	echo "index done"
fi

if [ $R_MOD = "TRUE" ]; then
	mode
	echo "mode done"
fi

exit 0

#
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
#	uni-c.report.sh 1
# RESUME
#	dannelse af FireWall-1 rapporter ud fra en eksporteret firewall-1 logfil.
# SYNOPSIS
#	\fBuni-c.report.sh\fR [-rim] \fBlogkatalog\fR
# OPTIONS
# .IP \fBlogkatalog\fR
#	Et katalog med firewall logfiler samt en eksporteret logfil.
# .IP \fB-r\fR
#	Lav \fIkun\fR rapporter ud fra FireWall-1 logfiler i \fIlogkatalog\fR
# .IP \fB-i\fR
#	Lav \fIkun\fR et index.html i \fIlogkatalog\fR
# .IP \fB-m\fR
#	Sæt \fIkun\fR rettigheder for dokumenterne i \fIlogkatalog\fR til noget
#	fornuftigt, hvis dokumenterne skal læses via http.
#
#	Kaldes scriptet kun med et argument, laves alt ovenstående.
# FORMÅL
#	\fBuni-c.report.sh\fR er en del af programpakken \fBUNIfw1lr\fR,
#	der anvendes til logrotation og retension af FireWall-1 logfiler.
#
#	\fBuni-c.report.sh\fR er et hjælpescript, der kalder en
#	rapportgenerator og får dannet 2-6 prædefinerede rapporter ud
#	fra den eksporterede logfil, der ligger i \fIlogkatalog\fR.
# BESKRIVELSE
#	\fBuni-c.report.sh\fR kalder en rapportgenerator med forkellige
#	argumenter, der læser en firewall-1 logfil. Logfilen er eksporteret
#	med IP adresser, og læses gennem et filter, der oversætter disse
#	til FQDM (full qualified domain names). Filteret lavner caching 
#	af navneoplysninger; idet FireWall-1 logexport ikke gør det, og
#	rapportgeneratoren tilsyneladende hellerikke gør det.
#	
#	Det kan være en fordel, at installere en lokal, caching navneserver
#	på firewall'en. Er en sådan installeret, fremgår det af de dokumenter,
#	der ligger i \fC/var/named\fR.
# BAGGRUND
#	Se den generelle dokumentation for programpakken \fBUNIfw1lr\fR.
# PROGRAMPAKKE
#       Dette script er en del af UNI\(buCs programpakke
#       \fBUNIfw1lr\fR til rotation af Check Point firewall-1
#       logfiler. Programpakken er afprøvet på NG FP3 men
#       burde også virke på tidligere versioner (3.0b, 4.0 og
#       4.1 på Solaris).
# ANDET
#	UNI\(buC og forfatteren fraskriver sig et hvert ansvar for anvendelse
#	af denne programpakke.
#
#	Se iøvrigt dokumentation for programpakken.
# VERSION
# $Header: /lan/ssi/shared/software/internal/UNIfw1lr/src/GaIA/default.report.sh,v 1.1 2016/04/29 13:35:57 root Exp $
# HISTORIE
#       Se \fCrlog $Id$\fR.
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

#
#	Usage for fwlogsum:
#
#	-a  --highlight         Highlight specified lines
#	-A  --attackinfo        Display attack info from SmartDefense
#	-B  --trenddir          Trend data directory
#	-bo --outbound          Report only on outbound traffic
#	-bi --inbound           Report only on inbound traffic
#	-c  --width             Column width.  80 or 132 chars
#	-C  --cachedns          Cache DNS results
#	-d  --delimiter         Delimiter for logexport fields (default: ;)
#x-D  --incdomsum         Include domain summary in report
#	-e  --excludesvc        Exclude specified service(s) from report
#	-f  --excludesrcsvc     Exclude specified source services(s) from report
#	-g  --restrictcount     Restrict entries with less than the specified count
#	-H  --header            Report header title
#	-i  --ignore            Ignore specified entries (perl regexp)
#	-l  --logexport         Read from specified logexport file (Standard or compressed)
#	-L  --fw1log            Read from specified FW1 log file (Standard or compressed)
#	-m  --mail              Mail report to specified user
#	-n  --excludeif         Exclude specified FW interface/s from the report
#	-o  --output            Output to specified file
#	-p  --incsrcport        Include source port number in report
#	-P  --summaries         Number of entries to appear in the summary (default: 10)
#	-q  --postresolveip     Resolve IP addresses after filtering has been performed.
#	-R  --resolveip         Resolve IP addresses (before filtering)
#	-ra --rptaccepts        Report only on accepted entries
#	-rd --rptdrops          Report only on dropped entries
#	-rr --rptrejects        Report only on rejected entries
#	-rt --rptattacks        Report only on attack entries
#	-rx --rptdropsrejects   Report only on dropped and rejected entries (Default)
#	-S  --summary           Generate Summary only.
#	-sa --sortattack        Sort by attack type (only relevant for SmartDefense entries)
#	-sc --sortcount         Sort by count (default)
#	-sd --sortdest          Sort by destination address
#	-sf --sortfw            Sort by firewall host
#	-sr --sortrule          Sort by rule number
#	-ss --sortsrc           Sort by source address
#	-sv --sortsvc           Sort by service
#	-t  --includeonly       Report only on specified entries (perl regexp)
#	-T  --time24            Display time summary as 24 hour clock
#	-v  --verbose           Verbose mode
#	-w  --html              Output in HTML
#	-xb --xlateboth         Report both normal address/port and translated address/port
#	-xt --xlate             Report just the translated address/port
#	-y  --svcname           Convert port numbers to their name
#	-Y  --svcport           Convert port names to their number

#
#	-G  --geolookup		Perform Geo IP Lookups

