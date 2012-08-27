#!/var/opt/UNItools/bin/perl -w
#
# Copyright (c) 2001 UNI-C, NTH. All Rights Reserved, see LICENSE
#
#
########################################################################
#
# Requirements
#
require "pwd.pl";
require "newgetopt.pl";
require "getcwd.pl";
require "ctime.pl";
use POSIX qw(strftime);
use File::Path;

########################################################################
#
# Global vars
#
########################################################################

my $ME		= "fw1logrotate.pl for Linux, Solaris and Nokia";
my $version	= '$Id$';

my $now     	= time();		# starttid
my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks, $file);

my $oldlogfile	= strftime "%Y_%m_%d_%H-%M-%S", localtime($now); 
my $time_now	= strftime "%d %B %Y kl. %H:%M:%S", localtime($now);

my $fw_ver	= "unknown";	# Firewall-1 version

my $str		= "";		# tmp. streng

########################################################################
#
# Default values -- goes to $CONFIG
#
########################################################################
#
# If $CONFIG exists, I'll read it. If not, I'll create it with the
# following default values.
#
my $CONFIG		=  "/var/opt/UNIfw1lr/conf/fw1logrotate.conf";

#
# I'm installed below here. If you change this, you may have to modify
# other scripts as well.
#
my $uni_fw1lr_home	= "/var/opt/UNIfw1lr";
#
# ROOT for logfiles
# 
my $datadir		= "$uni_fw1lr_home/data";		# ~ /var/log/fw1
#
# Soft link to where FW1 stores current log(s)
#
my $current		= "$datadir/current";			# ~ $ENV{$FWDIR}/log;
#
# Binary FW1 logfiles and their derived files will survive uncompressed
# this number of days
#
my $online_retension	= 10;	
#
# My copy / hard link of the FW1 logs stored below here in separate
# directories, one for each day.
#
my $html		= "$datadir/html";			# ~ /var/log/fw1/old
#
# Keep compressed versions of the logfiles this number of days
#
my $offline_retension	= 10;	
#
# Use this command to build a report
#
my $rapportgenerator	= "$uni_fw1lr_home/bin/default.report.sh";
#
# Use this command to make 'index.html' in $html
#
my $indexgenerator	= "$uni_fw1lr_home/bin/mkindex";

#
# Keep track of what I'm doing by writening to this file (will be overwritten)
#
my $MYLOG		=  "$html/$oldlogfile/fw1logrotate.log";
#
# Path to required applications. 
#
$tar="/var/opt/UNItools/bin/tar";			# Posix TAR
$gzip="/var/opt/UNItools/bin/gzip";			# GNU zip
$gunzip="/var/opt/UNItools/bin/gunzip";			# GNU unzip

########################################################################
#
# SUB ROUTINES
#
########################################################################


sub isolderthan() {
# purpose     : Determin if a file is older than nr. of days
# arguments   : days-to-be-older-than and filename. Age is determined
#             : by the filename, not access or creation time.
# return value: 1 if the file is older than, otherwise 0
# see also    :
	my ( $days, $file) = @_ ;
	my ( $tmptime)     = $now;	
	my ( $year)        = "";
	my ( $month)       = "";
	my ( $monthday)    = "";
	my ( $hour)        = "";
	my ( $min)         = "";
	my ( $sec)         = "";

	for  (0..$days) {
		($year, $month, $monthday, $hour, $min, $sec) =
		split(' ', strftime "%Y %m %d %H %M %S", localtime($tmptime));

		# 
		# Match "$year $month $monthday" against $filename
		# 

		$ptrn = $year . "_" . $month . "_" . $monthday ;

		$file =~ s/(...._.._..).*/$1/;		

		#
		# Stop if match -- the file isn't old enough to be deleted
		#
		return (0) if ($ptrn eq $file);

		$tmptime = $tmptime - (60 * 60 * 24);
	}

	#
	# No match, so the file is old enough to be deleted
	#
	return (1);

}

sub log {
# purpose     : Print a time-stamped line to my logfile
# arguments   : The line to be printed
# return value: None
	@t = localtime(time);
	$t[4]++;		# Month i nul-base on perl
	printf LOG "%02d/%02d/%02d %02d:%02d:%02d\t%s\n", @t[4,3,5, 2,1,0], "@_";
}

########################################################################
#
# MAIN
#
########################################################################
#
# Parse and process options
#
NGetOpt("c=s", "o=s", "l=s", "f=s") ||
	die "usage: $0 [-c current] [-o online_retension] [-l oldlogdir] [-f offline_retension]\n [-r rapportgenerator ] - argumentet til rapportgeneratoren er oldlogdir";

#
# Read / construct the config file
#
if (open(CONF, "<$CONFIG")) {
	while(<CONF>) {
		chomp;
		s/#.*$//;		# Fjern comments
		if( /datadir\s*:\s*(\S+)/)
			{ $datadir = $1; }
		if( /current\s*:\s*(\S+)/)
			{ $current = $1; }
		if( /online_retension\s*:\s*(\S+)/)
			{ $online_retension = $1; }
		if( /html\s*:\s*(\S+)/)
			{ $html = $1; }
		if( /offline_retension\s*:\s*(\S+)/)
			{ $offline_retension = $1; }
		if( /rapportgenerator\s*:\s*(\S+)/)
			{ $rapportgenerator = $1; }
		if( /indexgenerator\s*:\s*(\S+)/)
			{ $indexgenerator = $1; }
		if( /tar\s*:\s*(\S+)/)
			{ $tar = $1; }
		if( /gzip\s*:\s*(\S+)/)
			{ $gzip = $1; }
		if( /gunzip\s*:\s*(\S+)/)
			{ $gunzip = $1; }
		}
	close (CONF);
} else {
	if (open (CONF, ">$CONFIG")) {
	print CONF<<EOF
#
# config file for UNIfw1lr made by $ME at $time_now
#
# Syntax:
#	var : value
# White space not allowed
#
# datadir:            Her lægges FW1 logfiler; normalt
#                    /var/opt/UNIfw1lr/log
# current:           Identisk med \$FWDIR/log eller
#                    /var/opt/UNIfw1lr/log/current
# online_retension:  Antal dage binære FW1 logfiler overlever
#                    i datadir.
# html:           Her lægges gamle logfiler (som hardlinks),
#                    rapporter og tekstuel eksport af FW1 log.
#                    De overlever ligeledes i online_retension
#                    dage.
# offline_retension: Antal dage html skal overleve efter de
#                    er gemt som tgz arkiver.
# rapportgenerator:  Et eventuelt program der kan lave
#                    statistisk bearbejdning af den tekstuelle
#                    log.
# indexgenerator:    Et eventluelt program der kan lave en
#                    index side for alt i $datadir
#
# Der anvendes tre hjælpeprogrammer: tar, zip og unzip.
# 
datadir:			$datadir
current:		$current
online_retension:	$online_retension
html:		$html
offline_retension:	$offline_retension
rapportgenerator:	$rapportgenerator
indexgenerator:	        $indexgenerator
tar:			$tar
gzip:			$gzip
gunzip:			$gunzip
#
EOF
}
close (CONF);
}

#
# Overrule configuration / default values with
# arguments from the command line, if any
#
if ( $opt_c ) {
	$current = $opt_c;
}

if ( $opt_o ) {
	$online_retension = $opt_o;
}

if ( $opt_l ) {
	$html = $opt_l;
}

if ( $opt_f ) {
	$offline_retension = $opt_f;
}

if ( $opt_r ) {
	$rapportgenerator = $opt_r;
}

#
# 0 Is it possible to do anything alt all, except for creating a
#   configuration file ?
#

#
# check FWDIR
#
$ENV{'FWDIR'}	= $ENV{'FWDIR'}	? $ENV{'FWDIR'} : "/etc/fw";
die "\$FWDIR = $ENV{'FWDIR'}: $!" unless ( -d "$ENV{'FWDIR'}");

$fw		= "$ENV{'FWDIR'}/bin/fw";	# Here on all versions/platforms

#
# Logrotation: pre NGX anvend fw, NGX anvend fwm
# stop/start : pre NG anvend fwstop/fwstart, post anvend cpstop/cpstart
#

open (PIPE, "$fw ver | ") || warn "cannot fork: $!";
while (<PIPE>) {
	chomp ;

	if ( $_ =~ /3\.0/ )
	{
		$fw_ver		= "3.0";
		$fwm		= "$ENV{'FWDIR'}/bin/fw";
		$cpstop		= "$ENV{'FWDIR'}/bin/fwstop";
		$cpstart	= "$ENV{'FWDIR'}/bin/fwstart";
		last;
	};
	if ( $_ =~ /4\.0/ )
	{
		$fw_ver		= "4.0";
		$fwm		= "$ENV{'FWDIR'}/bin/fw";
		$cpstop		= "$ENV{'FWDIR'}/bin/fwstop";
		$cpstart	= "$ENV{'FWDIR'}/bin/fwstart";
		last;
	};
	if ( $_ =~ /4\.1/ )
	{
		$fw_ver		= "4.1";
		$fwm		= "$ENV{'FWDIR'}/bin/fw";
		$cpstop		= "$ENV{'FWDIR'}/bin/fwstop";
		$cpstart	= "$ENV{'FWDIR'}/bin/fwstart";
		last;
	};
	if ( $_ =~ /NG |R55/ )
	{
		$fw_ver = "NG";
		$fwm		= "$ENV{'FWDIR'}/bin/fwm";
		$cpstop		= "$ENV{'CPDIR'}/bin/cpstop";
		$cpstart	= "$ENV{'CPDIR'}/bin/cpstart";
		last;
	};
	if ( $_ =~ /NGX|R6?|R7?/ )
	{
		$fw_ver		= "NGX";
		$fwm		= "$ENV{'FWDIR'}/bin/fwm";
		$cpstop		= "$ENV{'CPDIR'}/bin/cpstop";
		$cpstart	= "$ENV{'CPDIR'}/bin/cpstart";
		last;
		logit("fw ver '$_' matched NGX, R6x or R7x");
	};
}
close (PIPE);

$rc = 0xffff & $?;
$str = sprintf "running '%s' returned %#04x: ", "fw ver", 0xffff & $?;

if ($rc == 0) {
	$str .= "with normal exit\n";
} elsif ($rc == 0xff00) {
	$str .= "command failled $!\n"; print("error: $str");
} elsif ($rc > 0x90) {
	$rc >>= 8;
	$str .= "ran with non-zero exit status $rc\n"; print("error: $str");
} else {
	$str .= "ran with ";
	if ($rc & 0x80) {
		$rc &= ~0x80;
		$str .= "core dump from ";
	}
	$str .= "signal $rc\n"; print("error: $str");
}

foreach ( $tar, $gzip, $gunzip, $fw, $cpstop, $cpstart) {
	die "Kommandoen '$_'. kan ikke udføres, kontroller $CONFIG. bye-bye"
		unless ( -x $_ );
}

#
# Create a directory to hold hardlink of logfiles and derived files
#
mkdir("$html/$oldlogfile", 0755) ||
	die "mkdir $html/$oldlogfile: $!";

open(LOG, ">$MYLOG") || die "Logging to logfile '$MYLOG' failled: $!" ;
select(LOG); $| =1;
select( STDERR );  $| = 1;
select( STDOUT );  $| = 1;

open(STDOUT, ">&LOG") || die ("re-open STDOUT to LOG failled: $!");
open(STDERR, ">&LOG") || die ("re-open STDERR to LOG failled: $!");

print<<EOF;
--------------------------------------------------------------------------------
$ME
================================================================================

Starttid          = $time_now
Programnavn       = $ME
Program version   = $version
Konfigurationsfil = $CONFIG

firewall version  = $fw_ver

datadir            = $datadir
current           = $current
online_retension  = $online_retension

html           = $html
offline_retension = $offline_retension

oldlogfile        = $oldlogfile

Rapportgenerator  = $rapportgenerator
Index generator   = $indexgenerator

EOF

die "$datadir: $!"	unless ( -d "$datadir" );
die "$html: $!"	unless ( -d "$html" );

#
# During upgrade/patching of FW1 on Nokia, $FWDIR is changed
# So the soft link pointing to FWDIR/log may have to be re-created
#
# So the script relays on FWDIR to be set.
#
my $env_fwdir_log     = "$ENV{'FWDIR'}/log";
my $real_current      = readlink($current);

if (! $real_current ) {
	#
	# The name for the link exists, but isn't a link. This
	# is an error, someone else has to fix it
	#
	if ( -e $current ) {
		die "$current findes og er ikke et link. Ret det.\n";
	} else {
		#
		# The link doesn't exist
		#
		print "$current findes ikke\n";
		symlink("$env_fwdir_log", "$current")
			|| die "symlink \$current '$current' -> \$env_fwdir_log '$env_fwdir_log': $!";
		print "Har symlinket det til FWDIR/log\n";
	}
} else {
	if ("$real_current" ne "$env_fwdir_log") {
		#
		# The link exists but doesn't point to FWDIR/log. Delete it, and
		# re-create it.
		#
		print "Linket current ! -> FWDIR/log\n";
		print "Sletter current og re-symlinker det til FWDIR/log\n";
		print "det pegede på '$real_current' \n";
		unlink("$current") || die "unlink \$current = '$current' failled: $!";
		symlink("$env_fwdir_log", "$current")
			|| die "symlink \$current '$current' to \$env_fwdir_log '$env_fwdir_log' failled: $!";
		print "symlink ok\n";
	} else {
		#
		# It's ok
		#
		print "Linket current -> FWDIR/log, hvilket er ok\n";
	}

}
#
# This is unlikely, but shit happens
#
die "$current: $!"	unless ( -d "$current" );

#
# If we are on a module, use contents of $FWDIR/conf/masters to
# build fw fetch command
#

if ( -f "$ENV{'FWDIR'}/conf/masters" ) {
	open ( M, "$ENV{'FWDIR'}/conf/masters") ||
		die "$ENV{'FWDIR'}/conf/masters': $!";
	line: while (<M>) {
		/^\s*$/ && next line;
		chomp ;
		$masters .= $_;
	}
	close (M);
} else {
	$masters = "localhost";
}
	
#
# 2 Now for the logswitch
#
&log("Udfører $fw logswitch $oldlogfile");

open ( FW, "$fw logswitch $oldlogfile 2>&1 |" ) ||
	die "$fw logswitch $oldlogfile: $!";

line: while (<FW>) {
	chomp;
	print "$_\n";
}
close (FW);

&log("...");
&log("Test for kendt fejl ved logswitch ... ");
&log("Fejlen optræder både i 3 (patch findes) og 4.1 (ved store logfiler)");
&log("og viser sig ved at 'fw log ...' giver fejlen 'SwOpen' et eller andet");

# 
# Attemtp to fix an error re-introduced 2 times by Check Point related to
# logswitch:
# 
# SwOpen: can't get inode of /etc/fw/log/fw.log: No such file or directory
#
# Fix it by stoping all processes working with fw.log including the firewall
# and re-start everything.
# 

open (FWLOG, "$fw log -n | ") ||
	die "fwlog: $!";

line: while (<FWLOG>) {
	chomp;
	if ($. < 10) {
		if ($_ =~ m/SwOpen/) {
		print "FW1 lavede en fatal fejl ved logswitch, opgrader venligst\n";
		print "kompencerer for fejlen (cpstop, cpstart, fw fetch $masters) ... \n";

		system("$cpstop");
		system("$cpstart");
		system("$fw fetch $masters");

		last line;
		
		}
		next line;
	}
	else {
		&log(".. alt ser normalt ud ...");
		last line;
	}
}

close (FWLOG);

#
# 3 Hardlink $oldlogfile* to $html/$datadir/$oldlogfile
#   Notice, that this requires the files to be on the same
#   filesystem
# 
opendir(CURRENT, "$current") ||
	die "opendir $current: $!";

@files = grep ( ! -d $_ && /^$oldlogfile*/, readdir(CURRENT) );
closedir(CURRENT);

foreach (@files) {
	link ("$current/$_", "$html/$oldlogfile/$_") ||
		die "hard link fejlede - er det på samme partition ? : $!";

	&log("HARD link $_ -> $html/$oldlogfile");
}

#
# 4 Clean up in $FWLOG, by truncating logfiles not related to the
#   firewall log (wonderfull english ;-)
#
&log("oprydning / trunkering af firewall-1 ikke-sikkerheds-logfiler mangler !");

#
# 5 export $html to text with IP addresses not FQDN
#

# $str = "$fwm logexport -n -i $html/$oldlogfile/$oldlogfile.log -o $html/$oldlogfile/$oldlogfile.txt";
#
# Large file breaks see sk65298 (avoid using -o file)
# See also sk37660 on how to use the -f argument in combination with $FWDIR/conf/logexport.ini
# The logexport.ini is created by during installation of UNIfw1lr, and is abesnt when the firewall
# software installation has ended. The -f argument can only be used on the active logfile.
#
# $str = "$fwm logexport -n -i $html/$oldlogfile/$oldlogfile.log > $html/$oldlogfile/$oldlogfile.txt";
$str = "$fwm logexport -n -i $html/$oldlogfile/$oldlogfile.log > $html/$oldlogfile/$oldlogfile.txt 2>/dev/null ";

#TODO: this command MAY have added one extra stupid line at the beginning of the file ... "

&log("$str");

open (FWLOG, "$str 2>&1 |") ||
	die "fw logexport: $!";
line: while (<FWLOG>) {
	chomp;
	&log("$_");
}
close (FWLOG);

$rc = 0xffff & $?;
$str = sprintf "running '%s' returned %#04x: ", "$fwm logexport ...", 0xffff & $?;

if ($rc == 0) {
	$str .= "with normal exit\n";
} elsif ($rc == 0xff00) {
	$str .= "command failled $!\n"; print("error: $str");
} elsif ($rc > 0x90) {
	$rc >>= 8;
	$str .= "ran with non-zero exit status $rc\n"; print("error: $str");
} else {
	$str .= "ran with ";
	if ($rc & 0x80) {
		$rc &= ~0x80;
		$str .= "core dump from ";
	}
	$str .= "signal $rc\n"; print("error: $str");
}

&log("$str");

#
# 6 If we are a module no logging should take place here.
#   but it does, it the connection to the master goes down. Pre NG
#   leaves the logfile local, so here is something for you, dear reader:
#   Insert code to scp the logfile(s) to the master and merge it in.
#
# &log("MANGLER TEST FOR, OM VI ER ET MODUL, DER MED SSH SKAL SENDE TIL MASTER !!!\n");

#
# 7 Clean up time in $current: Delete old files
#

opendir(CURRENT, "$current") ||
	die "opendir $current: $!";

&chdir("$current") ||
	die "chdir $current: $!";

&log("Oprydning i $current");

#
# Read files in $current matching dddd_dd_dd.* (year _ month _ date bla bla)
#
@files = grep ( ! -d $_ && /^\d\d\d\d_\d\d_\d\d*/, readdir(CURRENT) );
closedir(CURRENT);

$total_size = 0;

foreach $file (@files) {
	($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);

	$size /= ( 1024 * 1024 );

	if( &isolderthan( $online_retension, $file ) ) {

		&log("sletter $file $size Mb [FW1 logfil]");
		unlink ("$current/$file");
		$total_size += $size;
	} 
	else {
		&log("beholder $file $size Mb [FW1 logfil]");
	} 
}

#
# Tell much did we get rid of
#
&log("Slettet ialt $total_size Mb");

#
# 9 Clean up in $offline_retension, by compressing all $html
#   older than $online_retension - but only if we have more disk
#   space than 2*$datadir
#

opendir(OLDLOGS, "$html") ||
	die "opendir $html: $!";

&chdir("$html") ||
	die "chdir $html: $!";

&log("Komprimering i $html");

@dirs = grep ( ! -f $_ && /^\d\d\d\d_\d\d_\d\d.*/, readdir(OLDLOGS) );
closedir(OLDLOGS);

foreach $dir (@dirs) {
	if( &isolderthan( $online_retension, $dir ) ) {
		&log("Komprimerer $dir ... ");

		# Hmm - something more for the reader: insert code here
		# to check if we have enough free space
		system("$tar cf - $dir | $gzip -9 > $dir.tar.gz");

		# Check the compression went well. If so delete the
		# directory
		$err = system("$gunzip -t $dir.tar.gz");

		die "Komprimering fejlede: $!" if ($err);
		rmtree( "$dir", 0, 0);
	}
	else {
		&log("beholder $dir [online katalog med hardlink af logfiler]");
	}
}

#
#  9 delete archives older than $online_retension + $offline_retension
#
opendir(OLDLOGS, "$html") ||
	die "opendir $html: $!";

&chdir("$html") ||
	die "chdir $html: $!";

&log("Oprydning i $html");

# Find all files matching dddd_dd_dd.* and delete them if they are older
# than $offline_retension
@files = grep ( ! -d $_ && /^\d\d\d\d_\d\d_\d\d.*/, readdir(OLDLOGS) );
closedir(OLDLOGS);

foreach $file (@files) {
	($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
	$size /= ( 1024 * 1024 );

	if( &isolderthan( $online_retension + $offline_retension, $file ) ) {
		$total_size += $size;
		&log("$file $size Mb");
		unlink ("$html/$file");
	} 
	else {
		&log("beholder $file [arkiv med logfiler]");
	} 
}
&log("slettet $total_size Mb[arkiv med logfiler]");

#
# 10 Build a daily statistic and set the mode of $html to 'readable' - 644
#
if ( -x $rapportgenerator ) {
	system("$rapportgenerator $html/$oldlogfile");
} else {
	&log("rapportgenerator '$rapportgenerator' kan ikke udføres\n");
}

opendir(OLD_LOG_FILES, "$html/$oldlogfile") ||
	die "opendir $html/$oldlogfile: $!";
@files = grep (! -d, readdir(OLD_LOG_FILES));
closedir(OLD_LOG_FILES);

foreach $file (@files) {
	chmod (0644, "$html/$oldlogfile/$file") ||
	die "chmod $html/$oldlogfile/$file: $!";
}

#
# Buld 'index.html' for all directories and tgz files
#
if ( -x $indexgenerator) {
	system("$indexgenerator");
} else {
	&log("indexgenerator '$indexgenerator' kan ikke udføres\n");
}

&log("S L U T");

exit 0;

__DATA__

#++
# .\" srctoman - $0 > $0.1
# .\" Niels Thomas Haugård UNI-C
# NAVN
#	fw1logrotate 1
# SUMMARY
#	rotation og konsolidring af Check Point FireWall-1 logfiler.
# PACKAGE
#	UNIfwmon
# SYNOPSIS
#	\fBfw1logrotate\fR [options]
# PARAMETRE
#	\fBfw1logrotate\fR kan kaldes med følgende parametre:
# .TP
#	-c \fIkatalog\fR
# 	FireWall-1 logkatalog - $FWDIR/log. Her gemmes
#	gamle binære FireWall-1 logfiler. I dokumentationen vil det blive
#	omtalt som \fC$current\fR. Hvis kataloget \fIikke\fR findes,
#	afbrydes programmet. Er firewall'en installeret af UNI\(buC, vil
#	kataloget altid være \fC/var/opt/UNIfw1lr/log/current\fR.
# .TP
#	-o \fIantal\fR
#	Antal dage gamle logfiler skal blive liggende i $current.
# .TP
#	-l \fIkatalog\fR
#	Det katalog hvor gamle logfiler gemmes efter de er blevet slettet
#	fra $current. I dokumentationen vil det blive omtalt som
#	\fC$html\fR. Hvis kataloget \fIikke\fR findes,
#	afbrydes programmet.
# .TP
#	-f \fIantal\fR
#	Antal dage, gamle logfiler skal gemmes før de slettes, ud over
#	den tidsperiode de ligger online. Antallet af dage er summen af
#	argumentet til f og o, eller deres standardværdier.
# .TP
#	-r \fIrapportgenerator\fR
#	argumentet til rapportgeneratoren er $oldlogdir.
#
# STANDARDVÆRDIER
#	Første gang programmet kaldes, oprettes en præferancefil i
#	\fC/etc\fR med følgende værdier:
#	\fC
#.\"pr -t -e8 -n 'data'
# .nf
#	\fC
    1	#
    2	# Konfigurationsfil for /var/opt/UNIfw1lr/bin/fw1logrotate.pl
    3	# Oprettet: 02 March 2001 kl. 17:20:12
    4	#
    5	# Variabel : værdi
    6	# Bemærk, at værdi ikke kan indeholde whitespace.
    7	# Se dokumentationen for en beskrivelse af de enkelte værdier.
    8	#
    9	# datadir:            Her lægges FW1 logfiler; normalt
   10	#                    /var/opt/UNIfw1lr/log
   11	# current:           Identisk med $FWDIR/log eller
   12	#                    /etc/fw/log (linket findes ikke på Nokia).
   13	# online_retension:  Antal dage binære FW1 logfiler overlever
   14	#                    i datadir.
   15	# html:           Her lægges gamle logfiler (som hardlinks),
   16	#                    rapporter og tekstuel eksport af FW1 log.
   17	#                    De overlever ligeledes i online_retension
   18	#                    dage.
   19	# offline_retension: Antal dage html skal overleve efter de
   20	#                    er gemt som tgz arkiver.
   21	# rapportgenerator:  Et eventuelt program der kan lave
   22	#                    statistisk bearbejdning af den tekstuelle
   23	#                    log.
   24	# Der anvendes tre hjælpeprogrammer: tar, zip og unzip.
   25	#
   26	datadir:                 /var/opt/UNIfw1lr/log
   27	current:                /var/opt/UNIfw1lr/log/current
   28	online_retension:       10
   29	html:                /var/opt/UNIfw1lr/log/html
   30	offline_retension:      10
   31	rapportgenerator:       /opt/UNIfw1lr/default.report.sh
   32	tar:                    /etc/tar
   33	gzip:                   /usr/local/bin/gzip
   34	gunzip:                 /usr/local/bin//gunzip
   35	#


# .fi
#	\fR
# PROCEDURE FOR LOGROTATION
#	fw1logrotate - UNI-C FW1 log konsolidering, rotation og manipulation
#	Kogebog i FireWall-1 logrotation
# .TP
#	1
#	Beregn hvad tiden er nu, parse argumenter og lav logkataloget til
#	de gamle logfiler. Stop ved fejl.
# .TP
#	2
#	Foretag logskift, gammel logfil gemmes som $oldlogfilename. Kontroller,
#	at \fC$FWDIR/bin/fw logswitch $oldlogfilename\fR gik godt.
# .TP
#	3
#	Hard Link binære logfiler til $html/$datadir/$oldlogfilename.
#	Bemærk, at hard links \fIikke\fR virker under Microsoft Windows.
#	Nærværende program kræver et Posix system.
# .TP
#	4
#	Ryd op i $FWLOG - dvs. trunker de logfiler der ikke er relateret
#	direkte til firewall loggen. \fBDenne del mangler for version 3, 4 og
#	4.1\fR.
# .TP
#	5
#	Eksporter $oldlogfilename til $html/$datadir/$oldlogfilename.txt
#	- hvis der er diskplads nok (4 * logfil størrelse ?). \fBBetingelsen
#	mangler\fR.
# .TP
#	6
#	Check at vi ikke er et modul, der burde have afleveret logfiler
#	til en loghost. Kopier/flyt i så fald logfiler, rapporter mv. dertil
#	og adviser om, at noget er galt. \fBDenne del mangler\fR.
# .TP
#	7
#	I $FWC/log: slet logfiler ældre end $online_retension. Se ikke
#	på tidsstempel men navn.
# .TP
#	8
#	I $html: Komprimer (tgz) alle $datadir ældre end $online_retension
#	- hvis der er diskplads nok (2*$datadir). \fBBetingelsen mangler\fR.
# .TP
#	9
#	I $html: slet tgz arkiver ældre end $offline_retension.
# .TP
#	10
#	Lav en daglig statistik ved hjælp af rapportgeneratoren. Afslutter den
#	ikke inden for 'rimelig tid', er der på nuværende tidspunkt ryddet op,
#	så disken ikke løber fuld. Men det kan process tabellen stadig gøre, ind
#	til dette script begynder at undersøge, om rapportgeneratoren kører fra
#	sidste gang.
# .TP
#	11
#	Lav et index.html for \fChtml\fR.
#
# BEMÆRKNINGER
#	Dette system er beregnet på at køre een gang i \fIdøgnet\fR.
#	Køres det hyppigere, laves flere forskellige logfiler, eksporterede
#	logfiler, rapporter og kataloger disse gemmes i.
# .PP
#	Den nuværende version vil senere blive udvidet med en mulighed for,
#	at kunne foretage logskift flere gange i døgnet på f.eks. meget
#	belastede systemer, hvor logfilerne, de eksporterede logfiler og
#	rapporter grupperes for et døgn ad gangen.
# KENDTE FEJL
#	Hvis dette script skal kunne anvendes på NT, SUN, HP og AIX må 
#	man kan kun anvende 'aAbBcdHIjmMpSUwWxXyYZ%' i \fCstrftime(3)\fR.
# ANDET
#       Se dokumentation for programpakken.
# VERSION
#       $Header: /lan/ssi/shared/software/internal/UNIfw1lr/src/GaIA/RCS/fw1logrotate.pl,v 1.3 2016/05/02 20:51:55 root Exp $
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
