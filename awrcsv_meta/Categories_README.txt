Meta-data Categories
====================
The meta-data files are split into categories (a few of which span
more than one category. You can select a category when running awrcsv.pl
by using the -C command modifier with a category number. 

Example:

awrcsv.pl -d awrdir -o csvfiles -C 1

In the example here we read AWR files from the directory "awrdir", the
output CSV files are written to the directory "csvfiles" and we have
elected to generate the Basic category of CSV files.

By default category 9 (Performance Report) is selected for you.

The meta-data categories are divided as follows:

0. Everything 
=============
No filtering

1. Basic:
=========
DB Time
Dictionary Cache Statistics
Foreground Wait Class Statistics
Instance CPU
Load Profile
Instance Efficiency Statistics
Library Cache Activity
Load Profile
Memory Statistics
Sessions
Top 5 Foreground Events
Sort / PGA Statistics

2: Host: 
========
Hardware 
Load Averages
OS Statistics
OS Statistics Detail

3. Statistics & Events:
=======================
Time Model Statistics
Cache Sizes
Dictionary Cache Stats
Foreground Wait Events
Background Wait Events
Instance Activity Statistics
Instance CPU
Service Wait Class Stats
Instance Redo Log Activity

4. SQL Statistics
=================
SQL by CPU
SQL by Elapsed
SQL by Executions
SQL by Gets
SQL by Parse Calls
SQL by Reads
SQL by Version Count

5. Buffers, enqueues & Latches
==============================
Buffer Wait Statistics
Enqueue Activity
Latch Activity
Latch Sleep Breakdown

6. IO & Segment Activity
========================
File IO Stats
Segment Activity
Report Tablespace IO Stats
Undo Tablespace Summary

7. Oracle Memory
==================
Cache Sizes
Dynamic Memory Components
Memory Resize Ops Summary
Memory Resize Ops
Process Memory Summary
SGA Memory Summary
SGA Breakdown

8. RAC
======
Dictionary Cache Stats RAC
Global Cache and Enqueue Services
Global Cache Efficiency Percentages
Global Cache Load Profile
Library Cache Activity RAC
Segment Activity RAC


9. Performance Report (Default Meta-data)
=========================================
CSV File focus on wrting a performance report:

Buffer Cache
Library Cache Activity
OS CPU Load Stats
Parsing
Reads Writes Per Sec
Redo Activity
Session Stats
Sort PGA Analysis
Table IO
Table IO Methods
Top 5 Timed Events
Tspace IO Stats
TX Throughput
Undo TS Summary
Time Model Statistics
Global Cache and Enqueue Services
Global Cache Efficiency Percentages

NOTE: You will need to supplement these with category 4. 

      Also during your investigation you may need to 
      branch off to other categories, depending upon
      your observations.


10. Reserved for Streams
========================

11. Reserved for Shared Server
==============================

>25. May be user defined.
=========================



Categories.mta Structure
========================

The format of a Categories records is:

Category_no:meta_data_file_name.mta

More than one meta-data file may belong to a category.

Category_no > 25 reserved for users to define their own categories.

Before each set of categories a category description record should be placed of 
the form:

#Category_no: category_desc_text.

For example:

#5: Buffers, Enqueues & Latches
5:Buffer_Wait_Statistics.mta
5:Enqueue_Activityt.mta
5:Latch_Sleep_Breakdown.mta

#6: IO & Segment Activity
6:Tspace_IO_Stats.mta
6:Segment_Activity.mta
6:Undo_TS_Summary.mt

Note: Some categories may not be applicable to some database releases. If a 
category file is missing for a release / RAC / non-RAC combination it is 
silently ignored.
