use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Heap::Simple',
    'VERSION'		=> '0.06',
    'PREREQ_PM'		=> { 
        "Test::More" => 0.11,	# For the tests only
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Ton Hospel <Heap::Simple@ton.iguana.be>') : ()),
);
