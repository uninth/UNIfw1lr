#!/var/opt/UNItools/bin/bash
#
# Copyright (c) 2001 UNI-C, NTH. All Rights Reserved, see LICENSE
#

#
# Vars
#
MY_LOGFILE=/tmp/logrotation.err
LOGGER="logger -t `basename $0` -p mail.crit"

ERRORS=0

#
#
# Functions
#
logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`/bin/date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		${LOGGER} "${LOGIT_NOW} ${STRING}"
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				${LOGGER} "${LOGIT_NOW} ${LINE}"
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}

################################################################################
# Main
################################################################################

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac


case `uname` in
	IPSO)		. $HOME/.profile	> /dev/null 2>&1
	;;
	Linux|Solaris)	. $HOME/.bash_profile	> /dev/null 2>&1
			. $HOME/.bashrc		> /dev/null 2>&1
	;;
	*)		. $HOME/.profile	> /dev/null 2>&1
	;;
esac

/bin/rm -f ${MY_LOGFILE}

logit "FYI: Starting Check Point FireWall-1 LogRotation and visualization"
logit "FYI: This is the process and debug log"
logit "FYI: cron exec $0 $*"

# Logs stored here
HTML=/var/opt/UNIfw1lr/data/html

logit "FYI: HTML = '$HTML'"

# Find latest current logdir
PREV_LOGDIR=`find ${HTML} -maxdepth 1 -type d | sort -n | tail -1`

logit "FYI: PREV_LOGDIR = '$PREV_LOGDIR'"

logit "FYI: exec fw1logrotate. Time-stamp not accurate, but exit status is"

# Exec rotator
( /var/opt/UNIfw1lr/bin/fw1logrotate.pl ) 2>&1 > ${MY_LOGFILE}.tmp
EXIT_STATUS=$?
case $EXIT_STATUS in
	0)	logit "FYI: Exit status: $EXIT_STATUS"
	;;
	*)	logit "ERR: Exit status: $EXIT_STATUS"
		ERROR=1
	;;
esac


${LOGGER} "FYI: fw1logrotate done, output below"
logit < ${MY_LOGFILE}.tmp
/bin/rm -f ${MY_LOGFILE}.tmp

# This should have been created if fw1logrotate went well. And different
# from PREV_LOGDIR. Upon first run PREV_LOGDIR="." -- but still different
# from CURRENT_LOGDIR
LOGDIR=`find ${HTML} -maxdepth 1 -type d | sort -n | tail -1`

if [ "${PREV_LOGDIR}" = "${LOGDIR}" ]; then
	logit "ERR: prev logdir '${PREV_LOGDIR}' != current logdir '${LOGDIR}'"
	ERRORS=1
fi

# How successfull where we?
# - check we have switched the logfile
# - created required dirs
# AND
# - exported the logfile to *.txt -- eventually compressed to *.txt.gz
# - build at least one html document
# OR
# If we have the file $FWDIR/conf/masters, AND no hostname.domainname in it is ours
# then there should be no *.txt and no *.html files here if every log entry was
# sent correctly to 'masters'.
# If, however, there are problems delivering the logfile(s) to the master, process
# them locally and clean-up to avoid filling the filesystem

# The masters file has this format (NG, NGX)
# [Log]
# lognost | IP address
# ...
# Or a single line with IP or HOSTNAME on pre-NG
MASTERS="${FWDIR}/conf/masters"
D=`domainname`
H=`hostname`

IS_MASTER="NO"

case $D in
	"")	FQDN=${H}
	;;
	*)	FQDN=${H}.${D}
	;;
esac

logit "FYI: my FQDN = $FQDN"

if [ -f "${MASTERS}" ]; then
	logit "FYI: masters file \${FWDIR}/conf/masters"
	logit "FYI: Content of ${FWDIR}/conf/masters below"
	logit < ${FWDIR}/conf/masters
	logit "done"
	LOGHOST=`sed '/\[Log\]/,/\[.*\]/!d; /\[.*\]/d;' ${MASTERS}`
	LOGHOST=`echo $LOGHOST | sed 's/ .*//'`	# remove \n
	case "${LOGHOST}" in
		"")	# error in file or pre-NG stype master file. We have none left so ignore for now
			logit "ERR: Error in ${MASTERS} or firewall is pre-ngx"
			logit "FYI: IS_MASTER = YES"
			IS_MASTER="YES"
		;;
		*)	# does  my IP address, hostname and FQDN match loghost?
			logit "LOGHOST = $LOGHOST"
			FOUND=`(
				ifconfig -a | sed '/inet/!d; /127.0.0.1/d; s/.*addr://; s/[ \t].*//'
				echo ${FQDN}
			) | sed "/${LOGHOST}/!d" | sed -n '$='`
			if [ "${FOUND}" -gt 0 ]; then
				logit "FYI: found my IP or hostname in masters IS_MASTER = YES"
				IS_MASTER="YES"
			else
				logit "FYI: master is '${LOGHOST}' not me. IS_MASTER = NO"
				IS_MASTER="NO"
			fi
		;;
	esac
else
	# No masters file so I am the master
	logit "FYI: masters file \${FWDIR}/conf/masters NOT found"
	logit "FYI: Setting IS_MASTER = YES"
	IS_MASTER="YES"
fi

# Fix Apache Error #28 ¿ No space left on device which has nothing to do with
# space but turns out to be left over semaphore arrays see
# http://blog.ryantan.net/2010/04/apache-error-28-no-space-left-on-device/

NUMS=`ipcs -s | grep nobody|wc -l | tr -d ' '`

if [ "${NUMS}" -gt 50 ]; then
	ipcs -s | grep nobody | perl -e 'while (<STDIN>) { @a=split(/\s+/); print `ipcrm sem $a[1]`}'
	logit "removing apache left over semaphore arrays - found $NUMS expected way below 50"
fi

# notify somebody upon faileures using e-mail

if [ ! -d "${LOGDIR}" ]; then
	logit "error: ${LOGDIR} not found"
	ERRORS=1
else
	logit "FYI: dir '${LOGDIR}' ok"
	
	# The logfile might be compressed, but has to exist
	if [ -f ${LOGDIR}/`basename ${LOGDIR}`.txt ]; then
		LOGEXPORT=${LOGDIR}/`basename ${LOGDIR}`.txt
	else
		LOGEXPORT=${LOGDIR}/`basename ${LOGDIR}`.txt.gz
	fi

	if [ -f "${LOGEXPORT}" ]; then
		logit "FYI: export file '${LOGEXPORT}' found"

		if [ -s "${LOGEXPORT}" ]; then
			logit	"FYI: export file '${LOGEXPORT}' not empty"
		else
			if [ "$IS_MASTER" = "YES" ]; then
				logit	"ERR: export file '${LOGEXPORT}' is empty"
				ERRORS=1
			else
				logit	"FYI: export file '${LOGEXPORT}' is empty ok - loghost is '${LOGHOST}'"
			fi
		fi
	else
		if [ "$IS_MASTER" = "YES" ]; then
			logit	"ERR: export file '${LOGEXPORT}' not found"
			ERRORS=1
		else
			logit "FYI: export file  '${LOGEXPORT}' not found - ok as I am a module with a master"
		fi
	fi

	NUMBER_OF_FILES=`/bin/ls -1 ${LOGDIR}/*.html 2>/dev/null | wc -l | tr -d ' '`

	case $NUMBER_OF_FILES in
		0)	if [ "$IS_MASTER" = "YES" ]; then
				logit "ERR: no html files in ${LOGDIR} and I am master"
				ERRORS=1
			else
				logit	"FYI: no html files in '${LOGDIR}' - ok - loghost is '${LOGHOST}'"
			fi
		;;
		*)	logit "FYI: found ${NUMBER_OF_FILES} html files (ignored if not master)"
		;;
	esac
fi

if [ "${ERRORS}" -ne 0 ]; then
	. /var/opt/UNItools/conf/smtpclient.SH
	(
		echo ""
		echo "Hello IT Support"
		echo ""
		echo "An error has occoured during log roration on ${FQDN}. Please investigate."
		echo "Logfile below."
		echo "------------------------------------------------------------------"
		cat ${MY_LOGFILE}
		echo "------------------------------------------------------------------"
		echo "Log rotationslog ${LOGDIR}/fw1logrotate.log herunder:"
		echo "------------------------------------------------------------------"
		cat ${LOGDIR}/fw1logrotate.log
		echo "------------------------------------------------------------------"
		echo ""
	) | ${SMTPCLIENT} ${OPTIONS} -s "Log rotation failed on ${FQDN}"

	/bin/rm -f ${MY_LOGFILE}

	${LOGGER}		"notification sent by e-mail ${SMTPCLIENT} ${OPTIONS}"
fi

exit

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
#	fw1lr-wrapper.sh
# RESUME
#	Shell wrapper til fw1logrotate.pl på Nokia IPSO og Check Point VPN
#	appliance (Red Hat Linux).
# SYNOPSIS
#	\fBfw1lr-wrapper.sh\fR
# OPTIONS
#	Ingen. Scriptet udføres fra \fCcron(1)\fR.
# FORMÅL
#	Logrotation sker en gang i døgnet, styret af \fCcron(1)\fR.
#
#	Batch jobs har et meget begrænset 
#	standard environmentet på IPSO og VPN Appliance,
#	og indeholder bl.a. ikke \fC$FWDIR\fR.
#	Variablen sættes forskelligt på alle
#	Unix lignende platforme, men er altid sat i forbindelse med
#	enten \fC.profile\fR, \fC.bash_profile\fR, eller \fC.bashrc\fR.
#
#	Disse sources derfor af scriptet, før det kalder
#	\fCfw1logrotate.pl\fR via \fCexec(1)\fR.
#	
#	På \fCIPSO\fR er environmentet endog for
#	skrabet til, at Nokia's \fCperl(1)\fR kan udføres. \fC$LD_LIBRARY_PATH\fR
#	mangler at blive sat, for at Nokia's \fCperl(1)\fR kan starte (sic).
# PROGRAMPAKKE
#       Dette script er en del af UNI\(buCs programpakke
#       \fBUNIfw1lr\fR til rotation af Check Point firewall-1
#       logfiler. Programpakken er afprøvet på NG FP3 men
#       burde også virke på tidligere versioner (3.0b, 4.0 og
#       4.1 på Solaris).
# ANDET
#       Se dokumentation for programpakken.
# VERSION
#	$Header: /lan/ssi/shared/software/internal/UNIfw1lr/src/GaIA/RCS/fw1lr-wrapper.sh,v 1.1 2016/04/29 13:35:57 root Exp root $
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
