# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use Test::More tests => 2;
BEGIN { $^W = 1 };
BEGIN { use_ok("Heap::Simple") };
BEGIN { use_ok('Benchmark') };

my $cachegrind = 0;
my $Size = $cachegrind ? 10000 : 50000;
my $i;

sub report {
    my($desc, $count, $sub) = @_;
    $i = 0;
    print STDERR "[[ timing ]] $desc\n";
    print STDERR timestr(timeit($count, $sub))."\n";
}

sub mark {
    print STDERR "------\n";
}

my $a_heap  = Heap::Simple->new(elements => ["Array"]);
my $h_heap   = !$cachegrind && Heap::Simple->new(elements => [Hash => "foo"]);
my $num_heap = !$cachegrind && Heap::Simple->new;
my $f_heap   = !$cachegrind &&
         eval 'use Heap::Fibonacci; use Heap::Elem::Num qw(NumElem); Heap::Fibonacci->new';
my $b_heap = !$cachegrind &&
        eval 'use Heap::Binary; use Heap::Elem::Num qw(NumElem); Heap::Binary->new';
my $p_heap;
eval 'use Heap::Priority; $p_heap = Heap::Priority->new; $p_heap->lowest_first' unless $cachegrind;

my @array = map int(rand(2*$Size)), 1..$Size;
my @harray = map NumElem($_), @array if $f_heap || $b_heap;
# Only do few priority levels, or it's unfair to the design of Heap::Priority
my @parray = map [$i++, $_%100], @array if $p_heap;

print STDERR "\n";
mark();
report("insert of $Size elementss into Heap::Fibonacci",
       $Size,
       sub { $f_heap->add($harray[$i++]) },
    ) if $f_heap;
report("insert of $Size elementss into Heap::Binary",
       $Size,
       sub { $b_heap->add($harray[$i++]) },
    ) if $b_heap;
report("insert of $Size elementss into Heap::Priority (100 levels)",
       $Size,
       sub { $p_heap->add(@{$parray[$i++]}) },
    ) if $p_heap;
report("insert of $Size elementss into Heap::Simple(Number, Hash)",
       $Size,
       sub { $h_heap->insert({foo => $array[$i++]}) },
    ) if $h_heap;
report("insert of $Size elementss into Heap::Simple(Number, Array)",
       $Size,
       sub { $a_heap->insert([$array[$i++]]) },
    ) if $a_heap;
report("insert of $Size elementss into Heap::Simple(Number)",
       $Size,
       sub { $num_heap->insert($array[$i++]) },
    ) if $num_heap;

mark();
report("Extract $Size elementss from Heap::Fibonacci",
       $Size,
       sub { $f_heap->extract_minimum },
    ) if $f_heap;
report("Extract $Size elementss from Heap::Binary",
       $Size,
       sub { $b_heap->extract_minimum },
    ) if $b_heap;
report("Extract $Size elementss from Heap::Priority (100 levels)",
       $Size,
       sub { $p_heap->pop },
    ) if $p_heap;
report("Extract $Size elementss from Heap::Simple(Number, Hash)",
    $Size,
    sub { $h_heap->extract_min }
) if $h_heap;
report("Extract $Size elementss from Heap::Simple(Number, Array)",
    $Size,
    sub { $a_heap->extract_min }
) if $a_heap;
report("Extract $Size elementss from Heap::Simple(Number)",
    $Size,
    sub { $num_heap->extract_min }
) if $num_heap;
