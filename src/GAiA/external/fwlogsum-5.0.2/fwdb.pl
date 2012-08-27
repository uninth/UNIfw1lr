#!/usr/bin/perl -w
#==============================================================================
# $Id$
#
# This simple script can be used a starting base for generating reports from
# the trend databases.  It will return the top number of entries from the
# specified database.
#
# Once you have this data, you could easily import it into an Excel Spreadsheet
# or generate graphs using any one of the Perl graphing modules.
#
#==============================================================================

use strict;
use AnyDBM_File;
use Fcntl;

die "Usage: $0 <database>\n" unless @ARGV == 1;

my $maxentries=10;               # Maximum number of entries to display

my $Database=shift;
my $values;
my $labels;
my %db;

die "Database: $Database does not exist\n" if (! -f "$Database" and ! -f "$Database.dir");

tie(%db,'AnyDBM_File',$Database,O_RDWR,0600) or die "Can not open $Database $!\n";;

my $count=1;

foreach my $key  (sort { $db{$b} <=> $db{$a} } keys %db) {
        last if ($count > $maxentries);
	print "$key,$db{$key}\n";
        $count++;
}

untie %db;
