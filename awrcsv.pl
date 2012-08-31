#!/usr/bin/perl -w
my $vers='1.14';
###############################################################################
#                                                                             #
#   Module: awrcsv.pl                                                         #
#  Purpose: Generate CSV files from a collection of AWR / STATSPACK reports.  #
#           The tool bases its output on the contents of meta-data files      #
#           which are used to define how to extract contents based on RDBMS   #
#           version and / or whether the reports are for RAC or single        #
#           instance.                                                         #
#                                                                             #
# Usage: Type awrcsv.pl -h for a full help listing.                           #
#                                                                             #
# Author              Date        Modification                                #
# ==================  ==========  ==========================================  #
# cbostock            28.04.2011  First cut.                                  #
# cbostock            05.05.2011  Include meta-data categories to allow       #
#                                 selection of what CSV files should be       #
#                                 generated based on contents of              #
#                                 Categories.mta located in the root meta-    #
#                                 data directory.                             #
# cbostock            09.05.2011  Include copy of log to CSV target folder    #
#                                 if target is not current folder.            #
# cbostock            13.05.2011  Fixed the subfield function.                #
# cbostock            15.06.2011  Fixed the -c option. Prefix getting lost.   #
# cbostock            21.06.2011  Include the -M (meta_file) option.          #
# cbostock            23.06.2011  Included descending sort of output records. #
#                                 These are now written in descnding order    #
#                                 of the sum of the values.                   #
# cbostock            06.07.2011  Include trap to skip AWR files containing   #
#                                 Oracle errors (ORA-). Also includes a -I    #
#                                 flag to ignore errors if required.          #
# cbostock            05.11.2011  Improve suspicious record reporting.        #
# cbostock            14.11.2011  Include extended data label processing      #
#                                 for SN-M type dat position entries.         #
# cbostock            18.11.2011  Improve field validation by trapping non-   #
#                                 numerics in sum-fields function. Also       #
#                                 improvements with -f validation.            #
# cbostock            18.11.2011  Improved output produced with -t option     #
#                                 and fixed the category restriction bug      #
#                                 affecting -t & M flags when default         #
#                                 category of 9 was introduced.               #
# cbostock            18.12.2011  Include the option to map fields by field   #
#                                 number rather than start column and length. #
#                                 Specifying the data length field (field 8)  #
#                                 as an empty string, we assume that the      #
#                                 starting position field is actually the     #
#                                 field number (1st field starts at 1).       #
#                                                                             #
# cbostock            19.01.2012  Replaced the use of switch with given/when. #
# cbostock            15.08.2012  Improve AWR parse error reporting.          #
#                                                                             #
###############################################################################
use strict;
use 5.010;
use warnings;
use File::Basename;
use Getopt::Std;
use File::Copy;

my $awr_dir       = ".";
my $out_dir       = ".";
my $meta_dir      = "awrcsv_meta";   # Root of the meta-data directory structure
my $meta_sub      = ".";             # Metadata location for a specific AWR / STATSPACK file
my $awr_prefix   = "awr";
my $awr_suffix   = "txt";
my (
	%awr_file, $awr_file, $awr_rec, @awr_file, %awr_sort 
  , $csv_prefix
  , $inst_name, $inst_num, $db_name
  , $is_rac                          # Values "yes" or "no" 
  , $key                             # General purpose hash key
  , %meta_dir, $meta_file, @dirs, $dir
  , $regexp1 , $regexp2
  , $record
  , %version_list, $full_version, $base_version, $version_num,
  , @snap_rec , $snap_id , $snap_dttm , $snap_date , $snap_time , $sort_dttm
  );

my %inst_id        = ();
my %db_versions    = ();
my %inst_nums      = ();
my %csv_files;
my %categories     = ();
my $prog     = basename($0);
my $category = 9;
my $dirname = '.';
my $trap_awr_errors = 1;
my $logfile = 'awrcsv.log';

my $perform_field_valdn = 0;
my $test_meta = "";
my $run_meta = "";
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

sub deploy_chute
{
   	    prn_log ("$prog: Deploying chute and bailing out!\n");
        close (LOG);
        if ( $out_dir ne '.' )
        {
	        copy ('awrcsv.log',$out_dir);
        }
        open(LOG, ">> $logfile") or die "$prog: FATAL ERROR! Cannot write to file \"$logfile\"\n";
        prn_log ("\nINFO: Log \"awrcsv.log\" copied to \"$out_dir\"\n");
        close (LOG);
		exit 1;
}
#******************************************************************************/
#* Function: bi_outer_join which expects two hash references and peforms a    */
#* 2-way outer join on the keys. Returns a hash.                              */
#******************************************************************************/
sub bi_outer_join
{ 
  my ($ra, $rb) = (@_);
  my %a = %$ra;
  my %b = %$rb;
  my %jn;
  my $key;
  my $a_count = 0;
  my $b_count = 0;
                
  foreach $key (keys %a)
    {
	  # Find number of commas
      $a_count = ($a{$key} =~ tr/,//);
	}
  foreach $key (keys %b)
    {
	  # Find number of commas
      $b_count = ($b{$key} =~ tr/,//);
	}
                                       #**************************************/
                                       #*  If there are no entries at all    */
                                       #* in %b then seed all key values     */
                                       #* from %a with ',0'                  */
                                       #**************************************/
  if ($b_count == 0)
  {
  	foreach $key (keys %a)
      {
		  $b{$key} = ',0';
	  }
  }

                                       #**************************************/
                                       #*  If there are no entries at all    */
                                       #* in %a then seed all key values     */
                                       #* from %b with ',0'                  */
                                       #**************************************/
  if ($a_count == 0)
  {
  	foreach $key (keys %b)
      {
		  $a{$key} = ',0';
	  }
  }
                                       #**************************************/
                                       #* The next two blocks of code are    */
                                       #* in case we have some but not all   */
                                       #* keys populated in each %a and 0.   */
                                       #* We therefore need to ensure that   */
                                       #* we have a balanced number of       */
                                       #* fields in each. Hence the reason   */
                                       #* we counted the commas earlier (in  */
                                       #* $a_count and $b_count).            */
                                       #**************************************/
  foreach $key (keys %a)
    {
         if ( ! exists ($b{$key}))
           { 
		    my $i;
		    for ($i=1; $i < $b_count + 1; $i++) 
		      { if ( $i == 1 )
				{ 
					$b{$key} = ',0';
				}
				else
				{ 
					$b{$key} = $b{$key} . ',0';
				}
			  }
		   }
    }

  foreach $key (keys %b)
    {
         if (! exists $a{$key})
           { 
		    my $i;
		    for ($i=1; $i < $a_count + 1; $i++) 
		      { if ( $i == 1 )
				{ $a{$key} = ',0' }
				else
				{ $a{$key} = $a{$key} . ',0' }
			  }
		   }
    }
  
  foreach $key (keys %a)
    {
       $jn{$key} = $a{$key} .  $b{$key};
    }
  return %jn;
}

sub generate_csv 
{
	my ($meta_file, $meta_rec, $full_version) = (@_);

    my ($label_heading , $orig_title_heading, $title_heading, $start_str, $end_str  
     , $match_pattern, $label_start_pos, $label_len, $sep_count
     , $data_start_pos , $data_len, $shift_lines, $pop_lines);
    my $suffix_delim_pos = -1;

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
		prn_log ("$prog: Invalid meta-data record found in \"$meta_file\"\n");
		prn_log ("Incorrect field count of $sep_count (should be 12) for meta-data record:\n\n");
		prn_log ("$meta_rec\n");
		deploy_chute;
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
    if (scalar keys %db_versions > 1)
    {
		$base_csv_file = $csv_file = $csv_file . "(" . $full_version . ")";
	}	
	$base_csv_file = $base_csv_file . '.csv';
	$csv_file = $base_csv_file;

    if (defined($csv_prefix))
		{$csv_file    = $base_csv_file = $csv_prefix . $csv_file} 

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
		prn_log ("$prog: Invalid meta-data record found in \"$meta_file\"\n");
		prn_log ("The \"label start position\" field (field 7) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$label_start_pos\"\n");
		deploy_chute;
	}


	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$label_len        = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
	if ($label_len !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid meta-data record found in \"$meta_file\"\n");
		prn_log ("The \"label length\" field (field 8) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$label_len\"\n");
		deploy_chute;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$data_start_pos   = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
                                       #**************************************/
                                       #* WARNING: Don't meddle with the     */
                                       #* following pattern matching unless  */
                                       #* you are confident about what you   */
                                       #* are doing!                         */
                                       #**************************************/
	if ($data_start_pos !~ m/(^[\d]+$|^S[\d]+-[\d]+$|^[\d]+-[\W\D][\d]+$|^S[\d]+-[\d]-+[\W\D][\d]+$)/)
	{
		prn_log ("$prog: Invalid meta-data record found in \"$meta_file\"\n");
		prn_log ("The \"data start position\" field (field 9) is in an invalid format for record:\n\n");
		prn_log ("$meta_rec\n\n");
   	    prn_log ("\nValid formats are either a positive integer or:\n"); 
   	    prn_log ("\nSN-M\"\n");
   	    prn_log ("\nSN-M-DX\"\n");
   	    prn_log ("\nM-DX\"\n");
   	    prn_log ("where N, M and X are positive integers and C is a non-digit, non-alphabetic character.\n");
   	    prn_log ("See the MTA File README.txt for more detail.\n");
		deploy_chute;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$data_len         = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
	if ($data_len !~ m/[\d#]+/ and $data_len ne '')
	{
		prn_log ("$prog: Invalid meta-data record found in \"$meta_file\"\n");
		prn_log ("The \"data length\" field (field 10) is not a positive integer or an empty string for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$data_len\"\n");
		deploy_chute;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$shift_lines      = substr($meta_rec,$field_start_pos, $field_end_pos - $field_start_pos);
	if ($shift_lines !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid meta-data record found in \"$meta_file\"\n");
		prn_log ("The \"shift lines\" field (field 11) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n");
		prn_log ("Value found: \"$shift_lines\"\n");
		deploy_chute;
	}

	$field_start_pos  = $field_end_pos + 1;
    $field_end_pos    = index($meta_rec, $field_sep, $field_start_pos);
	$pop_lines        = substr($meta_rec,$field_start_pos);
	if ($pop_lines !~ m/[\d]+/)
	{
		prn_log ("$prog: Invalid meta-data record found in \"$meta_file\"\n");
		prn_log ("The \"pop lines\" field (field 12) is not a positive integer for record:\n\n");
		prn_log ("$meta_rec\n\n\n");
		prn_log ("Value found: \"$pop_lines\"\n");
		deploy_chute;
	}
	

    if ($test_meta)
	{
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

	if (length($end_str) <= length($start_str) and index($end_str,$start_str) == 0)
	{
	  prn_log ("\n\nWARNING[1] \"Start search string\" is contained within \"End search string\" - results may be unpredictable!\n");
 	  prn_log ("            Metadata file: $meta_file:\n");
	  prn_log ("     Start search string : $start_str\n");
	  prn_log ("       End search string : $end_str\n\n");
	}
    my $inst_num;
    my $prev_inst_num = 0;

    my $count = 1;
	my @csv           = ();
	my %csv           = ();
	my %prev_csv      = ();

   prn_log_divider();
   if (! $test_meta)
   {
     prn_log ("Processing \"$title_heading / $label_heading\" for $full_version data\n");
   }
   foreach $inst_num (keys %inst_nums)
   {
	@csv           = ();
	%csv           = ();
	%prev_csv      = ();
#	prn_log ("\n<<< Processing instance number $inst_num files >>>\n\n");
	if ($inst_num != $prev_inst_num)
		{
                                       #**************************************/
                                       #* If we are now processing files     */
                                       #* for a different instance we need   */
                                       #* to reset the cell headings and     */
                                       #* contents so that we can write to   */
                                       #* instance specific CSV files        */
                                       #* without polluting the contents     */
                                       #* from the previous instance.        */
                                       #**************************************/
		  $label_heading = trim($orig_label_heading);
                                       #**************************************/
                                       #* Check to see if the label heading  */
                                       #* includes a label suffix to be      */
                                       #* appended to all the labels we      */
                                       #* extract from the AWR files. The    */
                                       #* suffix exists if the label         */
                                       #* heading contains two strings       */
                                       #* separated by a pipe character.     */
                                       #* At this stage we only require the  */
                                       #* main label heading so we remove    */
                                       #* the rest.                          */
                                       #**************************************/
          $suffix_delim_pos = index($label_heading, '|', 0);
          if ($suffix_delim_pos > -1)
          {
	        $label_heading = substr($label_heading,0, $suffix_delim_pos);
          }
		  $title_heading = $orig_title_heading;
		  %prev_csv = %csv = ();
		  $count = 1;
		}
    foreach $awr_file (sort keys %awr_file)
     {
  	  my $awr = $awr_file{$awr_file};
  	  my $ref_awr;
  	  my @awr_file;
  	  my $file_name;
      $prev_inst_num = $inst_num;
  
      if ($inst_num != $awr->{INST_NUM})
  	  {
                                       #**************************************/
                                       #* Skip AWR / STATSPACK reports       */
                                       #* where the instance number is not   */
                                       #* of interest for this iteration.    */
                                       #**************************************/
		  next;
	  } 
  	  $csv_file = $inst_id{$awr->{INST_NUM}} . '_' . $base_csv_file;
  
  	  $file_name = $awr->{FILE_NAME}; 

  	  $ref_awr   = $awr->{AWR_FILE};
  	  @awr_file  = @$ref_awr;
  
  	  if ($test_meta)
  	  {
  	    prn_log ("Applying meta-data to AWR / STATSPACK file: $file_name\n");
  	  }
                                        #**************************************/
                                        #* Check that the database version    */
                                        #* that the netadata entry belongs to */
                                        #* is the same as the AWR /           */
                                        #* STATSPACK file. If not we do       */
                                        #* nothing. If there are meta-data     */
                                        #* entries for such and entry, the    */
                                        #* file will be processed on another  */
                                        #* pass.                              */
                                        #**************************************/
  	  if ($awr->{FULL_VERSION} eq  $full_version && $inst_num == $awr->{INST_NUM})
  	  {
  	    $label_heading = $label_heading . "," . $awr->{END_SNAP_DTTM}; 
  	    $title_heading = $title_heading . "," . $file_name; 
  	    if ($count == 1)
  	    { 
  		  $count++;
  		  @csv = min_match($meta_file, $match_pattern, $data_start_pos, $start_str, $end_str
  			                      , $shift_lines
  								  , $pop_lines
  								  , \@awr_file);
          %csv = form_csv_cols($file_name
                             , $orig_title_heading
                             , $orig_label_heading
                             , $label_start_pos	
                             , $label_len
  							 , $data_start_pos
  							 , $data_len
  							 , \@csv);
  	    }
  	    else
  	    {
  		  %prev_csv = %csv;
  		  @csv = min_match($meta_file, $match_pattern, $data_start_pos
  			           , $start_str, $end_str, $shift_lines
  					              , $pop_lines, \@awr_file);
          %csv = form_csv_cols($file_name
                             , $orig_title_heading
                             , $orig_label_heading
                             , $label_start_pos
                             , $label_len
  			                 , $data_start_pos
                             , $data_len
                             , \@csv);
          %csv = bi_outer_join(\%prev_csv,\%csv);
        }
  	  }
     }
  
    if ( exists $csv_files{$csv_file} )
  	 {
                                         #*************************************/
                                         #*  CSV file written for a previous  */
                                         #* meta-data entry so append data     */
                                         #* cells, but dont write headers as  */
                                         #* they already exist.               */
                                         #*************************************/
  
    		open(CSV, ">> " . $out_dir . $SD . $csv_file) or 
  				die "$prog: FATAL ERROR! Cannot write to file \"$csv_file\"\n";
    		prn_log ("Appending $csv_file\n\n");
  	    $csv_files{$csv_file} = 'append';    
  	 }
  	else
  	 {
                                         #*************************************/
                                         #* register the CSV file as having   */
                                         #* already been eritten so we can    */
                                         #* append if we come across the same */
                                         #* file name in another meta-data     */
                                         #* entry.                            */
                                         #*************************************/
  		                                   
    	open(CSV, "> " . $out_dir . $SD . $csv_file) or 
  				die "$prog: FATAL ERROR! Cannot write to file \"$csv_file\"\n";
  
    	prn_log ("Writing $csv_file\n\n");
  	    $csv_files{$csv_file} = 'written';    
    	print CSV "$title_heading\n";
    	print CSV "$label_heading\n";
  	}
	 my %ext_csv  = ();
     for $key (keys %csv)
      {
        my $total = 0;
		if ( $csv{$key} =~ m/[0-9][\s]+[0-9]/ )
		{
			prn_log ("ERROR: Suspicious record format(1) detected for file $csv_file\n");
			prn_log ("Record in ERROR: $key $csv{$key}\n");
            my $rec =  $csv{$key};
            $rec  =~ s/[0-9][\s]+[0-9]+/<HERE>/;
			prn_log ("\n    See <HERE>:$key $rec\n");
			prn_log ("Ensure meta-data file: $meta_file matches the AWR report format and check for AWR corruption.\n");
			exit(1);
		}
		if ( $csv{$key} =~ m/--/ )
		{
			prn_log ("ERROR: Suspicious record format(2) detected for file $csv_file\n");
			prn_log ("RECORD: $key $csv{$key}\n");
			prn_log ("Ensure meta-data file: $meta_file matches the AWR report format and check for AWR corruption.\n");
			exit(1);
		}
		$total = sum_fields($csv{$key}, $csv_file, $meta_file);
		my $csv_rec = { TOTAL    => $total,
		                CSV_REC  => $csv{$key} };
      	$ext_csv{$key} = $csv_rec;
      }
     for $key (sort { $ext_csv{$b}->{TOTAL} <=> $ext_csv{$a}->{TOTAL}   } keys %ext_csv)
      {
      	print CSV "$key$ext_csv{$key}->{CSV_REC}\n";	
      }
     close(CSV);
  }
}

#******************************************************************************/
#* Function which takes list (array) of label / value pairs and returns a     */
#* hash keyed on label. The labels point to the value prefixed by a comma.    */
#******************************************************************************/
sub form_csv_cols
{
   my ($awr_file_name, $main_title, $label_heading, $label_start_pos, $label_len, $data_start_pos, $data_len, $in_array) = (@_);
   my @array = @$in_array;
   my %ret_hash =();
   my $label;
   my $temp_label;
   my $data;
   my $discard_lines      = 0;
   my $skip_lines_to_data = 0;
   my $rec_count          = 0;
   my $mod                = 0;
   my $skip               = 0;
   my $subfield_no        = 0;
   my $subfield_delim     = 0;
   my $store_data_start;
   my $suffix_delim_pos   = -1;
   my $label_suffix;
   my $len;

                                       #**************************************/
                                       #* Check to see if the label heading  */
                                       #* includes a label suffix to be      */
                                       #* appended to all the labels we      */
                                       #* extract from the AWR files. The    */
                                       #* suffix exists if the label         */
                                       #* heading contains two strings       */
                                       #* separated by a pipe character.     */
                                       #**************************************/
   $suffix_delim_pos = index($label_heading, '|', 0);
   if ($suffix_delim_pos > -1)
   {
     $label_suffix  = $label_heading;
	 $label_suffix  = substr($label_suffix, $suffix_delim_pos + 1);
   }
                                       #**************************************/
                                       #*  Check for SN-M format.            */
                                       #**************************************/
   if  ( $data_start_pos =~ m/^^S[\d]+-[\d]+$/ )
    { 
		 $skip_lines_to_data = $data_start_pos;
		 $skip_lines_to_data =~ s/-.*//;
		 $skip_lines_to_data =~ s/S//;
		 $data_start_pos =~ s/^S.*-//;
		 $skip = $skip_lines_to_data;
		 $skip_lines_to_data = $skip_lines_to_data + 1;
	}
                                       #**************************************/
                                       #* Check for M-CX format              */
                                       #**************************************/
   if ( $data_start_pos =~ m/^[\d]+-[\W\D][\d]+$/ )
   {
		 $subfield_no = $subfield_delim = $data_start_pos;
		 $data_start_pos =~ s/^([\d]+)-[\W\D][\d]+$/$1/;
		 $subfield_delim =~ s/^[\d]+-([\W\D])[\d]+$/$1/;
		 $subfield_no    =~ s/^[\d]+-[\W\D]([\d]+$)/$1/;
   }

   if ( $data_start_pos =~ m/^S[\d]+-[\d]-+[\W\D][\d]+$/ )
   {
		 $skip_lines_to_data = $subfield_no = $subfield_delim = $data_start_pos;
		 $data_start_pos     =~ s/^S[\d]+-([\d])-+[\W\D][\d]+$/$1/; 
		 $skip_lines_to_data =~ s/^S([\d])+-[\d]-+[\W\D][\d]+$/$1/; 
		 $skip_lines_to_data = $skip_lines_to_data + 1;
		 $skip               = $skip_lines_to_data;
		 $subfield_delim     =~ s/^S[\d]+-[\d]-+([\W\D])[\d]+$/$1/; 
		 $subfield_no        =~ s/^S[\d]+-[\d]-+[\W\D]([\d])+$/$1/; 
   }

   foreach $record (@array)
     { 
		 $rec_count = $rec_count + 1;

		 if ($skip)
           { $mod = $rec_count % $skip_lines_to_data; }

         chomp $record;
		 if ($skip && ($mod) == 1) 
		 {
		   if (length($record) < $label_start_pos)
		   {
			 prn_log ("WARNING[2]: Possible incorrect meta-data entry \"$main_title\" found!\n");
			 prn_log ("            Record being processed is shorter than \"label\"\n");
			 prn_log ("            column defined start pos! ($label_start_pos)\n");
			 prn_log ("Record in error -> [$record]\n");
			 prn_log ("Skipping this row!\n");
			 prn_log_divider();
      		 next;
		   }

		   if (length($test_meta))
		   { 
              prn_log ("\n(rec count: $rec_count skip lines: $skip_lines_to_data mod: $mod) "); 
              prn_log ("Asssuming initial LABEL record:\n"); 
              prn_log("*****************************************");
              prn_log("*****************************************\n"); 
              prn_log ("$record\n"); 
              prn_log("*****************************************");
              prn_log("*****************************************\n"); 
           }

           $label = substr($record,$label_start_pos - 1, $label_len);
           if ($suffix_delim_pos  > -1)
           {
              $len = length($label) + length($label_suffix);
              $len = $label_len + length($label_suffix);
		      $label = rpad(trim($label) . $label_suffix,$len);
           }
           else
           {
              $len = length($label);
		      $label = rpad(trim($label), $label_len);
           }
	     }

                                       #**************************************/
                                       #* We have already started to obtain  */
                                       #* the label (above) but for a        */
                                       #* multi-line label (when using the   */
                                       #* SN-M format) we may need to grab   */
                                       #* bits of the label on the           */
                                       #* following lines prior to the data. */
                                       #**************************************/
         if ($rec_count < $skip_lines_to_data and $mod != 1) 
		 {
		   $temp_label = substr($record,$label_start_pos - 1, $label_len);
		   $temp_label = trim($temp_label);
           if ( $temp_label =~ m/[a-zA-Z]+/ )
           {
            #  $len = $label_len + length($label);
		    #  $label = rpad($label,$len);
               $label = $label . " " . $temp_label;
           }
         }
		 elsif (! $skip)
		 {
		   if (length($record) < $label_start_pos)
		     {
			   prn_log ("WARNING[3]: Possible incorrect meta-data entry \"$main_title\" found!\n");
			   prn_log ("            Record being processed is shorter than \"label\"\n");
			   prn_log ("            column defined start pos! ($label_start_pos)\n");
			   prn_log ("Record in error -> [$record]\n");
			   prn_log ("Skipping this row!\n");
			   prn_log_divider();
      		   next;
		     }
		   $label = substr($record,$label_start_pos - 1, $label_len);
           if ($suffix_delim_pos  > -1)
           {
              $len = length($label) + length($label_suffix);
		      $label = rpad(trim($label) . $label_suffix,$len);
           }
           else
           {
              $len = length($label);
		      $label = rpad(trim($label),$len);
           }
	     }

		 if ($skip && ($mod) == 0) 
		 {
		   if ($test_meta)
			{  
              prn_log ("\n(rec count: $rec_count skip lines: $skip_lines_to_data mod: $mod) "); 
              prn_log ("Assuming DATA record:\n"); 
              prn_log("*****************************************");
              prn_log("*****************************************\n"); 
              prn_log ("$record\n"); 
              prn_log("*****************************************");
              prn_log("*****************************************\n"); 
            }

		    if (length($record) < $data_start_pos)
		    {
			 prn_log ("WARNING[4]: Possible incorrect meta-data entry \"$main_title\" or malformed AWR report found!\n");
			 prn_log ("            Record being processed is shorter than \"data\"\n");
			 prn_log ("            column defined start pos! ($data_start_pos)\n");
			 prn_log ("Record in error -> [$record]\n");
		     prn_log ("The bad record was found processing AWR file: $awr_file_name.\n");
			 prn_log ("Skipping this row!\n");
			 prn_log_divider();
      		 next;
		    }
                                       #**************************************/
                                       #* If data_len is '#' then the field  */
                                       #* start position refers to the       */
                                       #* field number, otherwise it refers  */
                                       #* to the column the field starts     */
                                       #* at.                                */
                                       #**************************************/
           if ( $data_len eq '' )
           {
              $data =  @{[$record =~ m/\S+/g]}[$data_start_pos - 1];  
           }
           else
           {
		      $data  = substr($record,$data_start_pos - 1, $data_len);
           }

		   if ($subfield_delim)
		   {
			   $data = subfield($data, $subfield_delim, $subfield_no);
		   }
		   $data  =~ s/,//g;
                                       #**************************************/
                                       #*  If we are doing a test run then   */
                                       #* align the data neatly to make it   */
                                       #* more readable.                     */
                                       #**************************************/
           if ($test_meta)
           {
             $data = lpad($data, $data_len);
           }
           else
                                       #**************************************/
                                       #*  Otherwise we trim out the         */
                                       #* extraneous spaces to save space.   */
                                       #**************************************/
           {
             $data = trim($data, $data_len);
           }
                                       #**************************************/
                                       #* Field validation: Ensure that we   */
                                       #* have no alpha characters unless    */
                                       #* these are string 'N/A' or          */
                                       #* exponent symbol (E+).              */
                                       #**************************************/
           if ( $perform_field_valdn and $data =~ m/[A-Za-z]/ and trim($data) ne 'N/A' and index($data,'E+') == -1)
           {
     	    prn_log ("ERROR: Non-numeric found where a number was expected applying meta-data entry \"$main_title\"\n");
            prn_log ("Element looks like: \"$data\"\n");
		    prn_log ("Ensure the meta-data file entry matches the AWR report format.\n");
		    prn_log ("ERROR occurred processing AWR file: $awr_file_name.\n");
		    exit(1);  
           }

           $ret_hash{$label} =  "," . $data; 
		 }
		 elsif (!$skip)
		 {
		   if (length($record) < $data_start_pos)
		   {
			prn_log ("WARNING[5]: Possible incorrect meta-data entry \"$main_title\" found!\n");
			prn_log ("            Record being processed is shorter than \"data\"\n");
			prn_log ("            column defined start pos! ($data_start_pos)\n");
			prn_log ("Record in error -> [$record]\n");
		    prn_log ("The bad record was found processing AWR file: $awr_file_name.\n");
			prn_log ("Skipping this row!\n");
			prn_log_divider();
      		next;
		   }
		   if (length($test_meta))
		   {  
            prn_log ("\nProcessing extracted label / data RECORD:\n");
            prn_log("*****************************************");
            prn_log("*****************************************\n"); 
            prn_log ("$record\n");
            prn_log("*****************************************");
            prn_log("*****************************************\n"); 
           }
           if ( $data_len eq '' )
           {
		      my $sub_record = substr($record,$label_start_pos + $label_len);
              $data =  @{[$sub_record =~ m/\S+/g]}[$data_start_pos - 2];  
              
              if (! defined $data)
              {
                  prn_log("WARNING:\n");
                  prn_log("Suspicious empty field encountered (by field number).\n");
                  prn_log("Encountered in: $awr_file_name\n");
                  prn_log("    AWR Record: $record\n");
                  prn_log("    Main Title: $main_title\n");
                  prn_log(" Label Heading: $label_heading\n");
                  prn_log("      Field No: $data_start_pos\n");
                  prn_log("\nPossible cause: Variance in number of fields for this section of report.\n");
                  prn_log("         Action: Consider using a pattern filter to ommit such records\n");
                  prn_log("                 records and process such records using a seperate \n");
                  prn_log("                 meta-data record entry.\n");
                  $data = ' ';
	          #   prn_log("$prog: Bailing out!\n");
              }
           }
           else
           {
		     $data  = substr($record,$data_start_pos - 1, $data_len);
#             print "DB2: $awr_file_name : record = $record; data = $data\n";
           }
		   if ($subfield_delim)
		   {
			 $data = subfield($data, $subfield_delim, $subfield_no);
		   }

		   $data  =~ s/,//g;
           if (length($test_meta))
           {
            $data = lpad($data, $data_len);
           }
           else
                                       #**************************************/
                                       #*  Otherwise we trim out the         */
                                       #* extraneous spaces to save space.   */
                                       #**************************************/
           {
            $data = trim($data, $data_len);
           }
                                       #**************************************/
                                       #* Field validation: Ensure that we   */
                                       #* have no alpha characters unless    */
                                       #* these are string 'N/A' or          */
                                       #* exponent symbol (E+).              */
                                       #**************************************/
           if ( $perform_field_valdn and $data =~ m/[A-Za-z]/ and trim($data) ne 'N/A' and index($data,'E+') == -1)
           {
     	 	prn_log ("ERROR: Non-numeric found where a number was expected applying meta-data entry \"$main_title\"\n");
            prn_log ("Element looks like: \"$data\"\n");
			prn_log ("Ensure the meta-data file entry matches the AWR report format.\n");
			prn_log ("ERROR occurred processing AWR file: $awr_file_name.\n");
			exit(1);  
           }
           $ret_hash{$label} =  "," . $data; 
		 }
         if ($test_meta and !$mod)
   	    	{
			   prn_log ("\nConverting & adding record into comma delimited label / data COLUMNS results set:\n");
               prn_log("*****************************************");
               prn_log("*****************************************\n");
			   foreach $key (keys %ret_hash)
			   { 
                   prn_log ("$key $ret_hash{$key}"); 
                   if ( $ret_hash{$key}  =~ m/[0-9][\s]+[0-9]/  or  $ret_hash{$key} =~ m/--/ )
	                {
			          prn_log (" <--- Data failed sanity check!\n");
	                }
                    else
                    {
                        prn_log ("\n");
                    }
               }
               prn_log("*****************************************");
               prn_log("*****************************************\n");
               prn_log ("Performing Sanity check for meta-data entry  \"$main_title\"...\n");
			   foreach $key (keys %ret_hash)
			   { 
                   if ( $ret_hash{$key}  =~ m/[0-9][\s]+[0-9]/  or  $ret_hash{$key} =~ m/--/ )
	                {
			          prn_log ("Field sanity checks failed for file $awr_file_name!");
                      exit(1);
	                }
               }
               prn_log ("Sanity check completed OK\n\n");
            }

	}
    if ($perform_field_valdn)
    {
	  foreach $key (keys %ret_hash)
	  { 
        if ( $ret_hash{$key}  =~ m/[0-9][\s]+[0-9]/  or  $ret_hash{$key} =~ m/--/ )
	    {
		  prn_log ("Field sanity checks failed for file $awr_file_name!\n");
          prn_log ("$key $ret_hash{$key}"); 
		  prn_log (" <--- Data failed sanity check!\n");
          exit(1);
	    }
      }
    }
	return %ret_hash;
}
#******************************************************************************/
#* Function: hash_intersect to accept two hashes and retern an intersection   */
#* hash of the 2.                                                             */
#******************************************************************************/
sub hash_intersect
{
   my ($hasha, $hashb) = @_;
   my %newhash;
   foreach my $key (keys %{$hasha})
   {
      $newhash{$key} = $$hasha{$key} if (exists $$hashb{$key});
   }
   return %newhash;
}

#******************************************************************************/
# LPad                                                                        */
# Pads a string on the left end to a specified length with a specified        */
# character and returns the result.  Default pad char is space.               */
#******************************************************************************/
sub lpad {

my ($str, $len, $chr) = @_;

$chr = " " unless (defined($chr));
    
return substr(($chr x $len) . $str, -1 * $len, $len);

}

#******************************************************************************/
# RPad                                                                        */
# Pads a string on the right end to a specified length with a specified       */
# character and returns the result.  Default pad char is space.               */
#******************************************************************************/
sub rpad {

my ($str, $len, $chr) = @_;

$chr = " " unless (defined($chr));
    
return substr($str . ($chr x $len), 0, $len);

} # RPad

#******************************************************************************/
#* Function: list_intersect to accept 2 lists (arrays) and return the         */
#* intersection of both.                                                      */
#******************************************************************************/
#sub list_intersect
#{
#   my $item;
#   my @arraya = ();
#   my @arrayb = ();
#   my %hasha  = ();
#   my %hashb  = ();
#   my @newarray;
#   my %newhash;
#
#   my ($arraya, $arrayb) = @_;
#   @arraya = @$arraya;
#   @arrayb = @$arrayb;
#   foreach $item (@arraya)
#      { $hasha{$item} = 1 }
#   foreach $item (@arrayb)
#      { $hashb{$item} = 1 }
#   
#   %newhash = hash_intersect(\%hasha, \%hashb);
#   @newarray = keys %newhash;
#   return @newarray;
#}
#******************************************************************************/
#* Function to return the sum of all values in a comma separated list of      */
#* numbers.                                                                   */
#******************************************************************************/
sub sum_fields
{
   my $num;
   my $total = 0;
   my ($num_str, $csv_file, $meta_file) = @_;
   my @nums = split(',', $num_str);
   foreach $num (@nums)
   {
	 $num = trim($num);
	 if ( ! "$num"  or "$num" eq "N/A")
	 {
		 $num = 0;
	 }
	 $num =~ s/#/9/g;
     if ( $num =~ m/\D/ and $num !~ m/[.-]/ )
     {
       prn_log ("ERROR: Non-numeric found where a number was expected whilst processing $csv_file\n");
       if (! $perform_field_valdn)
       { prn_log ("Use -f flag for improved diagnosis of the error.\n"); }
       else
       { prn_log ("Element looks like: \"$num\"\n"); }
	   exit(1);  
     }
     else
     {
         $total = $total + $num;
     }
   }
   return $total;
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
#* Function: min_match accepts an array and returns the lines between two     */
#* search criteria in the form of an array. This works on a "minimal"         */
#* matching basis as opposed to the "greedy" matching performed by grep.      */
#******************************************************************************/
sub min_match
{
  my $collect = 0;
  my ($meta_file, $match_pattern, $data_start_pos, $start_str, $end_str, $shift_lines, $pop_lines, $srch_array) = (@_);
  my @search_array = @$srch_array;
  my @ret_array    = ();
  my @filter_array = ();
  my $shift_count;
  my $rec_count          = 0;
  my $mod;
  my $discard_lines      = 0;
  my $skip               = 0;

  chomp $pop_lines;
  chomp $shift_lines;

  if  ( $data_start_pos =~ m/^D[\d]+-/ )
    { 
		 $discard_lines = $data_start_pos;
		 $discard_lines =~ s/-.*//;
		 $discard_lines =~ s/D//;
		 $skip = $discard_lines;
		 $discard_lines = $discard_lines + 1;
	}

  my $pop_count;


  foreach $record (@search_array)
    { 
      chomp $record;
      if($record   =~ m/$start_str/)
        {
          $collect = 1;
        }

       if($record   =~ m/$end_str/ and $collect)
        {
          $collect = 0;
          push @ret_array, ($record); 
          last;
        }

      if ($collect)
        { 
          push @ret_array, ($record); }
        }
  if ($test_meta)
  { 
    prn_log("\n   Start String: \"$start_str\"\n     End String: \"$end_str\"\n");
	prn_log ("\nSnippet based on Start and End search strings:\n");
    prn_log("*****************************************");
    prn_log("*****************************************\n");
	foreach $record (@ret_array)
	  { prn_log("$record\n")}
    prn_log("*****************************************");
    prn_log("*****************************************\n");
  }
                                       #**************************************/
                                       #* Originally intended to use shift   */
                                       #* to remove the top lines,           */
                                       #* including the start search string  */
                                       #* line. However some reports with    */
                                       #* large sections repeat the          */
                                       #* headings due to page breaks in     */
                                       #* the middle of the section. This    */
                                       #* being the case we need to scan     */
                                       #* through our reduced array at this  */
                                       #* point and remove all occurrences   */
                                       #* of the start search string plus    */
                                       #* any following lines based on the   */
                                       #* shift count.                       */
                                       #**************************************/
	$rec_count = 0;
	foreach $record (@ret_array)
	{
      if($record   =~ m/$start_str/)
        {
          splice(@ret_array, $rec_count, $shift_lines);
        }
	  $rec_count++;
	}

    for ($pop_count = 0; $pop_count < $pop_lines; $pop_count++)
 	      { pop @ret_array }

    foreach $record (@ret_array)
	    { if (length($record))
           { push @filter_array, ($record); } 
	    }
	@ret_array = @filter_array;
  if ($test_meta)
  { 
	prn_log ("\nSnippet after applying Shift($shift_lines) Pop($pop_lines) values:\n");
    prn_log("*****************************************");
    prn_log("*****************************************\n");
	foreach $record (@ret_array)
	  { prn_log("$record\n")}
    prn_log("*****************************************");
    prn_log("*****************************************\n");
  }

    if ($test_meta and $match_pattern)
    {
	    prn_log ("\nApplying filter (regexp): \"$match_pattern\":\n");
    }

    if ($match_pattern)
        {
		   @filter_array = ();
           foreach $record (@ret_array)
	         { 
			   if ($record =~ m/$match_pattern/)
                 { push @filter_array, ($record); } 
	         }
	       @ret_array = @filter_array;
        }


    if (length($test_meta) and $match_pattern) 
        {   
            prn_log("*****************************************");
            prn_log("*****************************************\n");
			foreach $record (@ret_array)
		      { prn_log("$record\n")}
            prn_log("*****************************************");
            prn_log("*****************************************\n");
	    }

  return @ret_array;
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
   printf ("%s", @log_line);
   printf LOG ("%s", @log_line);
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
   printf ("%s: %s\n", $dts, @log_line);
}
#******************************************************************************/
#* Function sortable_dttm which accepts:                                      */
#*   date in the form DD-Mon-YY                                               */
#*   time in the form HH24:MI:SS                                              */
#* and returns a date/time of format YYMMDDHH24MISS in order                  */
#* that we can use the date/time for sorting.                                 */
#******************************************************************************/
sub sortable_dttm {
    
	my $mm;
	my $dd;
	my $yy;
	my $formed_date;
	my ($date, $time) = (@_);

	$mm = $dd = $yy = $date;
	$mm =~ s/\d\d-(\w\w\w)-\d\d/$1/;

	given ($mm)
	{
		when ("Jan") { $mm = '01' }
		when ("Feb") { $mm = '02' }
		when ("Mar") { $mm = '03' }
		when ("Apr") { $mm = '04' }
		when ("May") { $mm = '05' }
		when ("Jun") { $mm = '06' }
		when ("Jul") { $mm = '07' }
		when ("Aug") { $mm = '08' }
		when ("Sep") { $mm = '09' }
		when ("Oct") { $mm = '10' }
		when ("Nov") { $mm = '11' }
		when ("Dec") { $mm = '12' }
		default { $mm = 99 }
	}	

	$time =~ s/://g;
	$yy =~ s/\d\d-\w\w\w-(\d\d)/$1/;
	$dd =~ s/(\d\d)-\w\w\w-\d\d/$1/;
	$formed_date = $yy . $mm . $dd . $time;
	$formed_date =~ s/[\s\:]//g;
	return $formed_date;
}

#******************************************************************************/
#* Function subfield. Accepts a field which can be broken into subfields      */
#* based on it containing delimiters. For example of the form "A/B/C/D"       */
#* where the delimiter in this case is "/". The second and third parameters   */
#* are the delimiter character and the sub-field number required. The         */
#* function plucks out the value of the specified subfield no and returns     */
#* it. The first field number starts with 1.                                  */
#******************************************************************************/
sub subfield
{

  my ($field, $delim, $subfield_no) = @_;
  my $subfield_count = 0;
  my $subfield;
  $field = $field . $delim;

  my $sfield_start_pos = 0;
  my $sfield_end_pos   = 0;
  while ($subfield_count  <  $subfield_no)
  {
    $sfield_end_pos  = index($field, $delim, $sfield_start_pos);
	$subfield_count = $subfield_count + 1;
    $subfield = substr($field, $sfield_start_pos,$sfield_end_pos - $sfield_start_pos);
	$sfield_start_pos = $sfield_end_pos + 1;
  }

  return $subfield;
}

#******************************************************************************/
#* INITIAL Processing section - process arguments                             */
#******************************************************************************/
sub disp_categories
{
	
  if (  -f $meta_dir . $SD . "Categories.mta" ) 
  {
	  open (MTA,$meta_dir . $SD . "Categories.mta") or
	       die "$prog: Cannot open: " . $meta_dir . $SD . "Categories.mta";
	  my @categories = <MTA>;
	  close (MTA);

	  my @cat_titles = @categories;
	  my %cat_titles = ();
	  my $title;
	  my %category_mtas = ();
	  my $category_mta;  
	  my $cat;

	  foreach $record (@cat_titles)
	  {
		  chomp $record;
		  $title = $cat = $record;
		  if ($record =~ m/^#[\w\d]:.*$/ )
		  {
			$title =~ s/^#[\w\d]+:(.*)$/$1/;
			$title = trim($title);
			$cat   =~ s/^#([\w\d]+):.*$/$1/;
			$cat_titles{$cat} = $title;
		  }
	  }


	  foreach $record (@categories)
	  {
		  chomp $record;
		  $category_mta = $cat = $record;
		  if (index($record, ':') > 0 and index($record,'#') != 0)
		  {
			$category_mta =~ s/^[\w\d]+:(.*)$/$1/;
			$cat          =~ s/:.*//;
			$category_mtas{$category_mta} = $cat;
		  }
	  }

	  prn_log ("\nMetadata categories:\n");

	  my $last_cat = -1;
	  foreach $category_mta (sort { $category_mtas{$a} <=> $category_mtas{$b} } 
		            keys %category_mtas)
	  {
		  $cat = $category_mtas{$category_mta};
		  if ( $category_mtas{$category_mta} != $last_cat )
		  {
			  if (exists $cat_titles{$cat})
			  {
                
			    prn_log ("\n$cat: $cat_titles{$cat}:\n\n");
			  }
			  else
			  {
			    prn_log ("\nCategory $cat meta-data:\n\n");

			  }
			  $last_cat = $cat;
		  }
		  prn_log ("   $category_mta\n");
	  }
      prn_log ("\nThe numbers before the Category descriptions are \n");
      prn_log ("for use with the -C option.\n\n");
	  prn_log ("\nNOTE: A meta-data entry listed may not necessarily exist\n");
      prn_log ("      in a meta-data sub-directory for a given version or RAC\n");
      prn_log ("      option. These entries are simply used as filters based on\n");
      prn_log ("      the category, if selected, at run-time with the -C option.\n");
      prn_log ("      Additionally some may not have yet been implemented.\n");
	  prn_log ("\n$prog: Done.");
  }
}

sub disp_usage()
{
  print "\n$prog: Vers: $vers\n\n";
  print  "Usage $prog [ -f -c csv_pref -C category -o out_dir -I -L -m meta_dir\n";
  print  "              -M meta-file -t meta-file -p prefix -s suffix ] | -h\n\n";
  print " -c csv_pref : Prefix The generated CSV file names are prefixed\n";
  print "               with csv_pref.\n";
  print "               NOTE: An underscore character is automatically\n";
  print "                     appended to pref_str before prefixing the.\n";
  print "                     CSV file name.\n\n";
  print " -C category : Category defines what category of CSV files should \n";
  print "               be generated. This is based on the contents of the \n";
  print "               Categories.mta file in the meta-data root directory.\n";
  print "               Use -L to obtain a listing of category -> meta-data\n";
  print "               mappings.\n\n";
  print "               Without this option CSV files are generated based on\n";
  print "               category 9 (Performance Report) meta-data files implemented\n";
  print "               for a relevant Oracle version / RAC (or non RAC) combination.\n\n";
  print " -d awr_dir  : Directory where the AWR reports are located\n\n";
  print " -f          : Perform field level data sanity checks. \n";
  print " -I          : Ignore any Oracle errors (starting with \"ORA-\") \n";
  print "               contained in AWR files. Default behaviour is to skip \n";
  print "               such files and report the file as well as the errors\n";
  print "               encountered in the file.\n\n";
  print "               WARNING: You may find that errors and / or warnings will be reported \n";
  print "                        generating some CSV files if you elect to ignore the Oracle\n";
  print "                        errors.\n\n";
  print " -L          : Display the category -> meta-data file mappings\n";
  print "               associated with the -C option.\n\n";
  print " -M meta-file: Run with only the specified meta-data file.\n";
  print "             : NOTE: If used with -t, the -t flag is ignored.\n\n";
  print " -m meta_dir : Directory where awrcsv meta-data is to be found\n\n";
  print " -o out_dir  : Directory to output the CSV files to.\n\n";
  print " -p prefix   : Process AWR report files which have this prefix\n\n";
  print " -s suffix   : Process AWR report files which have this suffix\n\n";
  print " -t meta-file: Test / Debug a soecified meta-data file.\n";
  print "               E.g awrcsv.pl -t Load_profile.mta.\n\n";
  print " -h          : Display help (this text)\n\n";
  print "NOTE: awr_dir defaults to the current working directory\n";
  print "      The location of meta_dir defaults to the current directory.\n";
  print "      The location of out_dir defaults to the current directory.\n";
  print "      File prefix and suffix are optional.\n";
  print "      File prefix defaults to \"awr\" \n";
  print "      File suffix defaults to \"txt\" \n\n";
}

our (
     $opt_c
    ,$opt_C
    ,$opt_d
    ,$opt_f
    ,$opt_h
    ,$opt_I
    ,$opt_L
    ,$opt_M
    ,$opt_m
    ,$opt_o
    ,$opt_p
    ,$opt_s
    ,$opt_t
    );

getopts('c:C:d:fhILM:m:o:p:s:t:') or 
    die "\n$prog : Invalid options specified, use $prog -h. Deploying chute and bailing out!!!\n";
if(defined($opt_c))
{
  $csv_prefix=$opt_c . "_";
}
if(defined($opt_d))
{
  $awr_dir = $opt_d;
  if ( ! -d $awr_dir )
  { print "Invalid AWR report location specified (-d)\n"; 
	exit(1); }
}

if(defined($opt_f))
{
  $perform_field_valdn = 1;
}
else
{
  $perform_field_valdn = 0;
}
if(defined($opt_h))
{
  disp_usage();
  exit;
}

if(defined($opt_C))
{
  $category = $opt_C;
}

if(defined($opt_m))
{
  $meta_dir=$opt_m;
}

if(defined($opt_I))
{
  $trap_awr_errors=0;
}

if(defined($opt_M))
{
  $run_meta=$opt_M;
  $category = 0;
}


if(defined($opt_o))
{
  $out_dir = $opt_o;
  if ( ! -d $out_dir )
  { print "Invalid CSV output location specified (-o)\n"; 
	exit(1); }
}

if(defined($opt_p))
{
  $awr_prefix=$opt_p;
}

if(defined($opt_s))
{
  $awr_suffix=$opt_s;
}

if(defined($opt_t))
{
                                       #**************************************/
                                       #* Force category to 0 so that the    */
                                       #* test meta-data file specified is   */
                                       #* not restricted by category.        */
                                       #**************************************/
  $category = 0;
  $test_meta=$opt_t;
}


if (  -f ($meta_dir . $SD . "Categories.mta" ) and $category )
{
	open (MTA,$meta_dir . $SD . "Categories.mta");
	my @categories = <MTA>;
	close (MTA);
	foreach $record (@categories)
	{
		chomp $record;
		my $category_mta = $record;
		if (index($record, $category . ':') == 0)
		{
                                       #**************************************/
                                       #*  Store the listed meta-data file   */
                                       #* name so we can use the stored      */
                                       #* list later for                     */
                                       #*                                    */
                                       #* filtering out unwanted             */
                                       #* categories.                        */
                                       #**************************************/
			$category_mta =~ s/^$category:(.*)$/$1/;
			$categories{$category_mta} = 1;
		}
	}
}
elsif ($category)
{
	print "$prog: Cannot find the categories file (" . $meta_dir . $SD . 
	       "Categories.mta) required for -C option\n";
	deploy_chute;
}

#******************************************************************************/
#* LOAD the AWR / STATSPACK reports into array structures.                    */
#******************************************************************************/
  my $ref_awr;
# printf "Changing working directory to $awr_dir\n";
# chdir $awr_dir or die "$prog: Cannot change to specfied directory (-d $awr_dir)\n";

  open(LOG, "> $logfile") or die "$prog: FATAL ERROR! Cannot write to file \"$logfile\"\n";

  if(defined($opt_L))
  {
	$category = $opt_L;
    disp_categories();
    exit;
  }

  prn_log_ts("$prog: Vers: $vers\n");
  prn_log_ts("$prog: Started\n");
  if ($perform_field_valdn) 
  {
    prn_log("Including field level sanity checks...\n");
  }
  opendir(AWR,$awr_dir);
  my @awr_file_names = readdir(AWR);
  closedir(AWR);


  @awr_file_names = grep(/\.$awr_suffix$/, @awr_file_names);
  @awr_file_names = grep(/^$awr_prefix/, @awr_file_names);

  my $report_count = @awr_file_names;

  if ( $report_count > 0 )
  {
      prn_log ("Scanning $report_count AWR / STATSPACK reports...\n");
  }
  else
  {
      prn_log ("No AWR / STATSPACK reports found in directory \"$awr_dir\" for processing!\n\n");
  }

  foreach $awr_file (@awr_file_names)
  {
    if ( -f $awr_dir . $SD . $awr_file )
    {
      open(AWRFILE, $awr_dir . $SD . $awr_file) || die "Failed to open AWR/STATSPACK ($awr_file)\n";
      @awr_file=<AWRFILE>;
      close(AWRFILE) || die "Failed to AWR/STATSPACK file ($awr_file)\n";
      chomp @awr_file;
      if ( $trap_awr_errors )
      {
        my @awr_errors = grep(/ORA-/, @awr_file);
        if (@awr_errors)
        {
            print "INFO: Skipping $awr_file because it contains errors:\n";
            foreach $record (@awr_errors)
            {
               print "  $record\n";
            }
            print "\n";
            next;
        }
      }
    }
    else
    {
      next;
    }

  @snap_rec = grep(/End Snap/, @awr_file);

  $snap_id = $snap_date = $snap_time = join('\n', @snap_rec);
  chomp $snap_id;
  $snap_id =~ s/End Snap:(\s*)(\d*)\s.*/$2/;
  chomp($snap_date);
  $snap_date =~ s/^.*(\d\d-\w\w\w-\d\d).*/$1/;
  chomp($snap_date);
  $snap_time =~ s/^.*(\d\d:\d\d:\d\d).*/$1/;

  $sort_dttm = sortable_dttm ($snap_date, $snap_time);


  my $loop = 0;
  foreach $record (@awr_file)
  { 

     chomp $record;
	 if ($loop)
	   { $loop = $loop + 1 }
     if($record   =~ m/DB Id/)
       {
                                       #**************************************/
                                       #*  Set $loop then we need to loop    */
                                       #* to a value of 3 to get the         */
                                       #* version line.                      */
                                       #**************************************/
		   $loop = 1;
       }
	 if ($loop == 3)
       {
		   $full_version = $inst_num = $db_name = $inst_name = $is_rac = $record;
		   last;
       }
  } 
                                       #**************************************/
                                       #* Determine the version details. We  */
                                       #* want to get both the full release  */
                                       #* (e.g. 11.1.0.6.0) and the          */
                                       #* maintenance release (e.g. 11.1)    */
                                       #* Here we term the latter as the     */
                                       #* base version.                      */
                                       #**************************************/
  $full_version =~ s/^.*([1-9 ]\d.\d\.\d\.\d.\d).*/$1/;
  $full_version = ltrim($full_version);
  $base_version = $full_version;
  $base_version =~ s/^([\d ]+\.[\d]+)[\.].*/$1/;
  $base_version = ltrim($base_version);
  $inst_name =~ s/^[\S]+[\s]+[0-9]+[\s]([\w\d\_\$]+)[ ].*/$1/;
  $inst_num =~ s/^.*[ ]+[0-9]+[ ][\w\d\-_]+[ ]([\s\d]+)[ ].*/$1/;
  $inst_num = trim($inst_num);
  $db_name  =~  s/^(.*)[ ]+[0-9]+[ ][\w\d\-_]+[ ][\s\d]+[ ].*/$1/;
  $db_name = trim($db_name);

                                       #**************************************/
                                       #*  Is this a RAC based report?       */
                                       #**************************************/

  $is_rac  =~ s/^.*$full_version[ ]+([A-Z]+).*/$1/;

  $is_rac  =~ tr/A-Z/a-z/;

                                       #**************************************/
                                       #* Determine meta-data location.      */
                                       #* First checking for a directory     */
                                       #* based on the full release. If      */
                                       #* that doesn't exist, check for a    */
                                       #* directory based on base version.   */
                                       #* We also need to take account of    */
                                       #* whether the report is for RAC or   */
                                       #* non rac.                           */
                                       #**************************************/
  if ( -d $meta_dir . $SD . $full_version )
  	{$meta_sub = $meta_dir . $SD . $full_version } 
  elsif ( -d $meta_dir . $SD . $base_version )
  	{$meta_sub = $meta_dir . $SD . $base_version } 
  else
    { prn_log("Non-configured (missing meta-data) RDBMS version $full_version");
	  prn_log(" ($base_version) for file: $awr_file\n");
	  prn_log("Supplementary information: no \"" . $meta_dir . $SD . $base_version . "\"\n");
	  prn_log("or optional \"" . $meta_dir . $SD . $full_version . "\" directory found\n");
		         
	  exit(1);
    }
                                       #**************************************/
                                       #*  Now refine the meta-data location  */
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
  elsif ( $is_rac eq "no" )
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
  else
  { 
	  prn_log( "RAC status undetermined!\n");
	  prn_log( "Error interpretining AWR / STATSPACK contents\n");
	  prn_log("$prog: Bailing out!\n");
	  exit (1);
  }
                                       #**************************************/
                                       #*  Store the meta directory for      */
                                       #* this version. This hash will be    */
                                       #* used to forge the driving loop     */
                                       #* for processing our output.         */
                                       #**************************************/
	  $meta_sub = sprintf("%s", $meta_sub);
	  $meta_dir{$full_version} = "$meta_sub"; 

                                       #**************************************/
                                       #*  Build a master hash simply        */
                                       #* containing snapshot date/time,     */
                                       #* snapshot details                   */
                                       #* and the file names.                */
                                       #*  Store base and full version as    */
                                       #* well as file name and meta-data     */
                                       #* file and its location in a hash    */
                                       #* structure keyed on full version    */
                                       #* concatenated with snap dttm.       */
                                       #*  We also need to register whether  */
                                       #* the the report is for RAC or       */
                                       #* single instance (SI).              */
                                       #**************************************/
  { my @awr = @awr_file; 
	$ref_awr = \@awr; }
  $awr_rec = {
				END_SNAP_DTTM => $snap_date . " " . $snap_time
		       ,END_SNAP_ID   => $snap_id
		       ,FILE_NAME     => $awr_file
		       ,DB_NAME       => $db_name
		       ,INST_NUM      => $inst_num
		       ,INST_NAME     => $inst_name
		       ,IS_RAC        => $is_rac
		       ,FULL_VERSION  => $full_version
		       ,BASE_VERSION  => $base_version
		       ,AWR_FILE      => $ref_awr
	           };
                                       #**************************************/
                                       #* Use hash structures to keep count  */
                                       #* of distinct instance names and     */
                                       #* versions that we are dealing       */
                                       #* with.                              */
                                       #**************************************/
  $inst_id{$inst_num}         = $inst_name; 
  $db_versions{$full_version} = $inst_name;
  $inst_nums{$inst_num}       = $inst_name;

  $version_num = $full_version;
  $version_num =~ s/\.//g;
# $awr_file {$awr_rec -> {FILE_NAME}} = $awr_rec;
                                       #**************************************/
                                       #*  Store the file details...         */
                                       #**************************************/
  $awr_file {$inst_num . $version_num . $sort_dttm} = $awr_rec;

                                       #**************************************/
                                       #*  Store full version and file name  */
                                       #* in a hash structure, keyed on      */
                                       #* version. This will provide a       */
                                       #* distinct list of versions as well  */
                                       #* as providing a table indicating    */
                                       #* when we are processing the last    */
                                       #* file for a given version.          */
                                       #**************************************/
  $version_list{$full_version} = $awr_rec -> {FILE_NAME};
}
#******************************************************************************/
#* We are now in a position to scan through the AWR files stored in our       */
#* $awr_file hash. We drive the process from the %meta_dir hash structure.    */
#* This may contain one or more directories based on versions. We may expect  */
#* more than one if a database has been upgraded for example.                 */
#* For each meta data directory we loop through the AWR files applying        */
#* the meta data rules to generate the CSV for all AWR files with a match on  */
#* the full version.                                                          */
#******************************************************************************/

  foreach $full_version (sort keys %meta_dir)
    {
	  my $dir = $meta_dir{$full_version};
	  my $no_files;
	  my @meta_files;

	  if (length($run_meta))
	  {
		  @meta_files = ($run_meta);
	  }
	  elsif (length($test_meta))
	  {
		  @meta_files = ($test_meta);
	  }
	  else
	  {
        opendir(DIR,$dir);
        @meta_files = readdir(DIR);
        closedir(DIR);
        @meta_files = grep(/\.mta/, @meta_files);
	    if (! scalar @meta_files)
	    {
		    prn_log("$prog: No meta-data files found in $dir\n");
		    prn_log("$prog: Bailing out!\n");
		    exit(1);
	    }
	  }

  my @temp_array = ();

  if ($category and ! $run_meta)
  {
	if (scalar (keys %categories) == 0)
	{
		prn_log ("prog: ERROR! No meta-data files found for category $category\n");
		prn_log ("             Use ${prog} -L for a list of valid category numbers.\n");
		exit (1);
	}
	prn_log ("Category $category meta-data selected. The following meta-data filters will be applied:\n\n");
    foreach $meta_file (keys %categories)
    {
	  prn_log "$meta_file\n";
    }
	prn_log "\n";
  }
  foreach $meta_file (@meta_files)
    {
	  if ($category and exists $categories{$meta_file})
	  {
          open(MTA, $dir. $SD . $meta_file) || 
		    die "$prog: Can't open meta-data file: $dir$SD$meta_file\n";
          @temp_array = <MTA>;
	      close (MTA);
	  }
	  elsif ($category == 0)
	  {
         open(MTA, $dir. $SD . $meta_file) || 
	    die "$prog: Can't open meta-data file: $dir$SD$meta_file\n";
         @temp_array = <MTA>;
      close (MTA);
	  }
	  else
	  {
		next;
	  }

	  my @meta_recs;

	  foreach $record (@temp_array)
		{
		  if ( $record !~ m/^#/ )
            { push @meta_recs, ($record);  }
		}

      prn_log ("Loading meta-data file: $dir$SD$meta_file\n");

	  foreach $record (@meta_recs)
		{
		   generate_csv($meta_file, $record, $full_version); 
		}
	  }
	}
  prn_log_ts("$prog: Done\n");
  close (LOG);

  if ( $out_dir ne '.' )
  {
	  copy ('awrcsv.log',$out_dir);
      open(LOG, ">> $logfile") or die "$prog: FATAL ERROR! Cannot write to file \"$logfile\"\n";
      prn_log ("\nINFO: Log \"awrcsv.log\" copied to \"$out_dir\"\n");
      close (LOG);
  }
