# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use Test::More tests => 3574;
BEGIN { $^W = 1 };
BEGIN { use_ok("Heap::Simple") };

sub check_empty {
    my ($heap, $order) = @_;
    is($heap->count, 0, "Empty heap has count 0");
    is($heap->first, undef, "Empty heap gives undef");
    is($heap->first_key, undef, "First key returns undef on empty heap");
    my @expect = (1e300000, -1e300000, undef, "");
    my $val = eval { $heap->min_key };
    if (defined($expect[$order])) {
        is($val, $expect[$order], "Min key returns '$expect[$order]' on empty heap");
    } else {
        ok($@, "min_key should not exist");
    }
}

my $index;
my $basic;
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

my @order = (map [order => $_], qw(< > lt gt));
for my $order (-1..$#order) {
    my %order = $order == -1 ? () : @{$order[$order]};
    $order = 0 if $order == -1;	# Expect the default
    for ([],
         ["Key"],
         ["Array"],
         ["Array", 0],
         ["Array", 1],
         ["Hash", "baz"]) {
        $index = $_->[1];
        my %elements = @$_ ? (elements => $_) : ();

        # new & user_data
        my $empty_heap = Heap::Simple->new(%order, %elements);
        isa_ok($empty_heap, "Heap::Simple", "new creates Heap::Simple");
        my @expect = qw(Heap::Simple::Number Heap::Simple::NumberReverse
                      Heap::Simple::String Heap::Simple::StringReverse);
        isa_ok($empty_heap, $expect[$order], "right superclass");
        check_empty($empty_heap, $order);
        is($empty_heap->user_data, undef, "Default userdata is undef");
        is($empty_heap->user_data("foo"), undef, "userdata set returns old value");
        is($empty_heap->user_data, "foo", "Userdata set works");
        check_empty($empty_heap, $order);

        my $heap = Heap::Simple->new(%order, %elements, user_data => "bar");
        check_empty($heap, $order);
        is($heap->user_data, "bar", "Initial userdata is survives");

        # We'll insert each entry as key with the follower as value
        my @keys = (14, 8, 1, -12, 16, 10, 15, -11, 13, 10, 9, -1);
        @keys = map "A$_", @keys if $order == 2 || $order == 3;
        $basic = $heap->isa("Heap::Simple::Key");

        # Do everything 2 times to see if looping screws things up
        for (1..2) {
            check_empty($heap, $order);
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
            is($heap->user_data, "bar", "Inserting leaves user_data alone");

            # extract_min
            my $ref = $heap->extract_min;
            isa_ok($ref, "Wombat", "bless survives storage") unless $basic;
            is($heap->count, @keys-1, "Count right after extract");
            @expect = value($heap, [-12, 16], [16, 10], ["A-1", undef], ["A9", "A-1"]);
            is_deeply($ref, $expect[$order], "We extract what we put in");
            is($heap->user_data, "bar", "extract_min leaves user_data alone");
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

            is($heap->user_data, "bar", "extract_upto leaves user_data alone");

            @refs = $empty_heap->extract_upto(1e20);
            is(@refs, 0, "extract_upto on empty heap returns nothing");

            # insert again for a bit of irregularity
            for my $i (1..5) {
                $heap->insert(make($keys[$i-1], $keys[$i]));
            }
            is($heap->count, @keys-1, "Count keeps up");
            is($heap->user_data, "bar", "Inserting leaves user_data alone");

            # first
            $ref = $heap->first;
            isa_ok($ref, "Wombat", "bless survives storage") unless $basic;
            is($heap->count, @keys-1, "Count right after first unchanged");
            @expect = value($heap, [-12, 16], [16, 10], ["A-12", "A16"], ["A8", "A1"]);
            is_deeply($ref, $expect[$order], "right values found");
            is($heap->user_data, "bar", "First leaves user_data alone");
            # already checked on empty heap

            # first_key
            my $min = $heap->first_key;
            @expect = qw(-12 16 A-12 A8);
            is($min, $expect[$order], "Found first key");
            is($heap->user_data, "bar", "First_key leaves user_data alone");
            is($heap->count, @keys-1, "Count keeps up");
            # already checked on empty heap

            # min_key
            $min = eval { $heap->min_key };
            if ($order == 2) {
                ok($@, "There is no min_key method");
            } else {
                is($@, "", "min_key works");
                is($min, $expect[$order], "Found min key");
                # already checked on empty heap
            }
            is($heap->user_data, "bar", "Min_key leaves user_data alone");
            is($heap->count, @keys-1, "Count keeps up");

            # Now drop all values
            $heap->extract_min for 1..$heap->count;
            check_empty($heap, $order);

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
            if ($heap->isa("Heap::Simple::Hash")) {
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
