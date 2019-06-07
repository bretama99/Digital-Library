###########################################################################
#
# Code by Xin Gao based on the Ogg::Vorbis::Header::PurePerl module by
#   Andrew Molloy (GNU General Public Licensed)
#
# A component of the Greenstone digital library software
# from the New Zealand Digital Library Project at the 
# University of Waikato, New Zealand.
#
# Copyright (C) 2005 New Zealand Digital Library Project
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
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
###########################################################################

package rm::Header::PurePerl;

use 5.005;
use strict;
use warnings;

use Fcntl qw/SEEK_END/;

our $VERSION = '0.07';

sub new 
{
    my $class = shift;
    my $file = shift;

    return load($class, $file);
}

sub load 
{
    my $class    = shift;
    my $file     = shift;
    my $from_new = shift;
    my %data;
    my $self;

    # there must be a better way...
    if ($class eq 'rm::Header::PurePerl')
    {
	$self = bless \%data, $class;
    }
    else
    {
	$self = $class;
    }

    if ($self->{'FILE_LOADED'})
    {
	return $self;
    }

    $self->{'FILE_LOADED'} = 1;

    # check that the file exists and is readable
    unless ( -e $file && -r _ )
    {
	warn "File does not exist or cannot be read.";
	# file does not exist, can't do anything
	return undef;
    }
    # open up the file
    open FILE, $file;
    # make sure dos-type systems can handle it...
    binmode FILE;

    $data{'filename'} = $file;
    $data{'fileHandle'} = \*FILE;

    _loadInfo(\%data);

    close FILE;

    return $self;
}

sub info 
{
    my $self = shift;
    my $key = shift;

    # if the user did not supply a key, return the entire hash
    unless ($key)
    {
	return $self->{'INFO'};
    }

    # otherwise, return the value for the given key
    return $self->{'INFO'}{lc $key};
}

sub _loadInfo
{
    my $data = shift;
    my $start = 0;
    my $fh = $data->{'fileHandle'};
    my $buffer;
    my $byteCount = $start;
    my %info;
    
    # check that the first four bytes are '.RMF'
    read($fh, $buffer, 4);
    if ($buffer ne '.RMF')
    {
	warn "No RMF header?";
	return undef;
    }

$buffer='';
my $char;

#find the header
my $bytes = "DATA";
my @byteList = split //, $bytes;
my $numBytes = @byteList;
my $i;

LINE:   while (1){
  INNER:  for ($i = 0; $i < $numBytes; $i ++)
    {
  unless ( read($fh, $char, 1) ) {last LINE ;}
	# Find out all of char
	$buffer= $buffer.$char;  

if (ord($char) !=  ord($byteList[$i]) ) 
{last  INNER ;}
    }
if ($i == $numBytes) {last LINE ;} #jump out the while loop
        }

#find the tail
 $bytes = "INDX";
 @byteList = split //, $bytes;
 $numBytes = @byteList;

my $isrecord=0;
LINE:  while (read($fh, $char, 1)){
   if ($isrecord) {
	# Find out all of char
	$buffer= $buffer.$char;  
   }else
        {
         INNER:  for ($i = 0; $i < $numBytes; $i ++)
                     {
                      if (ord($char) !=  ord($byteList[$i]) ) {last  INNER ;}
                      unless ( read($fh, $char, 1) ) {last LINE ;}
                     }
if ($i == $numBytes) {$isrecord = 1;} #start record
        }
       }

my @cliptype = (

#add clip type here
"Comments",
"Keywords",
"Category",
"MimeType",# title
"Lyrics",
"Artist",
"CD Track #",
"Album",
"Extension",
"Genre",
"Statistics",
"PROP",
"MDPR",
"Target Audiences",
"Audio Format",
"Creation Date",
"Modification Date",
"Generated By",
"Abstract",
"Content Rating",
"File ID",
"CONT",
"Audio Stream",
"Video Stream",
"Title"
);

for my $j ( 1 .. scalar(@cliptype) ) {
$info{$cliptype[$j - 1]} = _loadInfor($buffer,$cliptype[$j - 1]);
}

    $data->{'INFO'} = \%info;
}

#search for the element name and value
sub _loadInfor
{my $data = shift;
my $item = shift;

my @byteList = split //, $data;
my $startbyte = 0;


my $isrecord;
my $data2 = "";
my $char;
my $item2 = "";
if ( $item eq "Title") {$item2 = $item; $item = "MimeType";}


OUT: while(index($data, $item, $startbyte) != -1){
$startbyte = index($data, $item, $startbyte);
$isrecord=0;

$startbyte += length($item);

if(ord($byteList[$startbyte]) == 0 or ord($byteList[$startbyte]) == 0x14){
  if ( $item eq "Album" or $item eq "Artist" or $item2 eq "Title"){
     if ( index($data,"Name",$startbyte) != -1) {
     $startbyte = index($data,"Name",$startbyte);
     $startbyte += length("Name");
     }else {next OUT;}
}

  if ($data2 ne "") {$data2 = $data2."; ";}

LINE:   while (1){
        $char = $byteList[++$startbyte];

	if (ord($char) >= 32 and ord($char) <= 126)
	{
        $isrecord=1; #record the string started
	$data2 = $data2.$char;  
	}else{
             if ( $isrecord == 1 ) {last LINE ;}# stop at the end of string
             }
        }# end LINE: while

 }# end if 
}# end while

return $data2;
}

1;
