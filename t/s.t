# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use Test::More tests => 2;
BEGIN { $^W = 1 };
BEGIN { use_ok("Heap::Simple") };
BEGIN { use_ok('Benchmark') };

my $cachegrind = 0;
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

# Calibrate perl speed
my $calibrate = 5;
my $from = time;
print STDERR "\n";
mark();
print STDERR "Calibrating. Should take about $calibrate seconds\n";
1 while $from == time;
$from = $calibrate+time;
do {
    $i++ for 1..10000;
} while $from > time;
my $Size = int($i/$calibrate/24);
$Size =~ s/\B./0/g;

for my $string (0) {
    my $order = $string ? "lt" : "<";
    
    my $a_heap  = Heap::Simple->new(elements => ["Array"], order => $order);
    my $h_heap   = !$cachegrind && 
      Heap::Simple->new(elements => [Hash => "foo"], order => $order);
    my $num_heap = !$cachegrind && Heap::Simple->new(order => $order);
    my $f_heap   = !$cachegrind && eval '
          use Heap::Fibonacci; 
          use Heap::Elem::Num qw(NumElem); 
          use Heap::Elem::Str qw(StrElem);
          Heap::Fibonacci->new';
    my $b_heap = !$cachegrind && eval '
          use Heap::Binary; 
          use Heap::Elem::Num qw(NumElem); 
          use Heap::Elem::Str qw(StrElem);
          Heap::Binary->new';
    my $p_heap;
    eval 'use Heap::Priority; 
          $p_heap = Heap::Priority->new; 
          $p_heap->lowest_first' unless $cachegrind;

    my @array = map int(rand(2*$Size)), 1..$Size;
    # Only do few priority levels, or it's unfair to Heap::Priority
    my $pre = $string ? "A" : "";
    my @parray = map [$pre . $i++, $_%100], @array if $p_heap;
    if ($string) {
        $_ = "A$_" for @array;
    }
    my @harray;
    if ($f_heap || $b_heap) {
        if ($string) {
            @harray = map StrElem($_), @array if $f_heap || $b_heap;
        } else {
            @harray = map NumElem($_), @array;
        }
    }

    mark();
    report("insert of $Size elements into Heap::Fibonacci",
           $Size,
           sub { $f_heap->add($harray[$i++]) },
           ) if $f_heap;
    report("insert of $Size elements into Heap::Binary",
           $Size,
           sub { $b_heap->add($harray[$i++]) },
           ) if $b_heap;
    report("insert of $Size elements into Heap::Priority (100 levels)",
           $Size,
           sub { $p_heap->add(@{$parray[$i++]}) },
           ) if $p_heap;
    report("insert of $Size elements into Heap::Simple(order => '$order', Hash)",
           $Size,
           sub { $h_heap->insert({foo => $array[$i++]}) },
           ) if $h_heap;
    report("insert of $Size elements into Heap::Simple(order => '$order', Array)",
           $Size,
           sub { $a_heap->insert([$array[$i++]]) },
           ) if $a_heap;
    report("insert of $Size elements into Heap::Simple(order => '$order')",
           $Size,
           sub { $num_heap->insert($array[$i++]) },
           ) if $num_heap;

    mark();
    report("Extract $Size elements from Heap::Fibonacci",
           $Size,
           sub { $f_heap->extract_minimum },
           ) if $f_heap;
    report("Extract $Size elements from Heap::Binary",
           $Size,
           sub { $b_heap->extract_minimum },
           ) if $b_heap;
    report("Extract $Size elements from Heap::Priority (100 levels)",
           $Size,
           sub { $p_heap->pop },
           ) if $p_heap;
    report("Extract $Size elements from Heap::Simple(order => '$order', Hash)",
           $Size,
           sub { $h_heap->extract_min }
           ) if $h_heap;
    report("Extract $Size elements from Heap::Simple(order => '$order', Array)",
           $Size,
           sub { $a_heap->extract_min }
           ) if $a_heap;
    report("Extract $Size elements from Heap::Simple(order => '$order')",
           $Size,
           sub { $num_heap->extract_min }
           ) if $num_heap;
}
