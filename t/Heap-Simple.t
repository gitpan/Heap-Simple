# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl A.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { 
    plan tests => 2;
    @Heap::Simple::implementors = qw(CGI);
}
use Heap::Simple;
ok(1); # We can load

my $cgi = Heap::Simple->new();
ok($cgi->isa("CGI"));
