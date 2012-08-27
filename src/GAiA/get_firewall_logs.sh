#!/bin/bash
#
# $Header$
#
# vim: set number ts=4 sw=4:
#
# Copyright (C) 2012 Niels Thomas Haugård
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#
# Default vars
#
MYNAME=get_firewall_logs

DSTDIR=/home/data/fw_log/
MY_LOGFILE=${DSTDIR}/log/${MYNAME}.log
TMPFILE=${DSTDIR}/log/tmpfile
ARCHIVE_LIST=${DSTDIR}/log/archive_list

KEEPDAYS=30

export LC_ALL=C
export LANG=C

# RCPT="ttx@HVIDOVRE.DK"
RCPT="fw-backup@hvidovre.dk"

PORT=9876
SRVR=10.1.0.10

#
# Functions
#
function mydie() {

  echo $*
  exit 1

}

function logit() {
# purpose	 : Timestamp output
# arguments   : Line og stream
# return value: None
# see also	:
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		if [ "${VERBOSE}" = "TRUE" ]; then
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				if [ "${VERBOSE}" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}


clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
	$echo trapped
	/bin/rm -f $TMPFILE
        exit 1
}

#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

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

#
# Process arguments
#
while getopts v opt
do
case $opt in
	v)	VERBOSE=TRUE
	;;
esac
done
shift `expr $OPTIND - 1`

cd ${DSTDIR} || {
  my_die "chdir ${DSTDIR} failed"
}

test -d ${DSTDIR}/log/ || {
  mkdir ${DSTDIR}/log/
}

/bin/rm -f $MY_LOGFILE $TMPFILE

cat << EOF |nroff  -man |sed '/^$/d' | logit
Firewall log consolidation
.br
Scriptname $0
.br
Arguments $*
.br
Exeuted by cron
.br
User `whoami`
.br
hostname `hostname`
.br
Usage
.br
The script uses wget to retreive and store firewall log files. The files are retreived with wget from
https://${SRVR}:${PORT}
.br
An identical copy (mirror) is save in the directory ${DSTDIR}/${SRVR}:${PORT}.
.br
The log files are archived (compressed tar archives) and moved to ${DSTDIR}.
.br
Only the last ${KEEPDAYS} archives are preserved.
.br
When a file is no longer available on the firewall it will be
removed from ${DSTDIR}/${SRVR}:${PORT} as well. wget 'mirror' relais on the content of
the file index.html found on the firewall.
.br
The script uses hard links to preserve space. See http://en.wikipedia.org/wiki/Hard_link.
.br
A small report is send by mail to $RCPT. The subject reflects the succes rate.
.br
If a fatal error is encountered the script exits ungracefully.
EOF

logit "$0 starting ... "

logit "mirroring content of ${SRVR}:${PORT} ... "
logit "work dir is `pwd`"
wget -N --reject 'index.html' -r -m --no-check-certificate https://${SRVR}:${PORT} > ${TMPFILE} 2>&1
ERRORS=$?
case $ERRORS in
	0)  MSG="wget: No problems occurred."
	;;
	1)  MSG="wget: Generic error code."
	;;
	2)  MSG="wget: Parse error"
	;;
	3)  MSG="wget: File I/O error."
	;;
	4)  MSG="wget: Network failure."
	;;
	5)  MSG="wget: SSL verification failure."
	;;
	6)  MSG="wget: Username/password authentication failure."
	;;
	7)  MSG="wget: Protocol errors."
	;;
	8)  MSG="wget: Server issued an error response"
	;;
esac

case $ERRORS in
	0)	logit "$MSG"
	;;
	*)	logit "wget failed with $MSG Log below"
		logit < ${TMPFILE}
	;;
esac

cd ${DSTDIR}/${SRVR}:${PORT} || {
	my_die "chdir ${DSTDIR}/${SRVR}:${PORT} failed"
}

ls -1 *gz | while read TGZFILE
do
	if [ ! -e ../${TGZFILE} ]; then
		ln ${TGZFILE} ../${TGZFILE}
		logit "creating hard link ${TGZFILE} -> .. "
	else
		/bin/rm -f ../${TGZFILE}
		ln ${TGZFILE} ../${TGZFILE}
		logit "${TGZFILE} removed and re-linked"
	fi
done

/bin/rm -f $TMPFILE

# create a backup archive for each directory, if the archive does
# not exist
cd ${DSTDIR}/${SRVR}:${PORT}
ls -1 |grep -v tar.gz | while read DIRECTORY
do
	if [ -e ${DSTDIR}/${DIRECTORY}.tar.gz ]; then
		logit "${DIRECTORY}.tar.gz ok"
	else
		logit "creating ${DSTDIR}/${DIRECTORY}.tar.gz ... "
		tar cvfpz ${DSTDIR}/${DIRECTORY}.tar.gz ${DIRECTORY} > ${TMPFILE}
		ERRORS=$?
		case $ERRORS in
		0)	logit "done"
		;;
		*)	logit "tar failed, errors below:"
			logit < ${TMPFILE}
		;;
		esac
	fi
done

logit "Now remove all but the last ${KEEPDAYS} archives in ${DSTDIR}"
cd ${DSTDIR}
ls -1 | grep 'tar.gz' | tac |awk '{ if (NR > '"${KEEPDAYS}"') { print "remove " $0 } else { print "keep " $0 } }' | while read EXEC FILE
do
	case ${EXEC} in
		remove)	logit "removing archive ${FILE}"
		;;
		keep)	logit "keeping archive ${FILE}"
		;;
		*)		logit "error ignored: \${EXEC} = ${EXEC}"
		;;
	esac
done

logit "`du -hs ${DSTDIR}`"


SUBJECT="firewall log archive finished with $ERRORS errors"

logit "$0 finished"

logit "Mail -s ${SUBJECT}"

printf "%75s\n" "`date`" > ${TMPFILE}
cat << EOF | fmt >> ${TMPFILE}

Hi

Archiving of your Check Point firewall logfile(s) exited with $ERRORS errors. The message from
the retreival was $MSG

Your logfiles takes up `du -hs ${DSTDIR} | awk '{ print $1 }'` of space in ${DSTDIR}

Please pay attention to your filesystem usage, it is

EOF

df -h ${DSTDIR} >> ${TMPFILE}
cat << EOF | fmt >> ${TMPFILE}

Regards, $0 at `hostname`

The process log is shown below for your information.
EOF

cat $MY_LOGFILE >> $TMPFILE

/usr/bin/Mail -s "${SUBJECT}" ${RCPT} < ${TMPFILE}

exit 0

__DATA__

echo '*********wget fra firewall start*********'  >> /var/log/fw.log
date >> /var/log/fw.log
cd /home/data/fw_log/${SRVR}:${PORT} 
rm -r *
cd /home/data/fw_log/
wget -m -k  --no-check-certificate https://${SRVR}:${PORT} -a /var/log/fw.log >> /var/log/fw.log
date >> /var/log/fw.log
cp /home/data/fw_log/.htaccess /home/data/fw_log/${SRVR}:${PORT}/
echo '********* wget fra firewall slut*********'  >> /var/log/fw.log

exit

