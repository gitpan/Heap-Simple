# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use Test::More tests => 5461;
BEGIN { $^W = 1 };
BEGIN { use_ok("Heap::Simple") };

my ($index, $basic, $order, $eorder);
my @infinity = (1e300000, -1e300000, undef, "", undef, "ABCD");

sub order {
    return $_[0] > $_[1];
}

my $key_lookup;
sub lookup {
    $key_lookup ||= $_[0] || "a";
    return shift->{look};
}

{
    package Wombat;
    sub meth {
        $key_lookup ||= $_[0] || "a";;
        return shift->{method};
    }
}

sub check_empty {
    my $heap = shift;
    is($heap->count, 0, "Empty heap has count 0");
    is($heap->first, undef, "Empty heap gives undef");
    is($heap->first_key, undef, "First key returns undef on empty heap");
    my $expect = $heap->infinity;
    is($expect, $infinity[$eorder+1], "Still the infinity we set");
    my $val = eval { $heap->min_key };
    if (defined($expect)) {
        is($val, $expect, "Min key returns '$expect' on empty heap");
    } else {
        ok($@, "min_key should fail");
    }
}

sub make {
    my ($key, $value) = @_;
    if ($index) {
        if ($index =~ /[^\d-]/) {
            return bless {$index => $key, val => $value}, "Wombat";
        } else {
            return bless [$value, $key], "Wombat";
        }
    } elsif ($basic) {
        return $key;
    } else {
        return bless [$key, $value], "Wombat";
    }
}

sub value {
    my $heap  = shift;
    return map {
        if ($index) {
            if ($index =~ /[^\d-]/) {
                bless({$index => $_->[0], val => $_->[1]}, "Wombat");
            } else {
                bless([reverse @$_], "Wombat");
            }
        } elsif ($basic) {
            $_->[0];
        } else {
            bless($_, "Wombat");
        }
    } @_;
}

# Check equivalences
my $heap1 = Heap::Simple->new();
my $heap2 = Heap::Simple->new(elements => ["Key"]);
is(ref($heap1), ref($heap2), "Default is element type Key");
$heap2 = Heap::Simple->new(elements => "Key");
is(ref($heap1), ref($heap2), "Short form of Key");
$heap2 = Heap::Simple->new(order => "<");
is(ref($heap1), ref($heap2), "Default order is <");

$heap1 = Heap::Simple->new(elements => [Array => 0]);
$heap2 = Heap::Simple->new(elements => ["Array"]);
is(ref($heap1), ref($heap2), "Default is array index is 0");
$heap2 = Heap::Simple->new(elements => "Array");
is(ref($heap1), ref($heap2), "Short form of Array");

my @order = qw(< > lt gt);
for (-1..$#order) {
    my %order = (order => $_ == -1 ? \&order : $order[$_]);
    $order = $_ == -1 ? 1 : $_;
    $eorder = $_ == -1 ? @order : $order;
    for (
         [],
         [Array	=> 0],
         [Array	=> 1],
         [Hash	=> "baz"],
         [Method => "meth"],
         [Object => "meth"],
         [Function => \&lookup],
         [Any	=> \&lookup],
) {
        my %elements = @$_ ? (elements => $_) : ();
        my $key_insert = $_->[0] && ($_->[0] eq "Object" || $_->[0] eq "Any");
        $index = $_->[1];
        $index = "method" if $index && $index eq "meth";
        $index = "look" if ref($index);

        # new & user_data
        my $empty_heap = Heap::Simple->new(%order, %elements);

        is($empty_heap->infinity, $infinity[$eorder], "Right infinity");
        is($empty_heap->infinity($infinity[$eorder+1]), $infinity[$eorder],
           "infinity set returns old value");
        is($empty_heap->infinity, $infinity[$eorder+1], "Right infinity");
        
        isa_ok($empty_heap, "Heap::Simple", "new creates Heap::Simple");
        my @expect = qw(Heap::Simple::Number Heap::Simple::NumberReverse
                      Heap::Simple::String Heap::Simple::StringReverse
                      Heap::Simple::Less);
        for (0..$#expect) {
            if ($_ == $eorder) {
                isa_ok($empty_heap, $expect[$_], "right superclass");
            } else {
                ok(!$empty_heap->isa($expect[$_]), "not the wrong superclass");
            }
        }
        check_empty($empty_heap);
        is($empty_heap->user_data, undef, "Default userdata is undef");
        is($empty_heap->user_data("foo"), undef, "userdata set returns old value");
        is($empty_heap->user_data, "foo", "Userdata set works");
        check_empty($empty_heap);

        my $heap = Heap::Simple->new(%order, %elements, user_data => "bar");
        # Got the right default infinity
        is($heap->infinity($infinity[$eorder+1]), $infinity[$eorder],
           "infinity set returns old value");

        check_empty($heap);

        # We'll insert each entry as key with the follower as value
        my @keys = (14, 8, 1, -12, 16, 10, 15, -11, 13, 10, 9, -1);
        @keys = map "A$_", @keys if $order == 2 || $order == 3;
        $basic = $heap->isa("Heap::Simple::Key");

        # Do everything 2 times to see if looping screws things up
        for (1..2) {
            check_empty($heap);
            if ($heap->isa("Heap::Simple::Method")) {
                is($heap->key_method, "meth", "Key method meth");
            } else {
                my $fail = eval { $heap->key_method };
                ok($@, "There is no key_method");
            }
            if ($heap->isa("Heap::Simple::Function")) {
                is($heap->key_function, \&lookup, "Key function lookup");
            } else {
                my $fail = eval { $heap->key_function };
                ok($@, "There is no key_method");
            }
            if ($heap->isa("Heap::Simple::Hash")) {
                is($heap->key_name, $index, "Key is at position $index");
            } else {
                my $fail = eval { $heap->key_name };
                ok($@, "There is no key_name");
            }
            if ($heap->isa("Heap::Simple::Array")) {
                is($heap->key_index, $index || 0,
                   "Key is at position ".($index || 0));
            } else {
                my $fail = eval { $heap->key_index };
                ok($@, "There is no key_index");
            }
            # insert
            for my $i (1..@keys) {
                $heap->insert(make($keys[$i-1], $keys[$i]));
                is($heap->count, $i, "Count keeps up");
            }

            # extract_min
            my $ref = $heap->extract_min;
            isa_ok($ref, "Wombat", "bless survives storage") unless $basic;
            is($heap->count, @keys-1, "Count right after extract");
            @expect = value($heap, [-12, 16], [16, 10], ["A-1", undef], ["A9", "A-1"]);
            is_deeply($ref, $expect[$order], "We extract what we put in");
            $ref = eval { $empty_heap->extract_min };
            ok($@, "Extracting from empty heap dies");

            # extract_upto
            my @upto = qw(0 13.5 A0 A156);
            my @refs = $heap->extract_upto($upto[$order]);
            unless ($basic) {
                isa_ok($_, "Wombat", "bless survives storage") for @refs;
            }
            @expect =([value($heap, 
                             [-11,13],[15,-11],["A-11","A13"],["A8","A1"])], 
                      [value($heap,
                             [-1,undef],[14,8],["A-12","A16"],["A16","A10"])]);
            is_deeply(\@refs, [map $_->[$order], @expect]);
            is($heap->count, @keys-3);

            @upto = qw(9 10 A10 A13);
            @refs = $heap->extract_upto($upto[$order]);
            unless ($basic) {
                isa_ok($_, "Wombat", "bless survives storage") for @refs;
            }
            @expect = ([value($heap,
                              [1,-12],[13,10],["A1", "A-12"],["A15", "A-11"])],
                       [value($heap,
                              [8,  1],[10,9],["A10","A9"],["A14", "A8"])],
                       [value($heap,
                              [9, -1],[10,15],["A10","A15"],["A13", "A10"])]);
            is_deeply(\@refs, [map $_->[$order], @expect]);
            is($heap->count, @keys-6);

            @refs = $empty_heap->extract_upto(1e20);
            is(@refs, 0, "extract_upto on empty heap returns nothing");
            is($empty_heap->infinity, $infinity[$eorder+1], "Right infinity");

            # insert again for a bit of irregularity, but now use key_insert
            # if we have it.
            if ($key_insert) {
                my (@element, @key);
                for my $i (1..5) {
                    $element[$i] = make($keys[$i-1], $keys[$i]);
                    $key[$i] = $heap->key($element[$i]);
                }
                $key_lookup = 0;
                for my $i (1..5) {
                    $heap->key_insert($key[$i], $element[$i]);
                }
                is($key_lookup, 0, "Internals never looked up key");
            } else {
                ok(!$heap->can("key_insert"), 
                   "others don't even HAVE key_insert");
                print STDERR "\n$heap has key_insert\n" if $heap->can("key_insert");
                for my $i (1..5) {
                    $heap->insert(make($keys[$i-1], $keys[$i]));
                }
            }
            is($heap->count, @keys-1, "Count keeps up");

            # first
            $ref = $heap->first;
            isa_ok($ref, "Wombat", "bless survives storage") unless $basic;
            is($heap->count, @keys-1, "Count right after first unchanged");
            @expect = value($heap, [-12, 16], [16, 10], ["A-12", "A16"], ["A8", "A1"]);
            is_deeply($ref, $expect[$order], "right values found");
            # already checked on empty heap

            # first_key
            my $min = $heap->first_key;
            @expect = qw(-12 16 A-12 A8);
            is($min, $expect[$order], "Found first key");
            is($heap->count, @keys-1, "Count keeps up");
            # already checked on empty heap

            # min_key
            $min = eval { $heap->min_key };
            is($@, "", "min_key works");
            is($min, $expect[$order], "Found min key");
            is($heap->count, @keys-1, "Count keeps up");

            # key
            is($heap->key($heap->first), $heap->first_key, 
               "Recover key from element");

            # Check if we still have the right associated data
            is($heap->infinity, $infinity[$eorder+1], "Right infinity");
            is($heap->user_data, "bar", "user_data survived everything");

            # Now drop all values
            $heap->extract_min for 1..$heap->count;
            check_empty($heap);

            # Bigger stress test
            my $n = 5000;
            my @rand = map int(rand(1000)), 1..$n;
            my @sorted;
            my @s = $order == 0 ? (sort {$a <=> $b } @rand) :
                $order == 1 ? (sort {$b <=> $a } @rand) :
                    $order == 2 ? (sort {$a cmp $b } @rand) :
                        $order == 3 ? (sort {$b cmp $a } @rand) :
                            die "Unhandled order $order";
            $heap->insert(make($_, "foo")) for @rand;
            if ($index && $index =~ /[^\d-]/) {
                @sorted = map $heap->extract_min->{$index}, @rand;
            } elsif ($basic) {
                @sorted = map $heap->extract_min, @rand;
            } else {
                my $i = $index || 0;
                @sorted = map $heap->extract_min->[$i], @rand;
            }
            is_deeply(\@sorted, \@s, "insert/extract from heap is like sort");
        }
    }
    my $fail = eval { Heap::Simple->new(%order, elements => ["Hash"]) };
    ok($@, "missing key_name should fail");
}

