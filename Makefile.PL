#! /usr/bin/perl -w
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $xs   = eval "use Heap::Simple::XS; 1";
my $perl = eval "use Heap::Simple::Perl; 1";

if ($xs) {
    print <<'EOT'

I will probably use 'Heap::Simple::XS' on your setup. Very good.
(the actual decission is deferred to runtime).

EOT
} elsif ($perl) {
    print <<'EOT'

I will probably use 'Heap::Simple::Perl' on your setup, which is perfectly fine
(the actual decission is deferred to runtime). You might consider also 
installing 'Heap::Simple::XS' though

EOT
} else {
    print <<'EOT'

You seem to have neither 'Heap::Simple::XS' nor 'Heap::Simple::Perl' installed.
That should not stop this package from getting installed (in fact, you'll need 
to install this package before you can install any of the other two).
However, this package won't be usable until you install one (or both) of these 
two.

EOT
}
WriteMakefile
    (NAME              => 'Heap::Simple',
     VERSION_FROM      => 'Simple.pm', # finds $VERSION
     PREREQ_PM         => {}, # e.g., Module::Name => 1.1
     ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Ton Hospel <Heap::Simple@ton.iguana.be>') : ()),
);
