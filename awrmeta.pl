#!/usr/bin/perl -w
my $vers='1.0';
###############################################################################
#                                                                             #
#   Module: awrmeta.pl                                                        #
#  Purpose: Reports the contents of a awrcsv.pl metadata file.                #
#                                                                             #
# awrmeta.pl -m metadata -S file_suffix -d                                    #
#                                                                             #
#      -h         : Display help (this text)                                  #
#                                                                             #
#  Examples:                                                                  #
#                                                                             #
#                                                                             #
# Author              Date        Modification                                #
# ==================  ==========  ==========================================  #
# cbostock            06.09.2010  First cut.                                  #
#                                                                             #
###############################################################################
use strict;
use Switch;
use warnings;
use File::Basename;
use Getopt::Std;
my $awr_dir       = ".";
my $meta_dir      = "awrcsv_meta";   # Root of the metadata directory structure
my $meta_sub      = ".";             # Metadata location for a specific AWR / STATSPACK file
my $awr_prefix   = "awr";
my $awr_suffix   = "txt";
my (
    $meta_file, @dirs, $dir
  , $record 
  , %version_list, $version_num
  );
my $prog     = basename($0);
my $dirname = '.';
my $logfile = 'awrmeta.log';
my $is_rac = 'no';
my $pattern_match = '^.*';

sub print_meta_rec 
{
	my ($meta_file, $meta_rec) = (@_);

    my ($label_heading , $orig_title_heading, $title_heading, $start_str, $end_str  
     , $match_pattern, $label_start_pos, $label_len, $sep_count
     , $data_start_pos , $data_len, $shift_lines, $pop_lines);

                                       #**************************************/
                                       #*  $csv_file is built based on       */
                                       #* $base_csv_file. $csv_file is       */
                                       #* modified to include the Instance   */
                                       #* Name as a prefix.                  */
                                       #**************************************/
    my $csv_file;
    my $base_csv_file;


    $title_heading  = $meta_rec;
    $label_heading  = $meta_rec;
	my $field_sep = ':';

	while( $meta_rec =~ /$field_sep/g){++$sep_count};

	$sep_count = $sep_count + 1;
	if ($sep_count != 12)
	{
		prn_log ("$prog: Invalid metadata record found in \"$meta_file\"\n");
		prn_log ("Incorrect field count of $sep_count (should be 12) for metadata record:\n\n");
		prn_log ("$meta_rec\n");
   	    prn_log ("$prog: Deploying chute and bailing out!\n");
		exit 1;
	}

	my $field_start_pos = 0;
	my $field_end_pos   = 0;
	my $orig_label_heading;

    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$title_heading =~ s/:.*//;
	chomp($title_heading);
	$orig_title_heading     = $title_heading;

    $field_start_pos  = index($meta_rec, $field_sep) + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$orig_label_heading = $label_heading = trim(substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos));

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$csv_file         = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos); 

	$base_csv_file = $csv_file;
	$base_csv_file = $base_csv_file . '.csv';

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$start_str        = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$end_str          = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$match_pattern    = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$label_start_pos  = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
	if ($label_start_pos !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid metadata record found in \"$meta_file\"\n");
		prn_log ("The \"label start position\" field (field 7) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$label_start_pos\"\n");
   	    prn_log ("$prog: Deploying chute and bailing out!\n");
		exit 1;
	}


	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$label_len        = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
	if ($label_len !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid metadata record found in \"$meta_file\"\n");
		prn_log ("The \"label length\" field (field 8) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$label_len\"\n");
   	    prn_log ("$prog: Deploying chute and bailing out!\n");
		exit 1;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$data_start_pos   = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);

	if ($data_start_pos !~ m/(^[\d]+$|^S[\d]+-[\d]+$|^[\d]+-[\W\D][\d]+$|^S[\d]+-[\d]-+[\W\D][\d]+$)/)
	{
		prn_log ("$prog: Invalid metadata record found in \"$meta_file\"\n");
		prn_log ("The \"data start position\" field (field 9) is in an invalid format for record:\n\n");
		prn_log ("$meta_rec\n\n");
   	    prn_log ("\nValid formats are either a positive integer or:\n"); 
   	    prn_log ("\nSN-M\"\n");
   	    prn_log ("\nSN-M-DX\"\n");
   	    prn_log ("\nM-DX\"\n");
   	    prn_log ("where N, M and X are positive integers and C is a non-digit, non-alphabetic character.\n");
   	    prn_log ("See the MTA File README.txt for more detail.\n");
   	    prn_log ("$prog: Deploying chute and bailing out!\n");
		exit 1;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$data_len         = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
	if ($data_len !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid metadata record found in \"$meta_file\"\n");
		prn_log ("The \"data length\" field (field 10) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$data_len\"\n");
   	    prn_log ("$prog: Deploying chute and bailing out!\n");
		exit 1;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$shift_lines      = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
	if ($shift_lines !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid metadata record found in \"$meta_file\"\n");
		prn_log ("The \"shift lines\" field (field 11) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$shift_lines\"\n");
  	    prn_log ("$prog: Deploying chute and bailing out!\n");
		exit 1;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$pop_lines        = substr($meta_rec,$field_start_pos);
	if ($pop_lines !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid metadata record found in \"$meta_file\"\n");
		prn_log ("The \"pop lines\" field (field 12) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n\n");
		prn_log ("Value found: \"$pop_lines\"\n");
   	    prn_log ("$prog: Deploying chute and bailing out!\n");
		exit 1;
	}
	

	my $divider = sprintf("%s", '=' x 80);
 	prn_log ("$divider\n");
 	prn_log ("Metadata parameters retrieved for $meta_file:\n\n");
	prn_log ("           Title Heading : $title_heading\n");
	prn_log ("           Label Heading : $label_heading\n");
	prn_log ("           Base CSV File : $csv_file\n");
	prn_log ("     Start search string : $start_str\n");
	prn_log ("       End search string : $end_str\n");
	prn_log ("Match pattern (optional) : $match_pattern\n");
	prn_log ("    Label start position : $label_start_pos\n");
	prn_log ("            Label length : $label_len\n\n");
	prn_log ("     Data start position : $data_start_pos\n");
	prn_log ("             Data length : $data_len\n\n");

	prn_log ("             Shift count : $shift_lines\n");
	prn_log ("               Pop count : $pop_lines\n");

}

#******************************************************************************/
#* Perl trim function to remove whitespace from the start and end of the      */
#* string                                                                     */
#******************************************************************************/
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

#******************************************************************************/
#* Function: ltrim to trim white space from left of a string                  */
#******************************************************************************/
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
#******************************************************************************/
#* # Right trim function to remove trailing whitespace                        */
#******************************************************************************/
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}


#******************************************************************************/
#* Produce a date / time stamp                                                */
#******************************************************************************/
sub date_time_stamp
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900; ## $year contains no. of years since 1900, to add 1900 to make Y2K compliant
  $mday = sprintf("%02d",$mday);
  $hour = sprintf("%02d",$hour);
  $min  = sprintf("%02d",$min);
  $sec  = sprintf("%02d",$sec);

  my @month_abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
  my @day_abbr = qw( Sun Mon Tue Wed Thu Fri Sat );
  my $fmt_datetime = "$day_abbr[$wday] $month_abbr[$mon] $mday $hour:$min:$sec $year";
  return $fmt_datetime;
}

#******************************************************************************/
#* Print a line to the log                                                    */
#******************************************************************************/
sub prn_log
{
   my @log_line = @_;
   printf LOG ("%s", @log_line);
   printf ("%s", @log_line);
}
#******************************************************************************/
#* Print a line to the log                                                    */
#******************************************************************************/
sub prn_log_divider
{
    printf LOG ("%s\n", "=" x 80);
}
#******************************************************************************/
#* Print a timestamp prefixed line to the log                                 */
#******************************************************************************/
sub prn_log_ts
{
   my @log_line = @_;
   my $dts = date_time_stamp;
   printf LOG ("%s: %s\n", $dts, @log_line);
}

#******************************************************************************/
#* INITIAL Processing section - process arguments                             */
#******************************************************************************/
sub disp_usage()
{
  print  "Usage $prog { -f meta_file -v rdbms_ver} [ -m meta_dir  -p regexp -r ] | [ -h ]\n\n";
  print " -h           : Display help (this text)\n\n";
  print " -f meta_file : Report based on the specified metadata file.\n";
  print " -v rdbms_ver : RDBMS version for the specified metadata.\n";
  print " -m meta_dir  : Directory where awrcsv metadata is to be found\n\n";
  print " -p pattern   : Match the metadata record which matches this regexp pattern.\n";
  print " -r           : Metadata is RAC specific (contained in the \"rac_yes\" sub-directory.\n";
  print "NOTES: The meta_dir defaults to awrcsv_meta in the current working directory.\n";
  print "       If the \"-r\" option is omitted, single instance Oracle is assumed.\n";
  print "       That is to say the rac_no sub-directory is assumed to be the location of the.\n";
  print "       metadata file specified.\n";
}

getopts('f:hm:p:v:') or 
    die "\n$prog : Invalid options specified, use $prog -h. Deploying chute and bailing out!!!\n";
our (
    	 $opt_h
    	,$opt_f
    	,$opt_m
    	,$opt_p
    	,$opt_r
    	,$opt_v
	);

if(defined($opt_h))
{
  disp_usage();
  exit;
}

if(defined($opt_f))
{
  $meta_file = $opt_f;
}

if(defined($opt_m))
{
  $meta_dir=$opt_m;
}


if(defined($opt_p))
{
  $pattern_match=$opt_p;
}

if(defined($opt_r))
{
  $is_rac='yes';
}

if(defined($opt_v))
{
  $version_num=$opt_v;
}

if(! defined($opt_f) || ! defined($opt_v))
{

	print("\n$prog: You must at least specify a metadata file (-f) and RDBMS version of the metadata file\n");
	disp_usage;
	exit(1);
}
my $SD="\/";
my $SP=":";
my $os = $ENV{'OS'}; 
if ( ! $os )
  { $os = $ENV{'OSTYPE'}; }
if ( ! $os )
  { 
     $os = `uname`;
     chomp $os;  
  }
if ( ! $os )
  { 
     $os = 'Unknown';
  }

$SD="\\" if($os  =~ /Win/i);
$SP=";" if($os   =~ /Win/i);

#******************************************************************************/
#* LOAD the AWR / STATSPACK reports into array structures.                    */
#******************************************************************************/
  my $ref_awr;
# printf "Changing working directory to $awr_dir\n";
# chdir $awr_dir or die "$prog: Cannot change to specfied directory (-d $awr_dir)\n";

  open(LOG, "> $logfile") or die "$prog: FATAL ERROR: Cannot write to file \"$logfile\"\n";
  prn_log_ts("$prog: Started\n");
  opendir(AWR,$awr_dir);
  my @awr_file_names = readdir(AWR);
  closedir(AWR);


  $meta_sub = $meta_dir . $SD . $version_num;
  if ( ! -d $meta_sub )
    { prn_log("Invalid metedata version: $version_num\n");
	  prn_log("Supplementary information: No \"" . $meta_dir . $SD . $version_num . "\"");
	  prn_log(" directory found\n");
		         
	  exit(1);
    }
                                       #**************************************/
                                       #*  Now refine the metadata location  */
                                       #* based on RAC: YES or NO            */
                                       #**************************************/
  if ( $is_rac eq "yes" )
  {
    if (-d $meta_sub . $SD . "rac_yes" )
  	{
		$meta_sub = $meta_sub . $SD . "rac_yes";
  	}
  	else
  	{
	  	prn_log "$prog: Cannot locate RAC meta data in \"$meta_sub\"\n";
	  	exit(1);
  	}
  }

  if ( $is_rac eq "no" )
  {
    if (-d $meta_sub . $SD . "rac_no" )
  	{
		$meta_sub = "$meta_sub" . "$SD" . "rac_no";
  	}
  	else
  	{
	  	prn_log "$prog: Cannot locate single instance meta data in \"$meta_sub\"\n";
	  	exit(1);
  	}
  }
	$meta_sub = sprintf("%s", $meta_sub);


	prn_log("Opening ". $meta_sub. $SD . $meta_file . "\n" );
    open(MTA, $meta_sub. $SD . $meta_file) || 
	    die "$prog: Can't open metadata file: $meta_sub$SD$meta_file\n";
    my @meta_recs = <MTA>;
	close (MTA);


	foreach $record (@meta_recs)
	{

	  if ( $record !~ m/^# / )
	  {
		if ( $record =~ m/$pattern_match/ )
			{
			   print_meta_rec($meta_file, $record); 
	  		}
	  }
	}
  my $divider = sprintf("%s", '=' x 80);
  prn_log ("$divider\n");
  prn_log_ts("$prog: Done\n");
  close (LOG);
