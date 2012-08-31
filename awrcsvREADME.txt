AWRCSV 1.12
===========
Description
===========
awrcsv.pl takes a collection of TEXT BASED (NOT HTML!) AWR / STATSPACK 
reports and uses meta-data entries stored in a meta-data directory to 
determine how to extract sections of data from each of the AWR files and 
produce CSV files for use with a spreadsheet application. The output records
are written in descending order of the sum of the field values. In most cases
this is desired for "Top N" type analysis.

The meta-data directory has sub-directories, the 1st level sub-directory
is based on RDBMS version numbers and the second level contains 2 folders
"rac_no" and "rac_yes".

The top level meta-data directory is by default named awrcsv_meta and
it's default location is the current working directory.
Meta-data files have a .mta file extension.

When awrcsv.pl is executed it builds a list of RDBMS versions based on the
AWR / STATSPACK files it is presented with. From this list it determines
which meta-data sub-directories are required. It then applies all the
meta-data files in the meta-data sub-directory to the AWR files matching
the respective database version. The actual names of the individual 
meta-data files are arbitrary, but it is strongly recommended that the names 
be kept consistent with thos listed when you issue the "awrcsv.pl -L" command 
to list CSV file categories.

The current version of AWRCSV is supplied with meta-data for the following
Oracle AWR / STATSPACK versions:

9.2  Single Instance STATSPACK
10.1 Single Instance 
10.2 Single Instance + RAC AWR
11.1 Single Instance + RAC AWR
11.2 Single Instance + RAC AWR

BAT File.
=========
A Windows BAT file, awrcsv.bat, has been supplied. This is supplied as a kind of 
template that you can copy and edit this to save a little time producing CSV files 
in a more organised fashion. This will create directories by CSV category, C1, C2, C3,
etc and place the output CSV files in their respective category directories. 
To use it rename the file extension from the supplied .BATT to .BAT and place leave it
in the folder where you unzip awrcsv. You then create an AWR sub-directory and drop you
text format AWR files into it before running the BAT file.

Excel Template
==============
An excel graphing template (SexyChart.crtx) has been supplied by a colleague (Andy 
MacPherson) which can be used to produce quite a nice looking graph. 
If you like it, you can save the chart template to the template chart location  in Excel 
pointed to by:   Design > Change Chart Type > Manage Templates

When you create a graph you can then in Excel generate a standard line graph and 
then use it via:  Design > Change Chart Type > Templates > <Template Name>.

To quote Andy:
"It’s just got a graduated background and thinner plot lines than the default, but makes 
it look like it’s been created with a pen and not a chubby wax crayon. J".

Thanks for the contribution Andy.

Requirements
============
To install, simply create a suitable folder directory and unzip the archive.
This will create a awrcsv_meta sub-directory which contains the meta-data
for the currently supported versions of Oracle. Also there will be a sql folder
containing utility SQL.In addition two Perl programs will be unpacked:

 awrcsv.pl  : Used to generate your spreadsheet files based on text AWR reports
 awrmeta.pl : Utility to report the contents of a specified meta-data file.

Unless there is a meta-data incompatabilty issue with the version of Oracle
that generated the AWR reports or you are developing meta-data for a new
version of Oracle or a previously undeveloped section of AWR, you probably
don't need to worry about awrmeta.pl.

Please note that before using awrcsv.pl and awrmeta.pl, you may 
need to edit the first line of each file, to reflect the location 
of your Perl interpeter. By default the loaction is assumed to be
/usr/bin/perl. This shouldn't be an issue for Windows users. These
tools were developed using 5.12 and so you should preferably be
using that of a later version. For UNIX / Linux installations you
will need to run the commands:

 tar -xvf awrcsv_unix.tar
 chmod 755 unix_setup.sh

You then need to run a command to set the rest of the file permissions and 
convert the meta-data files to UNIX / Linux format:

 ./unix_setup.sh

For Windows you need to ensure that you have a Perl interpreter installed.
A free interpreter can be obtained from http://www.activestate.com/ActivePerl.
For the free version select the "Community Edition" option.

Synopsis
========
Usage awrcsv.pl [ -f -c csv_pref -C category -o out_dir -I -L -m meta_dir
              -M meta-file -t meta-file -p prefix -s suffix ] | -h

 -f          : Perform field level data sanity checks

 -c csv_pref : Prefix The generated CSV file names are prefixed
               with csv_pref.
               NOTE: An underscore character is automatically
                     appended to pref_str before prefixing the.
                     CSV file name.

 -C category : Category defines what category of CSV files should
               be generated. This is based on the contents of the
               Categories.mta file in the meta-data root directory.
               Use -L to obtain a listing of category -> meta-data
               mappings.

               Without this option CSV files are generated based on
               category 9 (Performance Report) meta-data files 
               implemented for a relevant
               Oracle version / RAC (or non RAC) combination.

 -d awr_dir  : Directory where the AWR reports are located

 -I          : Ignore any Oracle errors (starting with "ORA-")
               contained in AWR files. Default behaviour is to skip
               such files and report that the file and the errors
               encountered in the file.
 -L          : Display the category -> meta-data file mappings
               associated with the -C option.

 -M meta-file: Run with only the specified meta-data file.
             : NOTE: If used with -t, the -t flag is ignored.

 -m meta_dir : Directory where awrcsv metadata is to be found

 -o out_dir  : Directory to output the CSV files to.

 -p prefix   : Process AWR report files which have this prefix

 -s suffix   : Process AWR report files which have this suffix

 -t meta-file: Test / Debug a soecified metadata file.
               E.g awrcsv.pl -t Load_profile.mta.

 -h          : Display help (this text)

NOTE: awr_dir defaults to the current working directory
      The location of meta_dir defaults to the current directory.
      The location of out_dir defaults to the current directory.
      File prefix and suffix are optional.
      File prefix defaults to "awr"
      File suffix defaults to "txt"

Getting Started
===============
You can use the supplied batch_awrrpt.sql to generate AWR reports
for spanning several days. This is located in the SQL folder. Run
as you would awrrpt.sql. The script prompts for a date, number of
days (going back from and including the date entered) and a format
which can be text or html. For the purpose of awrcsv.pl usage you 
need to specify text. This script has a couple of lines which need
to be commented in / out near the end depending on whether you are
running on Windows or UNIX. There are comments in the file itself
explaining this.

NOTE: There is also a batch_awrrpti.sql script. You may find this useful
      if you decide to export AWR data from a database for analysis 
      from the AWR repository on another database. After using the
      ?/rdbms/admin/awrextr.sql and rdbms/admin/awrload.sql scripts
      simply run batch_awrrpti.sql against the database where you
      have loaded your AWR data to.

The simplest way to use the tools is to create AWR and CSV directories 
in the directory where you installed awrcsv and copy AWR files for 
processing into the AWR folder. Remember to clear this folder before 
using the tool against a new set of AWR reports.

The CSV folder can be used to write CSV files out by specifying it in
conjunction with the -o flag. An example would be:

  awrcv.pl -d AWR -o CSV 

This assumes that your AWR file names all start with the string "awr" 
and have a suffix of "txt". If this is not the case you can use the
-p and -s flags respectively. For example assuming your reports are
all prefixed with the string "sp" and suffxed with ".text", you would
need to use the command:

  awrcv.pl -d AWR -o CSV -p sp -s text

Note you don't include the dot in the suffix - it is implicit. 

The syntax we have used so far will generate spreadsheet files which
are intended to produce CSV files where the focus is for use in writing 
a database performance report. There are, however, various categories
of CSV files which can be generated. These can be listed with the 
command:

  awrcsv.pl -L 

This lists the range of category numbers and what sections of AWR belong
to each category. For example the basic category (Category 1) includes:

"1: Basic:

    Top_5_Timed_Events.mta
    Load_Profile.mta
    Instance_Eff_Pct.mta
    Cache_Sizes.mta
    Sessions.mta
    Dictionary_Cache_Stats.mta
    Foreground_Wait_Class.mta
    Library_Cache_Activity.mta
    Instance_CPU.mta
    DBTime.mta
    Memory_Statistics.mta"

(NOTE: For an up to date list of category contents see the 
       Categories_README.txt in the awrcsv_meta directory).

In actual fact the categrories are expressed as the meta-data files 
used to generate the CSV files for each category. There are currently
9 categories. To make things more manageable you may wish to have
awrcsv.pl write out files to pre-created sub-directories within the CSV
directory. For example you might create sub-directories C1, C2, C3.. etc.
You could then generate CSV files by category as follwos:

  awrcv.pl -d AWR -o CSV\C1 -C 1

Here we are telling awrcsv.pl to generate CSV files for Category 1 into 
the (Windows) folder CSV\C1 located in the current working directory.

If you wish to focus on producing CSV files for a performance report, you
will also need to run against the category 4 (SQL Statistic) meta-data.
In addition you should run the sql_id_cmd_types.sql script (in the sql
directory) against the target instance. This will provide two files:

sql_id_cmd_types_excel.lst
sql_id_cmd_types.lst

The latter of these can be imported into a spreadsheet program, using a 
field delimiter of tilda (~). When you are analysing SQL performance
the output from these will help you to distinguish between PL/SQL 
and SQL commands in your analysis. 

If you don't have a copy of the sql_command_types.sql. You can use the
following sqlplus commands to at least obtain the spreadsheet data:

-------------------------- Cut Here ------------------------------------
spool sql_id_cmd_types_excel.lst
prompt sql_is~Command Type~Command Desc.~SQL Text (1st 200 Characters)
set head off feedback off pagesize 0 linesize 300
prompt sql_id~ Command Type~ Command Desc
select s.sql_id || '~'  || s.command_type || '~' || aa.name 
from dba_hist_sqltext s,
     audit_actions    aa
where aa.action(+) = s.command_type
/
spool off
-------------------------- Cut Here ------------------------------------

NOTE: That the audit_actions table may not include the MERGE statement.
      The command_type number for this is 189.

RAC and Database Versions
=========================
When awrcsv.pl is pointed towards a directory of AWR / STATSPACK reports,
it identifies the RDBMS versions and whether the reports are for RAC or non-RAC.
For RAC reports, reports for different instances may be mixed in the same directory,
in which case seperate sets of CSV files will be generated for each, each file prefixed
with the instance name. If awr reports are discovered for different database versions,
then similarly these are segregated into different CSV files, each of which has the 
version added in parentheses, just prior to the .csv file extension.

When searching for a version directory for the version specific meta-data, awrcsv first
looks for a directory which reflects the full version of the database (e.g. 10.2.0.4.0).
If such a directory is found, then the meta-data found below this is used. If this
directory is not found, awrcsv looks for a directory based on the base release (e.g. 
10.2). This allows finer granularity of control, if required, when mapping meta-data 
to AWR reports for a given version of Oracle. Generally, however, using the base version 
will suffice. As an example the current meta-data includes a 10.2 directory in addition
to a 10.2.0.5.0 directory. This is because there are subtle AWR format differences
between 10.2.0.5.0 and earcler 10.2 patchsets.

Capabilities
============
The awrcsv.pl tool works as follows:

Metadadata records include both "start regular expression" and "end regular expression" fields. 
These are used by awrcsv.pl to "snip" out a section (range of lines ) of each report. The 
awrcsv tool, unlike many pattern matching utilities, does not do "greedy" matching. It stops 
returning lines to the snipped report section as soon as it finds the first match to the provided 
"end regular expression". Also included in the meta-data file are the column positions of data 
decriptors / labels and the corresponding data values. These are extracted for each AWR file and 
joined together in comma separated format. Cells are included at the beginning (top 2 rows) to 
identify the AWR file names and snapshot date / times that correspond to the data values below.

Key features include:  

1 Code independent extensibility due to the meta-data architecture. This makes
  the awrcsv.pl tool independent of Oracle AWR (or STATSPACK) version, since new meta-data files
  can be modified or added for new versions of Oracle.
2 Ability to map data descriptors (data label)for an AWR report to data values on the same line.
3 Ability to map data descriptors for an AWR report to data values on a line 
  which appears one or more lines after the data descriptor line. 
4 The (implicit) ability to account for repeated headings due to page breaks in large sections of
  an AWR report.
5 Optional additional filtering of the snipped report section using regexp pattern matching.
6 Extraction of composite field data, i.e. of the form w/x/y/z/... where the '/' 
  delimits the digits w,y,y,z/.... 



AWRCSV meta-data FIles
======================

The awrcsv.pl meta-data files are text files used to define 
sections of an AWR / STATSPACK report and describe to awrcsv.pl how to process 
the data in those sections in order to produce spreadsheet compatible output.
Sets or meta-data files are located below a root meta-data directory, which by
default has the name "awrcsv_meta" and is by default expected to be in the
current working directory. The root directory has sub-directories which
reflect the RDBMS version (full version e.g. 10.2.0.2.0 or base version 10.2).
The awrcsv.pl program, when presented with an AWR file looks first of all for the 
full version directory. If this doesn't exist it looks for a base version directory. 
An error is returned if neither is found. Once found it then expects to find one of 
two further sub-directory which are used to obtain the meta-data based on whether 
the AWR report is produced from a RAC or non-RAC database instance. These directories 
are named "rac_yes" and "rac_no" respectively. This allows the configuration of meta-data
which is for various combinations of database versions and whether ot not we are
expecting RAC specific sections in the reports. The use of meta-data also future-proofs
the awrcsv.pl code.

NOTE: Another tool, awrmeta.pl, is provided to report the contents of meta-data files.
      Use the -h flag for help with awrcsv.pl or awrmeta.pl

Generically the resulting CSV produced spreadsheet, conceptually, looks something like this:

+---------------+--------------+--------------+-------------+ ...
| Section Head  | Report File1 | Report File2 | Date-Time3  | ...
+---------------+--------------+--------------+-------------+ ...
| Metric Label  | Date-Time1   | Date-Time2   | Date-Time3  | ...
+---------------+--------------+--------------+-------------+ ...
| Metric1       | ValueC1      | ValueC3      | ValueC4     | ... 
+---------------+--------------+--------------+-------------+ ...
| Metric2       | ValueD1      | ValueD2      | ValueD4     | ...
+---------------+--------------+--------------+-------------+ ...
| Metric3       | ValueE1 ...
+---------------+-------- ...

The first line provides the file name where the data values in respective metric 
value columns below are sourced from. The second line allows us to correlate the 
Date / Time snapshot (end snaps) with their respective source files.
However the CSV is as you would expect, comma separated, so appears as:

Section Head, Report File1, Report File2, Date-Time3, ...
Metric Label, Date-Time1, Date-Time2, Date-Time3, ...
Metric1, ValueC1, ValueC3, ValueC4 , ... 
Metric2, ValueD1, ValueD2, ValueD4 , ...
Metric3, ValueE1 ...

A meta-data file can contain one or more records. One large meta-data 
file could be used to define all report requirements, but this would be more 
unwieldy from a maintenance and testing point of view. It would also
prevent CSV file generation by category. It is strongly recommended 
that each meta-data file be limited to a specific section of the report.
Also you should where possible adhere to the meta-data names listed in
the output from the command awrcsv.pl -L. 

Record Structure
================

The fields in a meta-data file are:

Field  1: The Report Section Heading (Spreadsheet Title) which appears in the 1st cell of the spreadsheet.
          The cells to the right of this cell are occupied by the AWR / STATSPACK file names
          from which the data in the respective columns below is sourced.

Field  2; The Data Heading label to be placed in the 1st column (2nd row) in the spreadsheet
          The cells to the right of this are occupied by the dates/times of the 
          snapshots (ascending) with the respective report metrics below.

Field  3; The base CSV output file name (without the .csv extension; 
          this is added automatically)

Field  4; The "start regular expression" to search for which defines the start point 
          (i.e. line) of the section snippet for which we wish to extract data from 
          in the report.

Field  5; The "end regular expression" to search for which defines the end point 
          (i.e. line) of the section snippet for which we wish to extract data from 
          in the report.

Field  6; An optional filter regexp which can be used to discard lines
          which do not match regexp after fields 3 and 4 have returned
          a range of lines.

Field  7; The starting character position for the data label (data description) in 
          the AWR report (1st character position is 1).

Field  8; The length of the data label in the AWR report. 

Field  9; The starting character position for the metric value field in 
          the AWR report.  NOTE: If field 10 is an empty empty string, 
          then this field is interpreted as the field number, the 1st
          field having a field number of 1.

Field 10: The length of the metric value field in the AWR report. If specified as 
          empty string then field 9 is interpreted as the field number rather than 
          its start position. 

Field 11: The shift count: Defines how many lines from the top 
          of the returned snippet to throw away (e.g. Title rows,
          underline rows, blank lines...)

Field 12; The pop count  : Defines how many lines from the bottom 
          of the returned snippet to throw away. 

NOTE: If the value of field 3 is repeated in ANY of the meta-data files, the CSV output produced is
      appended to the file contents produced for the previous occurrence of the file during the current 
      execution.


The following example shows a fairly basic mapping for the Load Profile section of AWR.
The meta-data fields are delimited by colon characters ":". 

This means that colon characters cannot be included in regexp patterns within the meta-data files.
Also care must be taken when trying to match charcters which may have a special meaning in the
context of a regexp.

The meta-data file can contain more than one record for the purposes of extracting data from the same 
section of AWR. For example consider the Load Profile section of an AWR:

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Load Profile
~~~~~~~~~~~~                            Per Second       Per Transaction
                                   ---------------       ---------------
                  Redo size:              6,872.62              2,963.35
              Logical reads:            496,399.83            214,038.68
              Block changes:                 55.99                 24.14
             Physical reads:                164.01                 70.72
            Physical writes:                  2.81                  1.21
                 User calls:                 40.60                 17.51
                     Parses:                 17.60                  7.59
                Hard parses:                  0.29                  0.13
                      Sorts:                  8.44                  3.64
                     Logons:                  0.15                  0.06
                   Executes:                295.59                127.46
               Transactions:                  2.32

  % Blocks changed per Read:    0.01    Recursive Call %:    95.69

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Mapping Using the Data Field Column Position
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Using the data column position / data length method to map these records we might use:

Load Profile (Per Sec):Load Metric:load_profile-per_sec:Load Profile: % Blocks changed per Read::1:27:36:15:3:2
Load Profile (Per Trans):Load Metric:load_profile-per_tx:Load Profile: % Blocks changed per Read::1:27:58:15:3:3

So breaking down the 1st of these records: 

The 1st field value, "Load Profile (Per Sec)" is used to populate the 1st cell 
of the generated spreadsheet. It is effectively the spreadsheet title.

The 2nd field value, "Load Metric" is used to populate the header cell of the 1st column of the spreadsheet. That is
to say it is the header for the data label entries which will appear below it.

The 3rd field value, "load_profile_per_sec" is used to form the .csv file name.

The 4th field value, "Load Profile" is the start search pattern match.

The 5th field value, " % Blocks changed per Read" is the end search pattern match.

The 6th field value in this example is empty as we don't wish to filter any data.

The 7th and 8th field values, 1 and 27 tell awrcsv.pl the start position and length of the label data.

The 9th and 10th field values, 36 and 15 tell awrcsv.pl the position the data starts and its length.

The 11th and 12th fields tell awrcsv.pl to discard the 1st 3 and last 2 lines of the snippet returned by
the range of lines returned by using the sexpesions in fields 4 and 5.

NOTE: In this example the second line has a "pop count" of 3. This is because The Load Profile (Per Trans) 
side of the Load Profile section has one less field than the (Per Sec)

Note also that we don't have a "Transactions" entry for the "Per Transaction column as this would be meaningless. 
We need however to tell awrcsv.pl to throw away the Transactions line for the (Per Trans) processing.
Without taking this into account the following error message is printed:

================================================================================
Processing "Top 5 Timed Events [Waits]" data
WARNING[4]: Possible incorrect meta-data entry "Top 5 Timed Events [Waits]" found!
            Record being processed is shorter than "data"
            column defined start pos! (32)
Record in error -> [Global Cache Load Profile]
Skipping this row!
================================================================================

The square brackets "[]" are added by awrcsv.pl to delimit the record contents.

Mapping Using Field Numbering Method
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If we were to use the "field number" method to map the data values, then we would use something like:

Load Profile (Per Sec):Load Metric:load_profile-per_sec:Load Profile: % Blocks changed per Read::1:27:2::3:2
Load Profile (Per Trans):Load Metric:load_profile-per_tx:Load Profile: % Blocks changed per Read::1:27:3::3:3

So instead of specifying the column number where the data starts, we indicate the respective field numbers 
of 2 and 3 for the data. This is because we have specified the data length fields to be empty. The label field is assumed to
be field 1. Following the label field, data fields are assumed to have 1 or more spaces prior to and after each field,
excepting the last field which may have zero spaces following it. Looking at the first few records from the example section:

Load Profile
~~~~~~~~~~~~                            Per Second       Per Transaction
                                   ---------------       ---------------
                  Redo size:              6,872.62              2,963.35
<------- Field 1 ---------->              <Field2>              <Field3>
              Logical reads:            496,399.83            214,038.68
<------- Field 1 ---------->            <-Field2->            <-Field3->
            

The field number method has the advantage that it can account for very large data values which cause AWR to print values
larger than the fields expected length.

Special Cases
=============
The data position field (Field 9) may be included with a skip instruction, by prefixing it with 
"SM-" where M is positive integer (any value). This instructs awrcsv.pl to skip N lines from the 
line containing the label to get to the data line. This is useful for sections of the 
report with split lines. For example Tablespace IO statistics section:

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Tablespace IO Stats            DB/Inst: BOZDB/PBOZ01  Snaps: 12199-12200
-> ordered by IOs (Reads + Writes) desc

Tablespace
------------------------------
                 Av      Av     Av                       Av     Buffer Av Buf
         Reads Reads/s Rd(ms) Blks/Rd       Writes Writes/s      Waits Wt(ms)
-------------- ------- ------ ------- ------------ -------- ---------- ------
TSPACE01
       118,849     114  409.1     8.9        3,937        4        229  185.0
TSPACE02
         5,964       6  156.9     1.0       28,850       28      2,299   31.9
TSPACE03
        26,259      25   64.9     9.5          486        0        684    3.4
          -------------------------------------------------------------

File IO Stats                  DB/Inst:... (rest of report omitted)


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

In this case we need to map a label (i.e. the tablespace name TSPACE01) to
one of the the metrics on the following line, lets, say "Av Rd (ms). To do this
we might use a meta-data record like this:

Tablespace IO Stats:Avg Read Time (ms):tablespace_io_stats-avg_read_time:Tablespace IO Stats:File IO Stats::1:30:S1-24:6:8:3

Looking at the last few fields of this record: 

1:30:S1-24:6:8:3

These tell us that the label field starts at position 1 and is upto 30 characters long. The field contaiing S1-24, tells us 
that to get the start position of the field value we need to skip 1 line and go to character position 24. The next field tells 
us that the field is 6 characters long. The last two fields here are respectivley, the Shift Count and the Pop Count. 
NOTE: When you use the "skip lines" feature you must leave the filter regexp field blank (field 6). 

NOTE: If field 10 is an empty string (see field descriptions) then the integer after the dash represents the field number within 
the line. So referencing this same field by field number we would use:

Tablespace IO Stats:Avg Read Time (ms):tablespace_io_stats-avg_read_time:Tablespace IO Stats:File IO Stats::1:30:S1-3::8:3


There is also another format which allows subfields to be printed. By subfields we mean a field which is broken down
into a number of delimited values. For example under Undo Segment Summary in an Oracle 10.2 
AWR report we might see something like:


Undo   Num Undo       Number of  Max Qry   Max Tx Min/Max   STO/     uS/uR/uU/
 TS# Blocks (K)    Transactions  Len (s) Concurcy TR (mins) OOS      eS/eR/eU
---- ---------- --------------- -------- -------- --------- ----- --------------
   1        3.3           3,667    1,554       15           0/0   0/0/0/0/0/0
          -------------------------------------------------------------

Here STO (Snapshot Too Old) and OOS (Out of Space) are combined. Obviously extracting this field as a whole 
is not useful since we can't readily graph the reulting field. We need to break these subfields out. To
do this we would use a data column position of the form N-DX. The N gives the position of the whole field, the D 
is the delimiter character (in this case "/") and rhe X is the subfield number of interest. So:

61-/1  - Maps to STO
61-/2  - Maps to OOS

The SM- and N-DX techniques can be combined if required, resulting in a format like: SM-N-DX, though so far AWR report
structures don't require this. Please remember that you still need to ensure that you correctly specify the length of 
the composite field (meta-data field 10) when using subfield expressions.

Modifying Data Labels
=====================
Up to now we have seen the simplest method to generate a CSV file, which  is to bucket similar metrics (same denomination) 
together in the same CSV file. So for example, we might generate a CSV file which only contains statistics 
expressed as a rate, (e.g. "per Second") and another CSV file which contains only totals. In these cases we simply use 
field 1 or field 2 to include a description of the data denomination being processed. However, if we wish to mix the 
denomination of statistics in the same CSV file, life becomes a bit confusing when interpreting the data. 
Consider the case where we wish to mix "per Second" statistics with "Total" statistics. We need a way to tag extra text 
at the end of the dynamically  generated labels, which are plucked from the AWR files. To do this we add the static text 
we want appending within field 2. The static text must be separated from the main field 2 text using a pipe as we see here: 

Sort Statistic:Sorts|[Total]:pga_management:Instance Activity Stats:Instance Activity Stats - Absolute Values:sorts:1:32:34:18:4:3
Sort Statistic:Sorts|[per Second]:pga_management:Instance Activity Stats:Instance Activity Stats - Absolute Values:sorts:1:32:53:14:4:3

When the CSV file is generated the strings "[Total]" and "[per Second]" are appended to the label text as we see here:

Sort Statistic          ,24-Feb-10 10:31:06,24-Feb-10 11:00:16,24-Feb-10 11:16:04
sorts (rows) [Total]    , 11579369         , 11053259         , 13645768  
sorts (memory) [Total]  , 158139           ,   31596          ,    67688
sorts (disk) [Total]    , 0                ,        0         ,        0
sorts (rows) [Per Sec]  , 13064.3          ,  12937.5         ,  14388.1
sorts (memory) [Per Sec], 178.4            ,    37.0          ,     71.4
sorts (disk) [Per Sec]  , 0.0              ,      0.0         ,      0.0


Testing meta-data Files
=======================
It is sometimes useful when developing a meta-data file files to use the -t option. For example:

awrcsv.pl -d AWR -t Report_Parsing.mta

This produces output similar to:
<---------------------------------------------------------------------------------->
Sat Nov 19 14:42:41 2011: awrcsv.pl: Vers: 1.9

Sat Nov 19 14:42:41 2011: awrcsv.pl: Started

Scanning 1 AWR / STATSPACK reports...
Loading meta-data file: ..\awrcsv_meta\10.2\rac_no\Report_Parsing.mta
Metadata parameters retrieved for Report_Parsing.mta:

           Title Heading : Time Model Parse Stats - Times [Seconds]
           Label Heading : Statistic Name
           Base CSV File : parse_times.csv
     Start search string : Time Model Statistics
       End search string : Wait Class
Match pattern (optional) : parse
    Label start position : 1
            Label length : 42

     Data start position : 44
             Data length : 18

             Shift count : 8
               Pop count : 3

Applying meta-data to AWR / STATSPACK file: awr_20100224_1015_1030.txt

   Start String: "Time Model Statistics"
     End String: "Wait Class"

Snippet based on Start and End search strings:
**********************************************************************************
Time Model Statistics          DB/Inst: PWWSEV01/PWWSEV01  Snaps: 12193-12194
-> Total time in database user-calls (DB Time): 29152.9s
-> Statistics including the word "background" measure background process
   time, and so do not contribute to the DB time statistic
-> Ordered by % or DB time desc, Statistic name

Statistic Name                                       Time (s) % of DB Time
------------------------------------------ ------------------ ------------
sql execute elapsed time                             24,765.1         84.9
DB CPU                                                3,948.8         13.5
parse time elapsed                                      438.7          1.5
hard parse elapsed time                                 356.5          1.2
connection management call elapsed time                  51.7           .2
failed parse elapsed time                                 1.6           .0
sequence load elapsed time                                1.6           .0
PL/SQL execution elapsed time                             0.5           .0
repeated bind elapsed time                                0.1           .0
hard parse (sharing criteria) elapsed time                0.0           .0
DB time                                              29,152.9          N/A
background elapsed time                               4,367.6          N/A
background cpu time                                     100.7          N/A
          -------------------------------------------------------------

Wait Class                      DB/Inst: PWWSEV01/PWWSEV01  Snaps: 12193-12194
**********************************************************************************

Snippet after applying Shift(8) Pop(3) values:
**********************************************************************************
sql execute elapsed time                             24,765.1         84.9
DB CPU                                                3,948.8         13.5
parse time elapsed                                      438.7          1.5
hard parse elapsed time                                 356.5          1.2
connection management call elapsed time                  51.7           .2
failed parse elapsed time                                 1.6           .0
sequence load elapsed time                                1.6           .0
PL/SQL execution elapsed time                             0.5           .0
repeated bind elapsed time                                0.1           .0
hard parse (sharing criteria) elapsed time                0.0           .0
DB time                                              29,152.9          N/A
background elapsed time                               4,367.6          N/A
background cpu time                                     100.7          N/A
**********************************************************************************

Applying filter (regexp): "parse":
**********************************************************************************
parse time elapsed                                      438.7          1.5
hard parse elapsed time                                 356.5          1.2
failed parse elapsed time                                 1.6           .0
hard parse (sharing criteria) elapsed time                0.0           .0
**********************************************************************************

Processing extracted label / data RECORD:
**********************************************************************************
parse time elapsed                                      438.7          1.5
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
parse time elapsed                         ,             438.7
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - Times [Seconds]"...
Sanity check completed OK


Processing extracted label / data RECORD:
**********************************************************************************
hard parse elapsed time                                 356.5          1.2
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
hard parse elapsed time                    ,             356.5
parse time elapsed                         ,             438.7
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - Times [Seconds]"...
Sanity check completed OK


Processing extracted label / data RECORD:
**********************************************************************************
failed parse elapsed time                                 1.6           .0
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
hard parse elapsed time                    ,             356.5
parse time elapsed                         ,             438.7
failed parse elapsed time                  ,               1.6
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - Times [Seconds]"...
Sanity check completed OK


Processing extracted label / data RECORD:
**********************************************************************************
hard parse (sharing criteria) elapsed time                0.0           .0
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
hard parse elapsed time                    ,             356.5
parse time elapsed                         ,             438.7
hard parse (sharing criteria) elapsed time ,               0.0
failed parse elapsed time                  ,               1.6
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - Times [Seconds]"...
Sanity check completed OK

Writing PWWSEV01_parse_times.csv

Metadata parameters retrieved for Report_Parsing.mta:

           Title Heading : Time Model Parse Stats - %DB Time
           Label Heading : Statistic Name
           Base CSV File : parse_pct_dbtime.csv
     Start search string : Time Model Statistics
       End search string : Wait Class
Match pattern (optional) : parse
    Label start position : 1
            Label length : 42

     Data start position : 71
             Data length : 12

             Shift count : 8
               Pop count : 3

Applying meta-data to AWR / STATSPACK file: awr_20100224_1015_1030.txt

   Start String: "Time Model Statistics"
     End String: "Wait Class"

Snippet based on Start and End search strings:
**********************************************************************************
Time Model Statistics          DB/Inst: PWWSEV01/PWWSEV01  Snaps: 12193-12194
-> Total time in database user-calls (DB Time): 29152.9s
-> Statistics including the word "background" measure background process
   time, and so do not contribute to the DB time statistic
-> Ordered by % or DB time desc, Statistic name

Statistic Name                                       Time (s) % of DB Time
------------------------------------------ ------------------ ------------
sql execute elapsed time                             24,765.1         84.9
DB CPU                                                3,948.8         13.5
parse time elapsed                                      438.7          1.5
hard parse elapsed time                                 356.5          1.2
connection management call elapsed time                  51.7           .2
failed parse elapsed time                                 1.6           .0
sequence load elapsed time                                1.6           .0
PL/SQL execution elapsed time                             0.5           .0
repeated bind elapsed time                                0.1           .0
hard parse (sharing criteria) elapsed time                0.0           .0
DB time                                              29,152.9          N/A
background elapsed time                               4,367.6          N/A
background cpu time                                     100.7          N/A
          -------------------------------------------------------------

Wait Class                      DB/Inst: PWWSEV01/PWWSEV01  Snaps: 12193-12194
**********************************************************************************

Snippet after applying Shift(8) Pop(3) values:
**********************************************************************************
sql execute elapsed time                             24,765.1         84.9
DB CPU                                                3,948.8         13.5
parse time elapsed                                      438.7          1.5
hard parse elapsed time                                 356.5          1.2
connection management call elapsed time                  51.7           .2
failed parse elapsed time                                 1.6           .0
sequence load elapsed time                                1.6           .0
PL/SQL execution elapsed time                             0.5           .0
repeated bind elapsed time                                0.1           .0
hard parse (sharing criteria) elapsed time                0.0           .0
DB time                                              29,152.9          N/A
background elapsed time                               4,367.6          N/A
background cpu time                                     100.7          N/A
**********************************************************************************

Applying filter (regexp): "parse":
**********************************************************************************
parse time elapsed                                      438.7          1.5
hard parse elapsed time                                 356.5          1.2
failed parse elapsed time                                 1.6           .0
hard parse (sharing criteria) elapsed time                0.0           .0
**********************************************************************************

Processing extracted label / data RECORD:
**********************************************************************************
parse time elapsed                                      438.7          1.5
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
parse time elapsed                         , 1.5
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - %DB Time"...
Sanity check completed OK


Processing extracted label / data RECORD:
**********************************************************************************
hard parse elapsed time                                 356.5          1.2
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
hard parse elapsed time                    , 1.2
parse time elapsed                         , 1.5
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - %DB Time"...
Sanity check completed OK


Processing extracted label / data RECORD:
**********************************************************************************
failed parse elapsed time                                 1.6           .0
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
hard parse elapsed time                    , 1.2
parse time elapsed                         , 1.5
failed parse elapsed time                  ,  .0
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - %DB Time"...
Sanity check completed OK


Processing extracted label / data RECORD:
**********************************************************************************
hard parse (sharing criteria) elapsed time                0.0           .0
**********************************************************************************

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
hard parse elapsed time                    , 1.2
parse time elapsed                         , 1.5
hard parse (sharing criteria) elapsed time ,  .0
failed parse elapsed time                  ,  .0
**********************************************************************************
Performing Sanity check for meta-data entry  "Time Model Parse Stats - %DB Time"...
Sanity check completed OK

Writing PWWSEV01_parse_pct_dbtime.csv

Sat Nov 19 14:42:41 2011: awrcsv.pl: Done
<---------------------------------------------------------------------------------->

Going through the section headings.

"Snippet based on Start and End search strings:"
This first part of this output show the effect of the regular expression search and
if used the regular expression pattern match.

We can see from the application of the Start and End regular expression whether we
are plucking out the expected range of lines from the AWR report. If the regexp
strings do not work as expected then we could have problems with a run-away range
of lines or no lines at all!

"Snippet after applying Shift(8) Pop(3) values:"
This section gives us a view of what the data looks like after applying the Shift and
Pop values to the initial report snippet. In this case the values are 8 & 3, resulting
in the Top 8 lines and bottom 3 lines of the original report snippet being discarded.

"Applying filter (regexp): "parse":"
If a filter match pattern has been supplied in the meta-data entry, this section
will show how it reduced the snippet further.

The next repeated phases show record by record examples of the snippet being processed
and converted into label & data pairs delimited by commas. The section shown as:

Converting & adding record into comma delimited label / data COLUMNS results set:
**********************************************************************************
hard parse elapsed time                    ,             356.5
parse time elapsed                         ,             438.7
hard parse (sharing criteria) elapsed time ,               0.0
failed parse elapsed time                  ,               1.6
**********************************************************************************

represents an example of what has been extracted from 1 AWR report. The equivalent
sections from other reports will be joined to this to form our spreadsheet.

When using the "-t" option it is best to use only 1 (at most 2) AWR / STATSPACK reports to
test against. To this end it is best to point awrcsv.pl at a directory containing only 1
AWR report.

Diagnosing Problems
===================
If there are problems with processing AWR STATSPACK reports these are usually due to 
incorrect mapping specifications in one of the meta-data files or a bug on the AWR 
format. These are normally detected at run-time and an error will be reported:
--------------------------------------------------------------------------------------
Processing "Top 5 Timed Events [Time (s)] / Event Name" for 10.2.0.5.0 data
Writing PROLB_top_5_timed_events-time.csv

"Loading meta-data file: awrcsv_meta\10.2.0.5.0\rac_no\Top_5_Timed_Events.mta
Processing "Top 5 Timed Events [Waits] / Event Name" for 10.2.0.5.0 data
Writing PROLB_top_5_timed_events-waits.csv

Processing "Top 5 Timed Events [Time (s)] / Event Name" for 10.2.0.5.0 data
Writing PROLB_top_5_timed_events-time.csv

ERROR: Suspicious record format(1) detected for file PROLB_top_5_timed_events-time.csv
Record in ERROR: log file sync                  ,      1055,        930,      
1235,        952,      1078,      1137,      1 102,      1254,      1002,      
1022,      1091,      1168

    See <ERROR>:log file sync                  ,      1055,        930,      
1235,        952,      1078,      1137,      <HERE>,      1254,      1002,      
1022,      1091,      1168
Check meta-data file: Top_5_Timed_Events.mta and check the AWR reports."
--------------------------------------------------------------------------------------
Two versions of the CSV record are displayed, the second includes the string <HERE> to 
indicate where the error was spotted. A more succinct diagnostic can be obtained by
running with the -f (force field level sanity checks) or alternatively use the -M option
to test the Meta-data file. 

For example using the -f option for a bad meta-data entry:
--------------------------------------------------------------------------------------
awrcsv.pl  -d AWR -f -M Report_Parsing.mta
Sat Nov 19 15:16:50 2011: awrcsv.pl: Vers: 1.9

Sat Nov 19 15:16:50 2011: awrcsv.pl: Started

Including field level sanity checks...
Scanning 1 AWR / STATSPACK reports...
Loading meta-data file: awrcsv_meta\10.2\rac_no\Report_Parsing.mta
Processing "Time Model Parse Stats - Times [Seconds] / Statistic Name" for 10.2.0.4.0 data
ERROR: Non-numeric found where a number was expected applying meta-data entry "T
ime Model Parse Stats - Times [Seconds]"
Element looks like: "psed time                0.0"
Ensure the meta-data file entry matches the AWR report format.
ERROR occurred processing AWR file: awr_20100224_1015_1030.txt.
--------------------------------------------------------------------------------------
So we can see that the data field is not a number field as we sould hope. 
In this case the meta-data entry is incorrect causing the end of a previous (label)
field to be pre-pended to the field that we are trying to process.

Remember also to use the -t option as described in the last section. This usually
allows you to spot irregularities.
