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

my $f_heap   = !$cachegrind && eval '
          use Heap::Fibonacci;
          use Heap::Elem::Num qw(NumElem);
          use Heap::Elem::Str qw(StrElem);
          1';
my $b_heap = !$cachegrind && eval '
          use Heap::Binary;
          use Heap::Elem::Num qw(NumElem);
          use Heap::Elem::Str qw(StrElem);
          1';
my $p_heap = !$cachegrind && eval '
          use Heap::Priority;
          1';

print STDERR "\n";
my $Size;
my $calibrate = 5;
if ($cachegrind) {
    $Size = 10000;
} else {
    # Calibrate perl speed
    my $from = time;
    mark();
    print STDERR "Calibrating. Should take about $calibrate seconds\n";
    1 while $from == time;
    $from = $calibrate+time;
    do {
        $i++ for 1..10000;
    } while $from > time;
    $Size = int($i/$calibrate/24);
    $Size *= 5 if !$b_heap && !$f_heap && !$p_heap;
    $Size =~ s/\B./0/g;
}

for my $string (0) {
    my $order = $string ? "lt" : "<";

    my $a_heap  = Heap::Simple->new(elements => ["Array"], order => $order);
    my $h_heap   = !$cachegrind &&
      Heap::Simple->new(elements => [Hash => "foo"], order => $order);
    my $num_heap = !$cachegrind && Heap::Simple->new(order => $order);
    $f_heap = Heap::Fibonacci->new if $f_heap;
    $b_heap = Heap::Binary->new    if $b_heap;
    if ($p_heap) {
        $p_heap = Heap::Priority->new;
        $p_heap->lowest_first;
    }

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

    if ($f_heap) {
        mark();
        report("insert of $Size elements into Heap::Fibonacci",
               $Size,
               sub { $f_heap->add($harray[$i++]) });
        report("Extract $Size elements from Heap::Fibonacci",
               $Size,
               sub { $f_heap->extract_minimum },
               );
    }
    if ($b_heap) {
        mark();
        report("insert of $Size elements into Heap::Binary",
               $Size,
               sub { $b_heap->add($harray[$i++]) });
        report("Extract $Size elements from Heap::Binary",
               $Size,
               sub { $b_heap->extract_minimum });
    }
    @harray = ();

    if ($p_heap) {
        mark();
        report("insert of $Size elements into Heap::Priority (100 levels)",
               $Size,
               sub { $p_heap->add(@{$parray[$i++]}) });
        report("Extract $Size elements from Heap::Priority (100 levels)",
               $Size,
               sub { $p_heap->pop });
    }
    @parray = ();

    if ($h_heap) {
        mark();
        report("insert of $Size elements into Heap::Simple(order => '$order', Hash)",
               $Size,
               sub { $h_heap->insert({foo => $array[$i++]}) });
        report("Extract $Size elements from Heap::Simple(order => '$order', Hash)",
               $Size,
               sub { $h_heap->extract_min });
    }
    if ($a_heap) {
        mark();
        report("insert of $Size elements into Heap::Simple(order => '$order', Array)",
               $Size,
               sub { $a_heap->insert([$array[$i++]]) });
        report("Extract $Size elements from Heap::Simple(order => '$order', Array)",
               $Size,
               sub { $a_heap->extract_min });
    }
    if ($num_heap) {
        mark();
        report("insert of $Size elements into Heap::Simple(order => '$order')",
               $Size,
               sub { $num_heap->insert($array[$i++]) });
        report("Extract $Size elements from Heap::Simple(order => '$order')",
               $Size,
               sub { $num_heap->extract_min } );
    }
    mark();
}
