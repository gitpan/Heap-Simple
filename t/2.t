# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use Test::More tests => 1315;
BEGIN { $^W = 1 };
BEGIN { use_ok("Heap::Simple") };

sub check_empty {
    my $heap = shift;
    is($heap->count, 0, "Empty heap has count 0");
    is($heap->first, undef, "Empty heap gives undef");
    is($heap->first_key, undef, "First key returns undef on empty heap");
    is($heap->min_key, 1e300000, "Min key returns +inf on empty heap") if
        $heap->isa("Heap::Simple::Number");
}

for my $string (0, 1) {
    my %order_options = !defined($string) ? () : 
        $string ? (order => "lt") : (order => "<");
    for (["Array"],
         ["Array", 0],
         ["Array", 1],
         ["Hash", "baz"]) {
        my $index = $_->[1];

        # new & user_data
        my $empty_heap = Heap::Simple->new(%order_options, elements => $_);
        isa_ok($empty_heap, "Heap::Simple", "new creates Heap::Simple");
        check_empty($empty_heap);
        is($empty_heap->user_data, undef, "Default userdata is undef");
        is($empty_heap->user_data("foo"), undef, "userdata set returns old value");
        is($empty_heap->user_data, "foo", "Userdata set works");
        check_empty($empty_heap);

        my $heap = Heap::Simple->new(%order_options, 
                                     elements => $_, user_data => "bar");
        check_empty($heap);
        is($heap->user_data, "bar", "Initial userdata is survives");
        # Do everything 3 times to see if looping screws things up
        my @keys = (14, 8, 1, -12, 16, 10, 15, -11, 13, 14, 9, -1);
        @keys = map "A$_", @keys if $string;
        for (1..3) {
            check_empty($heap);
            if ($heap->isa("Heap::Simple::Hash")) {
                is($heap->key_name, $index, "Key is at position $index");
            } else {
                is($heap->key_index, $index || 0,
                   "Key is at position ".($index || 0));
            }
            # insert
            for my $i (1..@keys) {
                if ($index) {
                    if ($heap->isa("Heap::Simple::Hash")) {
                        $heap->insert(bless {$index => $keys[$i-1],
                                             val => $keys[$i]}, "Wombat");
                    } else {
                        $heap->insert(bless [$keys[$i], $keys[$i-1]], "Wombat");
                    }
                } else {
                    $heap->insert(bless [$keys[$i-1], $keys[$i]], "Wombat");
                }
                is($heap->count, $i, "Count keeps up");
            }
            is($heap->user_data, "bar", "Inserting leaves user_data alone");

            # extract_min
            my $ref = $heap->extract_min;
            isa_ok($ref, "Wombat", "bless survives storage");
            is($heap->count, @keys-1, "Count right after extract");
            my @expect = $string ? ("A-1", undef) : (-12, 16);
            if ($index) {
                if ($heap->isa("Heap::Simple::Hash")) {
                    is_deeply($ref, bless({$index => $expect[0],
                                           val => $expect[1]}, "Wombat"),
                              "We extract what we put in");
                } else {
                    is_deeply($ref, bless([reverse @expect], "Wombat"),
                              "We extract what we put in");
                }
            } else {
                is_deeply($ref, bless(\@expect, "Wombat"),
                          "We extract what we put in");
            }
            is($heap->user_data, "bar", "extract_min leaves user_data alone");
            $ref = eval { $empty_heap->extract_min };
            ok($@, "Extracting from empty heap dies");

            # extract_upto
            my @refs = $heap->extract_upto($string ? "A0" : 0);
            isa_ok($_, "Wombat", "bless survives storage") for @refs;
            @expect = $string ? qw(A-11 A13 A-12 A16) : (-11, 13, -1, undef);
            if ($index) {
                if ($heap->isa("Heap::Simple::Hash")) {
                    is_deeply(\@refs,
                              [bless({$index => $expect[0], 
                                      val    => $expect[1]}, "Wombat"),
                               bless({$index => $expect[2], 
                                      val    => $expect[3]}, "Wombat")]);
                } else {
                    is_deeply([map @$_, @refs], [@expect[1,0,3,2]]);
                }
            } else {
                is_deeply([map @$_, @refs], \@expect);
            }
            is($heap->count, @keys-3);

            @refs = $heap->extract_upto($string ? "A13" : 9);
            isa_ok($_, "Wombat", "bless survives storage") for @refs;
            @expect = $string ? qw(A1 A-12 A10 A15 A13 A14) : (1, -12, 8, 1, 9, -1);
            if ($index) {
                if ($heap->isa("Heap::Simple::Hash")) {
                    is_deeply(\@refs, [map bless({$index => $expect[2*$_-2], val => $expect[2*$_-1]}, "Wombat"), 1..@expect/2]);
                } else {
                    is_deeply([map @$_, @refs], 
                              [map $expect[$_^1], 0..$#expect]);
                }
            } else {
                is_deeply([map @$_, @refs], \@expect);
            }
            is($heap->count, @keys-6);

            is($heap->user_data, "bar", "extract_upto leaves user_data alone");

            @refs = $empty_heap->extract_upto(1e20);
            is(@refs, 0, "extract_upto on empty heap returns nothing");

            # insert again for a bit of irregularity
            for my $i (1..5) {
                if ($index) {
                    if ($heap->isa("Heap::Simple::Hash")) {
                        $heap->insert(bless {$index => $keys[$i-1],
                                             val => $keys[$i]}, "Wombat");
                    } else {
                        $heap->insert(bless [$keys[$i], $keys[$i-1]], "Wombat");
                    }
                } else {
                    $heap->insert(bless [$keys[$i-1], $keys[$i]], "Wombat");
                }
            }
            is($heap->count, @keys-1, "Count keeps up");
            is($heap->user_data, "bar", "Inserting leaves user_data alone");

            # first
            $ref = $heap->first;
            isa_ok($ref, "Wombat", "bless survives storage");
            is($heap->count, @keys-1, "Count right after first unchanged");
            @expect = $string ? ("A-12", "A16") : (-12, 16);
            if ($index) {
                if ($heap->isa("Heap::Simple::Hash")) {
                    is_deeply($ref, bless({$index => $expect[0], 
                                           val => $expect[1]}, "Wombat"),
                              "right values found");
                } else {
                    is_deeply($ref, bless([reverse @expect], "Wombat"), 
                              "right values found");
                }
            } else {
                is_deeply($ref, bless(\@expect, "Wombat"), 
                          "right values found");
            }
            is($heap->user_data, "bar", "First leaves user_data alone");
            # already checked on empty heap

            # first_key
            my $expect = $string ? "A-12" : -12;
            my $min = $heap->first_key;
            is($min, $expect, "Found first key");
            is($heap->user_data, "bar", "First_key leaves user_data alone");
            is($heap->count, @keys-1, "Count keeps up");
            # already checked on empty heap

            # min_key
            $min = eval { $heap->min_key };
            if ($string) {
                ok($@, "There is no min_key method");
            } else {
                is($@, "", "min_key works");
                is($min, $expect, "Found min key");
                is($heap->user_data, "bar", "Min_key leaves user_data alone");
                is($heap->count, @keys-1, "Count keeps up");
                # already checked on empty heap
            }

            # Now drop all values
            $heap->extract_min for 1..$heap->count;
            check_empty($heap);

            # Bigger stress test
            my $n = 5000;
            my @rand = map int(rand(1000)), 1..$n;
            my @sorted;
            if ($index) {
                if ($heap->isa("Heap::Simple::Hash")) {
                    $heap->insert({$index => $_, val => "foo"}) for @rand;
                    @sorted = map $heap->extract_min->{$index}, @rand;
                } else {
                    $heap->insert(["foo", $_]) for @rand;
                    @sorted = map $heap->extract_min->[$index], @rand;
                }
            } else {
                $heap->insert([$_, "foo"]) for @rand;
                @sorted = map $heap->extract_min->[0], @rand;
            }
            if ($string) {
                is_deeply(\@sorted, [sort @rand],
                          "insert/extract from heap is string sort");
            } else {
                is_deeply(\@sorted, [sort {$a <=> $b } @rand],
                          "insert/extract from heap is numeric sort");
            }
        }
    }
    my $fail = eval { Heap::Simple->new(%order_options, elements => ["Hash"]) };
    ok($@, "missing key_name should fail");
}
