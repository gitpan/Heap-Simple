# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use Test::More tests => 430;
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

for my $string (undef, 0, 1) {
    # new & user_data   
    my %options = !defined($string) ? () : 
        $string ? (order => "lt") : (order => "<");
    my $empty_heap = Heap::Simple->new(%options);
    isa_ok($empty_heap, "Heap::Simple", "new creates a Heap::Simple");
    check_empty($empty_heap);
    is($empty_heap->user_data, undef, "Default userdata is undef");
    is($empty_heap->user_data("foo"), undef, "userdata set returns old value");
    is($empty_heap->user_data, "foo", "Userdata set works");
    check_empty($empty_heap);

    my $heap = Heap::Simple->new(%options, user_data => "bar");
    check_empty($heap);
    is($heap->user_data, "bar", "Initial userdata is survives");
    # Do everything 3 times to see if looping screws things up
    my @keys = (14, 8, 1, -12, 16, 10, 15, -11, 13, 13, 9, -1);
    @keys = map "A$_", @keys if $string;
    for (1..3) {
        check_empty($heap);
        # insert
        for my $i (1..@keys) {
            $heap->insert($keys[$i-1]);
            is($heap->count, $i, "Count keeps up");
        }
        is($heap->user_data, "bar", "Inserting leaves user_data alone");

        # extract_min
        my $val = $heap->extract_min;
        is($heap->count, @keys-1, "Count right after extract");
        if ($string) {
            is($val, "A-1", "We extract what we put in");
        } else {
            is($val, -12, "We extract what we put in");
        }
        is($heap->user_data, "bar", "extract_min leaves user_data alone");
        $val = eval { $empty_heap->extract_min };
        ok($@, "Extracting from empty heap dies");

        # extract_upto
        my @refs = $heap->extract_upto($string ? "A0" : 0);
        if ($string) {
            is_deeply(\@refs, [qw(A-11 A-12)]);
        } else {
            is_deeply(\@refs, [-11, -1]);
        }
        is($heap->count, @keys-3);

        @refs = $heap->extract_upto($string ? "A13" : 9);
        if ($string) {
            is_deeply(\@refs, [qw(A1 A10 A13 A13)]);
            is($heap->count, @keys-7);
            # Bring number and string back in sync
            $heap->insert("A13");
        } else {
            is_deeply(\@refs, [1, 8, 9]);
            is($heap->count, @keys-6);
        }

        is($heap->user_data, "bar", "extract_upto leaves user_data alone");

        @refs = $empty_heap->extract_upto(1e20);
        is(@refs, 0, "extract_upto on empty heap returns nothing");

        # insert again for a bit of irregularity
        for my $i (1..5) {
            $heap->insert($keys[$i-1]);
        }
        is($heap->count, @keys-1, "Count keeps up");
        is($heap->user_data, "bar", "Inserting leaves user_data alone");

        # first
        $val = $heap->first;
        is($heap->count, @keys-1, "Count right after first unchanged");
        is($val, $string ? "A-12" : -12, "right values found");
        is($heap->user_data, "bar", "First leaves user_data alone");
        # already checked on empty heap

        # first_key
        my $min = $heap->first_key;
        is($min, $string ? "A-12" : -12, "Found first key");
        is($heap->user_data, "bar", "First_key leaves user_data alone");
        is($heap->count, @keys-1, "Count keeps up");
        # already checked on empty heap

        # min_key
        $min = eval { $heap->min_key };
        if ($string) {
            ok($@, "There is no min_key method");
        } else {
            is($@, "", "min_key works");
            is($min, -12, "Found min key");
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
        $heap->insert($_) for @rand;
        my @sorted = map $heap->extract_min, @rand;
        if ($string) {
            is_deeply(\@sorted, [sort @rand],
                      "insert/extract from heap is string sort");
        } else {
            is_deeply(\@sorted, [sort {$a <=> $b } @rand],
                      "insert/extract from heap is numeric sort");
        }
    }
}
