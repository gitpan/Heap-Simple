# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use Test::More tests => 2;
BEGIN { $^W = 1 };
BEGIN { use_ok("Heap::Simple") };
BEGIN { use_ok('Benchmark') };

my $cachegrind = 0;
my $simple_only = 0;
# Don't use insanely much memory even on very fast computers
my $max_size = 1e6;
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

my $f_heap   = !$simple_only && !$cachegrind && eval '
          use Heap::Fibonacci;
          use Heap::Elem::Num qw(NumElem);
          use Heap::Elem::Str qw(StrElem);
          1';
my $b_heap = !$simple_only && !$cachegrind && eval '
          use Heap::Binary;
          use Heap::Elem::Num qw(NumElem);
          use Heap::Elem::Str qw(StrElem);
          1';
my $p_heap = !$simple_only && !$cachegrind && eval '
          use Heap::Priority;
          1';

print STDERR "\n";
my $size;
my $calibrate = 5;
if ($cachegrind) {
    $size = 10000;
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
    $size = int($i/$calibrate/24);
    $size *= 5 if !$b_heap && !$f_heap && !$p_heap;
    $size =~ s/\B./0/g;
    $size = $max_size if $size > $max_size;
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

    my @array = map int(rand(2*$size)), 1..$size;
    # Only do few priority levels, or it's unfair to Heap::Priority
    my $levels = int sqrt $size;
    $levels =~ s/\B./0/g;
    my $pre = $string ? "A" : "";
    my @parray = map [$pre . $i++, $_%$levels], @array if $p_heap;
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
        report("insert of $size elements into Heap::Fibonacci",
               $size,
               sub { $f_heap->add($harray[$i++]) });
        report("Extract $size elements from Heap::Fibonacci",
               $size,
               sub { $f_heap->extract_minimum },
               );
    }
    if ($b_heap) {
        mark();
        report("insert of $size elements into Heap::Binary",
               $size,
               sub { $b_heap->add($harray[$i++]) });
        report("Extract $size elements from Heap::Binary",
               $size,
               sub { $b_heap->extract_minimum });
    }
    @harray = ();

    if ($p_heap) {
        mark();
        report("insert of $size elements into Heap::Priority ($levels levels)",
               $size,
               sub { $p_heap->add(@{$parray[$i++]}) });
        report("Extract $size elements from Heap::Priority ($levels levels)",
               $size,
               sub { $p_heap->pop });
    }
    @parray = ();

    if ($h_heap) {
        mark();
        report("insert of $size elements into Heap::Simple(order => '$order', Hash)",
               $size,
               sub { $h_heap->insert({foo => $array[$i++]}) });
        report("Extract $size elements from Heap::Simple(order => '$order', Hash)",
               $size,
               sub { $h_heap->extract_top });
    }
    if ($a_heap) {
        mark();
        report("insert of $size elements into Heap::Simple(order => '$order', Array)",
               $size,
               sub { $a_heap->insert([$array[$i++]]) });
        report("Extract $size elements from Heap::Simple(order => '$order', Array)",
               $size,
               sub { $a_heap->extract_top });
    }
    if ($num_heap) {
        mark();
        report("insert of $size elements into Heap::Simple(order => '$order')",
               $size,
               sub { $num_heap->insert($array[$i++]) });
        report("Extract $size elements from Heap::Simple(order => '$order')",
               $size,
               sub { $num_heap->extract_top } );
    }
    mark();
}
