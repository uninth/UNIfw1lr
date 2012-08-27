#!/usr/bin/perl 
#==============================================================================
#
# NAME:         fwlogsum.cgi
#
# AUTHOR:       Peter Sundstrom (peter@ginini.com)
#		(c) 1999-2003
#
# PURPOSE:      A CGI form to generate the appropriate flags to use with
#		fwlogsum.  
# 
# SOURCE:	http://www.ginini.com/software/fwlogsum/
#
#==============================================================================


use strict;
use CGI;

my $fwlogsumver='5.0.0';

my $query = new CGI;
my $script = $query->url(-absolute=>1);
my %param = $query->Vars;


if ($param{Output}) {
	ProcessForm();
}
else {
	DisplayForm();
}

#------------------------------------------------------------
sub ProcessForm {
	my $flags;

	if ($param{flagtype} eq 'short') {
	$flags = '-rx' if ($param{Report} =~ /Dropped and Rejected Entries/);
	$flags = '-ra' if ($param{Report} =~ /Accepted Entries/);
	$flags = '-rd' if ($param{Report} =~ /Dropped Entries/);
	$flags = '-rt' if ($param{Report} =~ /Attack Entries/);

	$flags .= ' -c 80' if ($param{Output} eq '80 Column Output');
	$flags .= ' -c 132' if ($param{Output} eq '132 Column Output');
	$flags .= ' -w' if ($param{Output} eq 'HTML Output');

	$flags .= ' -S' if ($param{Mode} eq 'Summary only');

	$flags .= ' -sa' if ($param{Sort} eq 'By Attack Type');
	$flags .= ' -sc' if ($param{Sort} eq 'By Count');
	$flags .= ' -ss' if ($param{Sort} eq 'By Source Address');
	$flags .= ' -sd' if ($param{Sort} eq 'By Destination Address');
	$flags .= ' -sv' if ($param{Sort} eq 'By Service');
	$flags .= ' -sf' if ($param{Sort} eq 'By Firewall Host');
	$flags .= ' -sr' if ($param{Sort} eq 'By Rule Number');

	$flags .= ' -bo' if ($param{Traffic} eq 'Outbound Traffic');
	$flags .= ' -bi' if ($param{Traffic} eq 'Inbound Traffic');

	$flags .= ' -A' if ($param{AttackInfo} eq 'on');
	$flags .= ' -p' if ($param{SourcePort} eq 'on');
	$flags .= " -xb" if ($param{XlateBoth} eq 'on');
	$flags .= " -xt" if ($param{XlateSingle} eq 'on');
	$flags .= " -v" if ($param{Verbose} eq 'on');
	$flags .= " -T" if ($param{Time} eq 'on');
	$flags .= " -R" if ($param{Resolve} eq 'on');
	$flags .= " -q" if ($param{PostResolve} eq 'on');
	$flags .= " -C" if ($param{CacheDNS} eq 'on');
	$flags .= " -D" if ($param{Domain} eq 'on');
	$flags .= " -y" if ($param{ConvertPnum} eq 'on');
	$flags .= " -Y" if ($param{ConvertPname} eq 'on');

	$flags .= " -d $param{DelimiterChar}" if ($param{Delimiter} eq 'on');
	$flags .= " -g $param{RestrictNum}" if ($param{Restrict} eq 'on');
	$flags .= " -P $param{SummaryNum}" if ($param{Summary} eq 'on');

	$flags .= qq( -a "$param{AlertText}") if ($param{Alert} eq 'on');
	$flags .= qq( -m $param{MailUser}) if ($param{Mail} eq 'on');
	$flags .= qq( -H $param{HeaderTitle}) if ($param{Header} eq 'on');

	$flags .= qq( -e "$param{ExcludeServices}") if ($param{Exclude} eq 'on');
	$flags .= qq( -f "$param{SExcludeServices}") if ($param{SExclude} eq 'on');
	$flags .= qq( -n "$param{ExcludeIFname}") if ($param{ExcludeIF} eq 'on');

	$flags .= qq( -i "$param{IgnoreEntries}") if ($param{Ignore} eq 'on');

	$flags .= qq( -t "$param{IncludeEntries}") if ($param{Include} eq 'on');

	$flags .= " -l $param{LogFileName}" if ($param{LogFile} eq 'on');
	$flags .= " -L $param{FW1LogName}" if ($param{FW1LogFile} eq 'on');
	$flags .= " -l $param{ZLogFileName}" if ($param{ZLogFile} eq 'on');
	$flags .= " -B $param{TrendDir}" if ($param{Trend} eq 'on');
	$flags .= " -o $param{OutputFile}" if ($param{Outputfile} eq 'on');
	}
	else {
	$flags = '--rptdropsrejects' if ($param{Report} =~ /Dropped and Rejected Entries/);
	$flags = '--rptattacks' if ($param{Report} =~ /Attacks/);
	$flags = '--rptaccepts' if ($param{Report} =~ /Accepted Entries/);
	$flags = '--rptdrops' if ($param{Report} =~ /Dropped Entries/);

	$flags .= ' --width 80' if ($param{Output} eq '80 Column Output');
	$flags .= ' --width 132' if ($param{Output} eq '132 Column Output');
	$flags .= ' --html' if ($param{Output} eq 'HTML Output');

	$flags .= ' --summary' if ($param{Mode} eq 'Summary only');

	$flags .= ' --sortattack' if ($param{Sort} eq 'By Attack Type');
	$flags .= ' --sortcount' if ($param{Sort} eq 'By Count');
	$flags .= ' --sortsrc' if ($param{Sort} eq 'By Source Address');
	$flags .= ' --sortdest' if ($param{Sort} eq 'By Destination Address');
	$flags .= ' --sortsvc' if ($param{Sort} eq 'By Service');
	$flags .= ' --sortfw' if ($param{Sort} eq 'By Firewall Host');
	$flags .= ' --sortrule' if ($param{Sort} eq 'By Rule Number');

	$flags .= ' --outbound' if ($param{Traffic} eq 'Outbound Traffic');
	$flags .= ' --inbound' if ($param{Traffic} eq 'Inbound Traffic');

	$flags .= ' --attackinfo' if ($param{AttackInfo} eq 'on');
	$flags .= ' --incsrcport' if ($param{SourcePort} eq 'on');
	$flags .= " --xlateboth" if ($param{XlateBoth} eq 'on');
	$flags .= " --xlate" if ($param{XlateSingle} eq 'on');
	$flags .= " --verbose" if ($param{Verbose} eq 'on');
	$flags .= " --time24" if ($param{Time} eq 'on');
	$flags .= " --resolveip" if ($param{Resolve} eq 'on');
	$flags .= " --postresolveip" if ($param{PostResolve} eq 'on');
	$flags .= " --cachedns" if ($param{CacheDNS} eq 'on');
	$flags .= " --incdomain" if ($param{Domain} eq 'on');
	$flags .= " --svcport" if ($param{ConvertPname} eq 'on');
	$flags .= " --svcname" if ($param{ConvertPnum} eq 'on');

	$flags .= " --delimiter $param{DelimiterChar}" if ($param{Delimiter} eq 'on');
	$flags .= " --restrictcount $param{RestrictNum}" if ($param{Restrict} eq 'on');
	$flags .= " --summaries $param{SummaryNum}" if ($param{Summary} eq 'on');

	$flags .= qq( --highlight "$param{AlertText}") if ($param{Alert} eq 'on');
	$flags .= qq( --mail $param{MailUser}) if ($param{Mail} eq 'on');
	$flags .= qq( --header $param{HeaderTitle}) if ($param{Header} eq 'on');

	$flags .= qq( --excludesvc "$param{ExcludeServices}") if ($param{Exclude} eq 'on');
	$flags .= qq( --excludesrcsvc "$param{SExcludeServices}") if ($param{SExclude} eq 'on');
	$flags .= qq( --excludeif "$param{ExcludeIFname}") if ($param{ExcludeIF} eq 'on');

	$flags .= qq( --ignore "$param{IgnoreEntries}") if ($param{Ignore} eq 'on');

	$flags .= qq( --includeonly "$param{IncludeEntries}") if ($param{Include} eq 'on');

	$flags .= qq( --fw1log $param{LogFileName}) if ($param{LogFile} eq 'on');
	$flags .= qq( --logexport $param{FW1LogName}) if ($param{FW1LogFile} eq 'on');
	$flags .= qq( --fw1log $param{ZLogFileName}) if ($param{ZLogFile} eq 'on');
	$flags .= qq( --trenddir $param{TrendDir}) if ($param{Trend} eq 'on');
	$flags .= qq( --output $param{OutputFile}) if ($param{Outputfile} eq 'on');
	}

	Header();
	print "<h1>fwlogsum $flags</h1>\n";
	print "<i>These flags are correct for fwlogsum Version: $fwlogsumver</i><br>\n";
	print "Note: You may not need all of these flags depending on what defaults you have set<BR>\n";

	print qq(<p><a href="$script">Return to Form</a>\n);
}

#------------------------------------------------------------
sub DisplayForm {


	Header();

	print <<FORM;
<body bgcolor="#ffffff">

<div align="center">
<form method="post" action="$script">

<table class="formtable" cellspacing="5">

<tr>
<td align="center" colspan="2"><h1>Automated Flag Generator</h1>For fwlogsum version: $fwlogsumver<br><hr size="1"></td>
</tr>

<tr>
<td><a href="#type">Report Type</a>:</td>

<td><select name="Report" class="formtable">
<option>Dropped and Rejected Entries
<option>Attack Entries
<option>Accepted Entries
<option>Dropped Entries
<option>Rejected Entries
</select></td>
</tr>

<tr>
<td><a href="#output">Report Output</a>:</td>
<td><select name="Output" class="formtable">
<option>HTML Output
<option>80 Column Output
<option>132 Column Output
</select></td>
</tr>

<tr>
<td><a href="#mode">Report Mode</a>:</td>
<td><select name="Mode" class="formtable">
<option>Details and Summary
<option>Summary only
</select></td>
</tr>

<tr>
<td><a href="#sort">Sort Mode</a>:</td>
<td><select name="Sort" class="formtable">
<option>By Count
<option>By Attack Type
<option>By Source Address
<option>By Destination Address
<option>By Service
<option>By Firewall Host
<option>By Rule Number
</select></td>
</tr>

<tr>
<td><a href="#report">Report on</a>:</td>
<td><select name="Traffic" class="formtable">
<option>All Traffic
<option>Inbound Traffic
<option>Outbound Traffic
</select></td>
</tr>

<tr>
<td><input type=checkbox name="AttackInfo"> <a href="#attackinfo">Display Attack information in Report</a></td>
</tr>

<tr>
<td><input type=checkbox name="SourcePort"> <a href="#sourceport">Include Source Port in Report</a></td>
</tr>

<tr>
<td><input type=checkbox name="Resolve"> <a href="#resolve">Resolve IP Addresses (before filtering)</a></td>
</tr>

<tr>
<td><input type=checkbox name="PostResolve"> <a href="#postresolve">Post Resolve IP Addresses (after filtering)</a></td>
</tr>

<tr>
<td><input type=checkbox name="CacheDNS"> <a href="#cachedns">Cache DNS entries</a></td>
</tr>

<tr>
<td><input type=checkbox name="ConvertPnum"> <a href="#convertpnum">Convert Port Numbers to Names</a></td>
</tr>

<tr>
<td><input type=checkbox name="ConvertPname"> <a href="#convertpname">Convert Port Names to Numbers</a></td>
</tr>

<tr>
<td><input type=checkbox name="Domain"> <a href="#domain">Include Domain Summary in Report</a></td>
</tr>

<tr>
<td><input type=checkbox name="Time"> <a href="#time">Display Time Summary as 24 hour clock</a></td>
</tr>

<tr>
<td><input type=checkbox name="XlateBoth"> <a href="#translate">Report both normal address/port and translated address/port</a></td>
</tr>

<tr>
<td><input type=checkbox name="XlateSingle"> <a href="#translate">Report just the translated address/port</a></td>
</tr>

<tr>
<td><input type=checkbox name="Verbose"> <a href="#verbose">Verbose Output</a></td>
</tr>

<tr>
<td><input type=checkbox name="Delimiter"> <a href="#delimiter">Delimiter character for logexport</a></td>
<td><input type=text name="DelimiterChar" size=1>
</tr>

<tr>
<td><input type=checkbox name="Header"> <a href="#header">Report Header Title</a></td>
<td><input type=text name="HeaderTitle" size=30>
</tr>

<tr>
<td><input type=checkbox name="Outputfile"> <a href="#outputfile">Output file for report</a></td>
<td><input type=text name="OutputFile" size=30>
</tr>

<tr>
<td><input type=checkbox name="Mail"> <a href="#mail">Mail output to specified user</a></td>
<td><input type=text name="MailUser" size=30>
</tr>

<tr>
<td><input type=checkbox name="Alert"> <a href="#alert">Matched Highlights</a></td>
<td><input type=text name="AlertText" size=30>
</tr>

<tr>
<td><input type=checkbox name="Exclude"> <a href="#exclude">Exclude specified services from report</a></td>
<td><input type=text name="ExcludeServices" size=30>
</tr>

<tr>
<td><input type=checkbox name="SExclude"> <a href="#sexclude">Exclude specified source services from report</a></td>
<td><input type=text name="SExcludeServices" size=30>
</tr>

<tr>
<td><input type=checkbox name="ExcludeIF"> <a href="#excludeif">Exclude specified FW interfaces from report</a></td>
<td><input type=text name="ExcludeIFname" size=30>
</tr>

<tr>
<td><input type=checkbox name="Ignore"> <a href="#ignore">Ignore specified entries</a></td>
<td><input type=text name="IgnoreEntries" size=30>
</tr>

<tr>
<td><input type=checkbox name="Restrict"> <a href="#restrict">Restrict entries with count less than</a></td>
<td><input type=text name="RestrictNum" size=3>
</tr>
<tr>

<tr>
<td><input type=checkbox name="Summary"> <a href="#summary">Maximum number of entries to appear in the summaries</a></td>
<td><input type=text name="SummaryNum" size=3>
</tr>
<tr>

<td><input type=checkbox name="Include"> <a href="#include">Include only specified entries</a></td>
<td><input type=text name="IncludeEntries" size=30>
</tr>

<tr>
<td><input type=checkbox name="LogFile"> <a href="#logfile">Run report against specified logexport log file</a></td>
<td><input type=text name="LogFileName" size=30>
</tr>

<tr>
<td><input type=checkbox name="FW1LogFile"> <a href="#fw1logfile">Run report against specified FW1 log file</a></td>
<td><input type=text name="FW1LogName" size=30>
</tr>

<tr>
<td><input type=checkbox name="Trend"> <a href="#trend">Create trend databases in specified directory</a></td>
<td><input type=text name="TrendDir" size=30>
</tr>



<tr>
<td>Display command with
<input type="radio" name="flagtype" value=short checked>Short flags
<input type="radio" name="flagtype" value=long>Long flags
</td>
</tr>

<tr>
<td>
<input type="submit" value="Generate" class="button">
<input type="reset" value="Reset" class="button">
</td>
</tr>

</table>
</form>

</div>

<p>
<hr>
<p>
<h1>Form Help</h1>
<a name=type><h2>Report Type</h2></a>
There are four different types of reports:<br>
<ol>
<li>Dropped and Rejected Entries.<br>
<li>Attack Entries.<br>
<li>Accepted Entries.<br>
<li>Dropped Entries.<br>
<li>Rejected Entries.<br>
</ol>

<p>

<a name=output><h2>Output Format</h2></a>
There are three different types of output formats:<br>
<ol>
<li>HTML<br>
<li>80 Columns - ASCII <br>
<li>132 Columns - ASCII <br>
</ol>

<p>

<a name=mode><h2>Report Mode</h2></a>
There are two different types of report modes:<br>
<ol>
<li>Details and Summary - Details of all packets are reported<br>
<li>Summary Only - Only the summaries are reported<br>
</ol>

<p>

<a name=sort><h2>Sort Types</h2></a>
There are six different types of sorting:<br>
<ol>
<li>Count - Sort by number of occurances.<br>
<li>Attack Type.<br>
<li>Source Address - Only useful if source address is selected.<br>
<li>Destination Address.<br>
<li>Service - Service name.<br>
<li>Firewall Host - Firewall-1 host the logging orginated from.<br>
<li>Rule Number - Useful in accept reports for seeing which rules are triggered the most.<br>
</ol>

<p>

<a name=report><h2>Report On</h2></a>
There are three different way to report on:
<ol>
<li>All packets - Report on all packets for the report type.<br>
<li>Inbound Traffic - Report on inbound traffic only.<br>
<li>Outbound Traffic - Report on outbound traffic only.<br>
</ol>

<p>

<a name=resolve><h2>Resolve IP Addresses</h2></a>
If you have a slow naming service, you can let <b>fwlogsum</b> resolve IP
addresses for you.  As it only needs to resolve entries that appear in the
report, it should be substantially quicker.<br>
<p>

<a name=postresolve><h2>Post Resolve IP Addresses</h2></a>
This option is similar to the above option, except that the resolution
of IP addresses is done after filtering has been performed.  This can
signficantly speed up report generation as only the reported entries 
need to be resolved.  The down side is that any filtering will need
to be done using IP addresses.

<p>

<a name=cachedns><h2>Cache DNS Entries</h2></a>
This option caches DNS entries to a DBM file.  It can significantly
speed up report generation if you are resolving IP addresses.<br>
<p>

<a name=convertpnum><h2>Convert Port Numbers to Name</h2></a>
This option will attempt to convert any port numbers to their corresponding
service description. 
<p>

<a name=convertpname><h2>Convert Port Names to Number</h2></a>
This option will attempt to convert any port descriptions to their corresponding
port number.
<p>

<a name=domain><h2>Include Domain Summaries in Report</h2></a>
You can define local and common domains to be displayed in a Domain summary.<br>
<p>

<a name=time><h2>Display Time Summary as 24 hour clock</h2></a>
By default the summary will show the top time periods in descending order of
greatest use.  Selecting this option will display the 24 time period in
time order.<br>
<p>

<a name=verbose><h2>Version Output</h2></a>
This option is will display informational messages about the processing of
the log.  The output is displayed on stderr.<br>
<p>

<a name=translate><h2>Address/Port Translation</h2></a>
If you have translated addresses and/or ports, using these options will either show just the translated address/port or both the untranslated and translated address/port, for example:<p>
<code>outside.domain.com/inside.domain.com</code>
<p>

<a name=delimiter><h2>Delimiter character for logexport</h2></a>
By default, <b>fw logexport</b> uses the <b>;</b> character as the field
delimiter.  You can set the delimiter to something else if you generate
logexport logs with a different delimiter.<br>
<p>


<a name=sourceport><h2>Source Port</h2></a>
By default, <code>fwlogsum</code> does not include the source port in the 
report as this is generally not useful, as most of these will be random high  
ports, eg:  the remote site connecting to your web server on port 80 will have a
random source port.<br>
However, it can be useful for checking things such as <b>ftp</b> and
<b>domain</b> requests.
<p>

<a name=header><h2>Report Header</h2></a>
This option overides the default report header title.
<p>

<a name=outputfile><h2>Output File for Report</h2></a>
Name of the output file for the report.  If this is left off, the report goes to STDOUT.
<p>

<a name=mail><h2>Mail Output</h2></a>
Mail the contents of the report to the specified address/es.
<p>

<a name=alert><h2>Matched Highlight</h2></a>
This option can be used to highlight particular entries of interest in the HTML
report.  For example, you may want to take particular notice to any <b>telnet</b> attempts.
<p>

<a name=exclude><h2>Exclude Specified Services</h2></a>
Some services are not always useful to report on, especially when reporting
on accepted packets.  Things like http, smtp, icmp etc.  Excluding these 
services can drastically reduce the size of the report.<br>
If you are running a dropped report, then excluding auth packets will save 
a lot of space.
<p>

<a name=sexclude><h2>Exclude Specified Source Services</h2></a>
This option is the same as above, but useful when you have selected to include
source services in the report.
<p>

<a name=excludeif><h2>Exclude Specified FW Interfaces</h2></a>
This option allows you to exclude an FW interface from the report. The interface name is
the same as it is known by FW1, eg: hme0, qfe0, etc.
<p>

<a name=ignore><h2>Ignore Specified Entries</h2></a>
This allows you to ignore entries based on a perl regular expression.  For
example you may wish to ignore all entries from microsoft.com and netscape.com
using the expression: <code>microsoft\.com|netscape\.com</code>
<p>

<a name=restrict><h2>Restrict Entries less than specified Count</h2></a>
This option allows you to reduce the size of you report by only reporting the
detail of entries greater than the specified count.  There will be many entries
that occur less then 10 times.  By restricting these, your report will be of a
more managable size.  The report summaries will not be effected.
<p>

<a name=summary><h2>Maximum Number of entries to appear in the summaries</h2></a>
This option allows you to set how many entries you want to see in the summary reports.
<p>


<a name=include><h2>Include Specified Entries</h2></a>
Works the same as ignore entries but allows you to specify specific entries to
include.
<p>

<a name=logfile><h2>Run Report Against Specified ASCII Log File</h2></a>
This option is useful if you want to run multiple views of the same data, by
first generating the log file with the <code>fw logexport >logfile</code> command
and then generating various reports with <b>fwlogsum</b>.
<p>

<a name=fw1logfile><h2>Run Report Against Specified FW1 Log File</h2></a>
This option allows you to run the report against another fw1 log file.  Compressed or uncompressed.
<p>

<a name=trend><h2>Create trend databases in specified directory</h2></a>
This option will write a dbm file in the specified directory for every summary type.
<p>
 
</body>
</html>

FORM
;
}

#------------------------------------------------------------
sub Header {
	print $query->header;

	print <<TEXT;
<html>
<head>
<title>fwlogsum Flag Generator</title>

<style type="text/css">

BODY {	font-family: arial,helvetica,sans-serif; 
	font-size: 12px;
	margin-left: 50px
}

H1 { font-size: 20px }
H2 { font-size: 15px }
HR { color: black}

.formtable { font-size: 12px;
	     background-color: #bdc8e9;
	     border: 1px solid black;

}

.button { font-family: Arial, sans-serif;
 	  font-weight: bold;
 	  font-size: 12px;
 	  border-style: beveled;
 	  border-width: 3;
 	  cursor: pointer;
}
</style>

</head>

<body bgcolor="#ffffff">
TEXT
}

