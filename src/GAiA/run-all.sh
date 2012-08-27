#!/var/opt/UNItools/bin/bash
#
# Copyright (c) 2001 UNI-C, NTH. All Rights Reserved, see LICENSE
#
#

P=/var/opt/UNIfw1lr/data/html
cd $P

for D in *
do
	DIR=$P/$D
	if [ -d $DIR ]; then
		sh /var/opt/UNIfw1lr/bin/default.report.sh $DIR
	fi
done

exit 0

#
# Copyright (c) 2001 UNI-C, NTH. All Rights Reserved
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF UNI-C, DENMARK
# The copyright notice above does not evidence  any  actual  or
# intended publication of such source code.
#

#++
# NAVN
#	run-all.sh
# RESUME
#	Processer alle gamle logfiler.
# SYNOPSIS
#	\fBrun-all.sh\fR 
# OPTIONS
# Ingen.
# FORMÅL
#	Script til aftesting i forbindelse med installation. Ikke et
#	produktionsscript.
# PROGRAMPAKKE
#       Dette script er en del af UNI\(buCs programpakke
#       \fBUNIfw1lr\fR til rotation af Check Point firewall-1
#       logfiler. Programpakken er afprøvet på NG FP3 men
#       burde også virke på tidligere versioner (3.0b, 4.0 og
#       4.1 på Solaris).
# ANDET
#       Se dokumentation for programpakken.
# VERSION
#       $Header: /lan/ssi/shared/software/internal/UNIfw1lr/src/GaIA/run-all.sh,v 1.1 2016/04/29 13:35:57 root Exp $
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
