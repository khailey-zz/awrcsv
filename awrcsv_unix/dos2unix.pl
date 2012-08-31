#!/usr/bin/perl -w
###############################################################################
#                                                                             #
#  Module: ACSDIAG dos2unix.pl                                                #
# Purpose: Convert line terminator on file(s) from DOS to UNIX                #
#                                                                             #
# Usage $prog [-d directory -f file -w ] | -h                                 #
#                                                                             #
#  -d directory : Convert the line/record terminators of all files in         #
#                 directory.                                                  #
#                                                                             #
#  -f file      : Convert the line/record terminators of the specified file.  #
#  -w           : Reverse the line conversion. That is convert from UNIX      #
#                  format to Windows / DOS                                    #
#                                                                             #
#  -h           : Display help (this text)                                    #
#                                                                             #
# By default $prog converts CR/LF record terminators (ala DOS) to LF          #
# terminators. The -w option can be used to convert in the opposite direction.#
# However care hould be taken not to use this option on files already in      #
# DOS format!                                                                 #
#                                                                             #
# Author              Date        Modification                                #
# ==================  ==========  ==========================================  #
# cbostock (Oracle)   06.09.2010  First cut.                                  #
# cbostock (Oracle)   01.12.2010  Mod to exclude binary files and directories #
#                                                                             #
###############################################################################
use Cwd "abs_path";
use File::Basename;
use File::Copy;
use Getopt::Std;
use File::Basename;
use strict;
my $tmp = '/tmp';
our $prog     = basename($0);
my $vers='1.1';
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

my (
      $conv_file
    , $conv_dir
    , $target_platform
   );

our (
      $opt_d
    , $opt_f
    , $opt_h
    , $opt_w
    );

$target_platform="UNIX";

sub disp_usage
{
  printf "Usage $prog [-d directory -f file -w ] | -h \n";
  print  "\n";
  print " -d directory     : Convert the line/record terminators of all files in directory\n";
  print " -f file          : Convert the line/record terminators of the specified file\n";
  print " -w               : Reverse the line conversion. That is convert from UNIX format to Windows / DOS\n";
  print " -h               : Display help (this text)\n";
  print  "\n";
  print "      By default $prog converts CR/LF record terminators (ala DOS) to LF terminators\n";
  print "      The -w option can be used to convert in the opposite direction. However care hould be";
  print "      taken not to use this option on files already in DOS format!";
}



$SD="\\" if($os  =~ /Win/i);
$SP=";" if($os   =~ /Win/i);

getopts('d:f:hw') or 
    die "\nInvalid options specified, use $prog -h.\n$prog: Deploying chute and bailing out!!!\n";

if(defined($opt_h))
{
  disp_usage();
  exit;
}

if(defined($opt_d))
{
  $conv_dir = $opt_d;
}

if(defined($opt_f))
{
  $conv_file = $opt_f;
}

if(defined($opt_w))
{
  $target_platform="DOS";
}


sub convert_dir
{
  my ($conv_dir, $target_platform) = @_;
  my @files = glob($conv_dir . $SD . '*');
  my $file;
  foreach $file (@files)
  {
    if ( -d  $file )
     { print "  Skipping directory: " . $conv_dir . $SD . $file . "\n";  }
    elsif ( -B $file )
     { print "Skipping binary file: " . $conv_dir . $SD . $file . "\n";  }
    elsif ( -f  $file )
     { convert_file($file, $target_platform); }
    else
     { print "         Cowardly on:  " . $conv_dir . $SD . $file . "\n";  }
  }
}

sub convert_file
{
  my ($file, $target_platform) = @_;

  print "Converting file: $file\n";
  my $bfile = basename($file);
  open (CNV, $file) or die "Failed to open $file for conversion\n";
  my @c_recs = <CNV>;
  close (CNV);
  open (DCNV,">",$tmp . $SD . $bfile) or 
                die "Cannot open $tmp " . $SD . $bfile . "\n";
  foreach my $rec (@c_recs)
    {
       if ( $target_platform eq 'DOS' )
       {
           $rec =~ s/\n/\r\n/;
       }
       else
       {
           $rec =~ s/\r\n/\n/;
       }
       print DCNV "$rec";
    }
  close (DCNV);
  # Delete the original file
  unlink ($file);
  # Replace with converted file
  move($tmp . $SD . $bfile, $file);
  print "File converted to $target_platform format\n";
}

print "Target platform: $target_platform\n";
if(defined($conv_dir))
{
  convert_dir($conv_dir, $target_platform);
}

if(defined($conv_file))
{
  convert_file($conv_file, $target_platform);
}
exit;
