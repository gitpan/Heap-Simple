#!/usr/bin/perl -w
require 5.004;
use ExtUtils::MakeMaker;
BEGIN {
    @Heap::Simple::implementors = qw(CGI) unless @Heap::Simple::implementors;
}
WriteMakefile(
    'NAME'		=> 'Heap::Simple',
    'VERSION_FROM'	=> 'lib/Heap/Simple/Perl.pm',
    'PREREQ_PM'		=> { 
        "Heap::Simple"	=> 0.07,	# implementor switch
        "Test::More" => 0.11,		# For the tests only
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Ton Hospel <Heap::Simple@ton.iguana.be>') : ()),
);
