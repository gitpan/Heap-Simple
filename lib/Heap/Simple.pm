package Heap::Simple;
use strict;
use Carp;

use vars qw($VERSION $auto %used);
$VERSION = "0.06";
$auto = "Auto";
%used = ();

use AutoLoader qw(AUTOLOAD);

use constant DEBUG => 0;

sub _use {
    my $name = shift();
    $name =~ s|::|/|g;
    print STDERR "require Heap/Simple/$name.pm\n" if DEBUG;
    return require "Heap/Simple/$name.pm";
}

my %order = ("<"  => "Number",
             ">"  => "NumberReverse",
             "lt" => "String",
             "gt" => "StringReverse",
             );
sub _order {
    my ($self, $order) = @_;
    # Default order if nothing specified
    $order = "<" unless defined($order) && $order ne "";
    my $name;
    if (ref($order) eq "CODE") {
        $self->[0][3] = $order;
        $name = "Less";
    } else {
        $name = $order{$order} || croak "Unsupported order '$order'";
    }
    $used{$name} ||= _use($name);
    return $name;
}

sub _elements {
    my ($self, $elements) = @_;
    $elements = ["Key"] unless defined($elements);
    $elements = [$elements] if ref($elements) eq "";
    croak "option elements is not an array reference" unless
        ref($elements) eq "ARRAY";
    croak "option elements has no type defined at index 0" unless
        defined($elements->[0]);
    my $name = ucfirst(lc($elements->[0]));
    $used{$name} ||= _use($name);
    return (__PACKAGE__ . "::$name")->_elements($self, $name, $elements);
}

sub _init {
}

sub new {
    my ($class, %options) = @_;
    # note: the array starts at elements 1 to make the subscripting
    # operations (much!) cleaner.
    # So elements 0 is used for associated data
    my $self = bless [[]], $class;
    # We temporarily bless $self into $class so you can play OO games with it
    my @order    = $self->_order($options{order});
    my @elements = $self->_elements($options{elements});
    my $gclass = join("::", $class, $auto, @order, @elements);
    no strict "refs";
    @{"${gclass}::ISA"} = (__PACKAGE__ . "::$elements[0]",
                           __PACKAGE__ . "::$order[0]",
                           $class) unless @{"${gclass}::ISA"};
    print STDERR "Generated class $gclass\n" if DEBUG;
    # Now rebless the result in its final generated class
    bless $self, $gclass;
    $self->[0][1] = exists($options{infinity}) ?
        $options{infinity} : $self->_INF;
    $self->[0][4] = $options{user_data} if defined($options{user_data});
    $self->_init(\%options);
    return $self;
}

sub _ELEMENTS_PREPARE {
    return "";
}

sub _ORDER_PREPARE {
    return "";
}

sub _PREPARE {
    my $self = shift;
    return join("", $self->_ORDER_PREPARE, $self->_ELEMENTS_PREPARE);
}

sub _VALUE {
    return $_[1];
}

sub _WRAPPER {
    return $_[2];
}

sub _INF {
    return;
}

sub _MAKE_KEY {
    my ($self, $key, $value) = @_;
    return "$key " . $self->_KEY($value);
}

my $balanced;
# String with balanced parenthesis
$balanced = qr{[^()]*(?:\((??{$balanced})\)[^()]*)*};
sub _make {
    my $self  = shift;

    die "Cannot determine caller class from '$self'" unless ref($self);
    my $subroutine = (caller(1))[3];
    $subroutine =~ /(::[^:]*)\z/ || die "Cannot parse caller '$subroutine'";
    $subroutine = ref($self) . $1;
    print STDERR "Sub: $subroutine\n" if DEBUG;

    my $string = shift;
    # Very simple macro expander
    1 while $string =~ s/(_\w+)\(($balanced)\)/$self->$1(split ',', $2)/eg;
    print STDERR "Code: $string\n" if DEBUG;
    no warnings 'redefine';
    no strict 'refs';
    die "Duplicate attempt to set $subroutine" if defined(*$subroutine{CODE});
    *$subroutine = eval $string;
    die $@ if $@;
}

sub count {
    return $#{+shift};
}

sub clear {
    $#{+shift} = 0;
}

1;

__END__

sub insert {
    my $self = shift;
    if ($self->_KEY("") eq "") {
        $self->_make('sub {
    my ($self, $key) = @_;
    _ORDER_PREPARE()
    my $i = @$self;
    $i = $i >> 1 while $i > 1 && _SMALLER($key, ($self->[$i] = $self->[$i >> 1]));
    $self->[$i] = $key;
    return}');
    } else {
        $self->_make('sub {
    my ($self, $value) = @_;
    _PREPARE()
    _MAKE_KEY(my $key =, $value);
    my $i = @$self;
    $i = $i >> 1 while
        $i > 1 && _SMALLER($key, _KEY(($self->[$i] = $self->[$i >> 1])));
    $self->[$i] = _WRAPPER($key, $value);
    return}');
    }
    $self->insert(@_);
}

sub extract_upto {
    my $self = shift;
    $self->_make('sub {
    my ($self, $border) = @_;
    _PREPARE()
    my @result;
    push(@result, $self->extract_top) until
        @$self <= 1 || _SMALLER($border, _KEY($self->[1]));
    return @result
}');
    $self->extract_upto(@_);
}

sub extract_top {
    my $self = shift;
    $self->_make('sub {
    my $self = shift;
    if (@$self <= 2) {
        return _VALUE(pop(@$self)) if @$self == 2;
        croak "heap underflow";
    }
    my $min = _VALUE($self->[1]);
    _PREPARE()
    my $key = _KEY($self->[-1]);
    my $n = @$self-2;
    my $i = 1;
    my $l = 2;
    while ($l < $n) {
        if (_SMALLER(_KEY($self->[$l]), $key)) {
            if (_SMALLER(_KEY($self->[$l+1]), _KEY($self->[$l]))) {
                $self->[$i] = $self->[$l+1];
                $i = $l+1;
            } else {
                $self->[$i] = $self->[$l];
                $i = $l;
            }
        } elsif (_SMALLER(_KEY($self->[$l+1]), $key)) {
            $self->[$i] = $self->[$l+1];
            $i = $l+1;
        } else {
            last;
        }
        $l = $i * 2;
    }
    if ($l == $n && _SMALLER(_KEY($self->[$l]), $key)) {
        $self->[$i] = $self->[$l];
        $i = $l;
    }
    $self->[$i] = pop(@$self);
    return $min
}');
    $self->extract_top(@_);
}

sub extract_min {
    my $self = shift;
    $self->_make('sub {
    my $self = shift;
    if (@$self <= 2) {
        return _VALUE(pop(@$self)) if @$self == 2;
        croak "heap underflow";
    }
    my $min = _VALUE($self->[1]);
    _PREPARE()
    my $key = _KEY($self->[-1]);
    my $n = @$self-2;
    my $i = 1;
    my $l = 2;
    while ($l < $n) {
        if (_SMALLER(_KEY($self->[$l]), $key)) {
            if (_SMALLER(_KEY($self->[$l+1]), _KEY($self->[$l]))) {
                $self->[$i] = $self->[$l+1];
                $i = $l+1;
            } else {
                $self->[$i] = $self->[$l];
                $i = $l;
            }
        } elsif (_SMALLER(_KEY($self->[$l+1]), $key)) {
            $self->[$i] = $self->[$l+1];
            $i = $l+1;
        } else {
            last;
        }
        $l = $i * 2;
    }
    if ($l == $n && _SMALLER(_KEY($self->[$l]), $key)) {
        $self->[$i] = $self->[$l];
        $i = $l;
    }
    $self->[$i] = pop(@$self);
    return $min
}');
    $self->extract_top(@_);
}

sub top_key {
    my $self = shift;
    if ($self->can("_QUICK_KEY")) {
        $self->_make('sub {
    my $self = shift;
    return @$self > 1 ? _QUICK_KEY($self->[1]) :
        defined($self->[0][1]) ? $self->[0][1] : croak "Heap empty"
}');
    } else {
        $self->_make('sub {
    my $self = shift;
    return defined($self->[0][1]) ? $self->[0][1] : croak "Heap empty" if
        @$self <= 1;
    _ELEMENTS_PREPARE()
    return _KEY($self->[1])
}');
    }
    $self->top_key(@_);
}

sub min_key {
    my $self = shift;
    if ($self->can("_QUICK_KEY")) {
        $self->_make('sub {
    my $self = shift;
    return @$self > 1 ? _QUICK_KEY($self->[1]) :
        defined($self->[0][1]) ? $self->[0][1] : croak "Heap empty"
}');
    } else {
        $self->_make('sub {
    my $self = shift;
    return defined($self->[0][1]) ? $self->[0][1] : croak "Heap empty" if
        @$self <= 1;
    _ELEMENTS_PREPARE()
    return _KEY($self->[1])
}');
    }
    $self->top_key(@_);
}

sub first_key {
    my $self = shift;
    if ($self->can("_QUICK_KEY")) {
    $self->_make('sub {
        my $self = shift;
    return if @$self <= 1;	# avoid autovivify
    return _QUICK_KEY($self->[1])
}');
    } else {
    $self->_make('sub {
        my $self = shift;
    return if @$self <= 1;	# avoid autovivify
    _ELEMENTS_PREPARE()
    return _KEY($self->[1])
}');
    }
    return $self->first_key(@_);
}

sub first {
    my $self = shift;
    if ($self->_VALUE("") eq "") {
        $self->_make('sub {
    return shift->[1]
}');
    } else {
        $self->_make('sub {
    my $self = shift;
    return if @$self <= 1;	# avoid autovivify
    return _VALUE($self->[1])
}');
    }
    return $self->first(@_);
}

# This code is pretty weak. Often best to override for the mement
sub key {
    my $self = shift;
    if ($self->_KEY("") eq "") {
        $self->_make('sub {
    return $_[1]}');
    } else {
        $self->_make('sub {
    my $self = shift;
    return _QUICK_KEY(shift)
}');
    }
    return $self->key(@_);
}

sub keys {
    my $self = shift;
    if($self->_KEY("") eq "") {
        $self->_make('sub {
    my $self = shift;
    return @$self[1..$#$self]}');
    } else {
        $self->_make('sub {
    my $self = shift;
    _ELEMENTS_PREPARE()
    return map _KEY($_), @$self[1..$#$self]}');
    }
    return $self->keys(@_);
}

sub values {
    my $self = shift;
    if($self->_VALUE("") eq "") {
        $self->_make('sub {
    my $self = shift;
    return @$self[1..$#$self]}');
    } else {
        $self->_make('sub {
    my $self = shift;
    return map _VALUE($_), @$self[1..$#$self]}');
    }
    return $self->values(@_);
}

sub user_data {
    if (@_ > 1) {
        my $self = shift;
        my $old = $self->[0][4];
        $self->[0][4] = shift;
        return $old;
    }
    return shift->[0][4];
}

sub infinity {
    if (@_ > 1) {
        my $self = shift;
        my $old = $self->[0][1];
        $self->[0][1] = shift;
        return $old;
    }
    return shift->[0][1];
}

#sub key_insert {
#    croak "Wrong Heap type, does not support key_insert";
#}

=head1 NAME

Heap::Simple - Fast and easy to use classic heaps

=head1 SYNOPSIS

    use Heap::Simple;

    # Create a heap
    my $heap = Heap::Simple->new;
    my $heap = Heap::Simple->new(%options);

    # Put data in the heap
    $heap->insert($element);
    # Put data in a "Object" or "Any" heap with a given key
    $heap->key_insert($key, $element);

    # Extract data
    $element = $heap->extract_top;

    # Extract all data whose key is not above a given value
    @elements = $heap->extract_upto($max_key);

    # Look which data is first without extracting
    $element = $heap->first;

    # Find the lowest value in the heap
    $top_key = $heap->first_key;  # returns undef   on an empty heap
    $top_key = $heap->top_key;	  # return infinity on an empty heap

    # Find the number of elements
    $count = $heap->count;

    # Empty the heap
    $heap->clear;

    # Get all keys (not sorted)
    @keys = $heap->keys;
    # Get all values (not sorted)
    @values = $heap->values;

    # Find the key corresponding to a value
    $key = $heap->key($value);

    # Get/Set user_data
    $user_data  = $heap->user_data;
    $old_data   = $heap->user_data($new_data);

    # Get/Set infinity
    $infinity     = $heap->infinity;
    $old_infinity = $heap->infinity($new_data);

    # Get the position of a key in an element
    $key_index    = $heap->key_index;
    $key_name     = $heap->key_name;
    $key_method   = $heap->key_method;
    $key_function = $heap->key_function;

=head1 EXAMPLE1

    use Heap::Simple;
    my $heap = Heap::Simple->new(elements => "Any");

    $heap->key_insert(8, "bar");
    $heap->key_insert(5, "foo");

    # This will print foo (5 is the top key)
    print "First value is ", $heap->extract_top, "\n";

    $heap->key_insert(7, "baz");

    # This will print baz (7 is the top key)
    print "Next value is ", $heap->extract_top, "\n";
    # This will print bar (8 is now the top key)
    print "Next value is ", $heap->extract_top, "\n";

=head1 EXAMPLE2

    # This is purely for display, ignore it
    use Data::Dumper;
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse = 1;

    # Real code starts here
    use Heap::Simple;
    my $heap = Heap::Simple->new(elements => "Array");

    $heap->insert([8, "bar"]);
    $heap->insert([5, "foo"]);

    # This will print [5, foo] (5 is the top key)
    print "First value is ", Dumper($heap->extract_top), "\n";

    $heap->insert([7, "baz"]);

    # This will print [7, baz] (7 is the top key)
    print "Next value is ", Dumper($heap->extract_top), "\n";
    # This will print [8, bar] (8 is now the top key)
    print "Next value is ", Dumper($heap->extract_top), "\n";

=head1 DESCRIPTION

A heap is a partially sorted structure where it's always easy to extract the
smallest element. If the collection of elements is changing dynamically, a
heap has less overhead than keeping the collection fully sorted.

The order in which equal elements get extracted is unspecified.

The main order relations supported by this module are "<" (numeric compare)
and "lt" (string compare).

The module allows you to manage data where the elements are of several
allowed types, in particular array references, hash references, objects
or just the keys themselves.

The internals of the module do nothing with the elements inserted except
inspecting the key. This means that if you for example store a blessed
object, that's what you will get back on extract. It's also ok to keep
references to the elements around and make changes to them while they are
in the heap as long as you don't change the key.

=head1 EXPORT

None.

=head1 METHODS

New has a lot of ways to specify element types, but the right choices
follows quite directly from the data you'll put in the heap. If the key
is part of the data (or easily derived from the data), choose an element
type that tells how to get the key out of the data, and insert elements
using L<insert|/"insert">. If the key is independent from the data or
you want to avoid repeated key calculations, use the L<Any|/"Any"> element
type and insert elements using L<key_insert|/"key_insert">.

=over

=item X<new>my $heap = Heap::Simple->new

This simplest form creates a new (empty) heap object able to hold numeric keys.

You could for example use this to print a list of numbers from low to high:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->extract_top, " " for 1..$heap->count;
    print "\n";
    # Will print: -1 3 3 8 14

This example is silly of course. You could just as well directly use
L<perl sort|perlfunc/"sort">. But in real applications you would do the
inserting interleaved with extracting and always keeping the list sorted
would become inefficient for big lists. That is where you would use a heap.
The examples we give will however be like the one above so you can quickly
see the way in which the methods are supposed to be called.

For some applications this basic usage where you just store numeric keys will
be good enough, but usually you want to be able to store more complex elements.

Several options can help you with that:

=over 2

=item X<order>order => $order

$order indicates what operation is used to compare keys. Supported orders are:

=over 2

=item E<lt>

Indicates that keys are compared as numbers, and extraction is lowest value
first. This is actually the default order, so the example above could have
used:

    my $heap = Heap::Simple->new(order => "<");

and the result would have been exactly the same.

The default infinity for this order is +inf.

=item E<gt>

Indicates that keys are compared as numbers, and extraction is highest value
first. This means that methods like L<extract_top|"extract_top"> become
rather confusing in name, since they extract the maximum in the sense of
the numeric value (but it's still the smallest value in terms of the
abstract order relation).

Repeating the example with this order gives:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => ">");
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->extract_top, " " for 1..$heap->count;
    print "\n";
    # Will print: 14 8 3 3 -1

The default infinity for this order is -inf.

=item lt

Indicates that the keys are compared as strings, and extraction is lowest
value first. So we could modify the "<" example to:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "lt");
    $heap->insert($_) for "ate", 8, 3, "zzzz", 14, -1, 3, "at";
    print $heap->extract_top, " " for 1..$heap->count;
    print "\n";
    # Will print: -1 14 3 3 8 at ate zzzz

Notice how 14 comes before 3 as you would expect in lexical sorting.

The default infinity for this order is "undef" (there is no maximum string)

=item gt

Indicates that the keys are compared as strings, and extraction is highest
value first. The concept of "minimum" again becomes rather confusing.
The standard example now becomes:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "gt");
    $heap->insert($_) for "ate", 8, 3, "zzzz", 14, -1, 3, "at";
    print $heap->extract_top, " " for 1..$heap->count;
    print "\n";
    # Will print: zzzz ate at 8 3 3 14 -1

The default infinity for this order is "" (the empty string)

=item $code_reference

If your keys are completely weird things, ordered neither as numbers nor as 
strings and you need a special compare function, you can use this general 
ordering type.

Every time two keys need to be compared, the given code reference will be
called like:

    $less = $code_reference($key1, $key2);

This should return a true value if $key1 is smaller than $key2 and a false
value otherwise (actually, since the order of equal elements is unspecified,
it's ok to return true in case of equality too). $code_reference should
imply a total order relation, so it needs to be transitive.

Since in this case nothing can be determined about the key type, there will
be no infinity by default (even if the keys are numbers).

Example:

    use Heap::Simple;

    sub more { return $_[0] > $_[1] }

    my $heap = Heap::Simple->new(order => \&more);
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->extract_top, " " for 1..$heap->count;
    print "\n";
    # Will print: 14 8 3 3 -1

The code reference will be called many times during normal heap operations
(O(log n) times for a single insert or extract on a size n heap), so only use
this order type within reason. Usually it's better to precalculate some number 
or string representation of some sort of key and use normal compares on these.
You can use the L<Any element type|"Any"> and L<key_insert|"key_insert"> to 
wrap the precalculated key with the corresponding element, or you can delegate
the key calculation to the L<insert|"insert"> method and use one of the
L<Method|"Method">, L<Object|"Object"> or L<Function|"Function"> element types.

Here's an example of such "fake" keys: 

    # "human" sorting mixed strings
    use Heap::Simple;

    sub key {
        my $str = uc(shift);
        $str =~ s|(0*)(\d+)|pack("AN/A*N", "0", $2, length($1))|eg;
        return $str;
    }
       
    my $heap = Heap::Simple->new(order => "lt",
                                 elements => [Function => \&key]);
    $heap->insert($_) for qw(Athens5.gr Athens40.gr
                             Amsterdam51.nl Amsterdam5.nl amsterdam20.nl);
    print $heap->extract_top, "\n" for 1..$heap->count;
    # This will print:
    Amsterdam5.nl
    amsterdam20.nl
    Amsterdam51.nl
    Athens5.gr
    Athens40.gr

=back

=item X<elements>elements => $element_type

This option describes what sort of elements we will store in the heap.
The only reason the module needs to know this is to determine how to access
the key values.

The $element_type is usually an array reference, but if the array has only
one entry, you may use that directly. So you can use:

    elements => "Array"

instead of:

    elements => ["Array"]

The following element types are currently supported:

=over 2

=item X<Key>["Key"]

Indicates that the elements are the keys themselves. This is the default if no
elements option is provided. So the constructor in the previous example could
also have been written as:

    my $heap = Heap::Simple->new(order => "lt",
                                 elements => ["Key"]);

or in the simplified notation:

    my $heap = Heap::Simple->new(order => "lt", elements => "Key");

=item X<Array>[Array => $index]

Indicates that the elements are array references, with the key at index $index.
So now the element can be not just the key, but also associated data. We can
use this to for example print the values of a hash ordered by key:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "lt",
                                 elements => [Array => 0]);
    while (my ($key, $val) = each %hash) {
        $heap->insert([$key, $val]);
    }
    for (1..$heap->count) {
        print $heap->extract_top->[1], "\n";
    }

You can always use something like [$key, @data] to pair up keys and data,
so the "Array" element type is rather generally useful (but see the
L<Object|"Object"> and L<Any|"Any"> element types for another way to pair
keys with data). Since it's so common to have the key in the first position, 
you may in fact drop the index in that case, so the constructor in the 
previous example could also be written as:

    my $heap = Heap::Simple->new(order => "lt",
                                 elements => ["Array"]);

or using the one element rule:

    my $heap = Heap::Simple->new(order => "lt",
                                 elements => "Array");

In case the elements you want to store are arrays (or array based objects
(or L<fields based objects|fields>) and you are prepared to break the object
encapsulation), this element type is also very nice. If for example the value
on which you want to order is a number at position 4, you could use:

    my $heap = Heap::Simple->new(elements => [Array => 4]);
    print "The key is $object->[4]\n";
    $heap->insert($object);

=item X<Hash>[Hash => $key_name]

Indicates that the elements are hash references, where the key (for the heap
element) is the value $element->{$key_name} .

Redoing the Array example in Hash style gives:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "lt",
                                 elements => [Hash => "tag"]);
    while (my ($key, $val) = each %hash) {
        $heap->insert({tag => $key, value => $val});
    }
    for (1..$heap->count) {
        print $heap->extract_top->{value}, "\n";
    }

In case the elements you want to store are hashes (or hash based objects and 
you are prepared to break the object encapsulation), this element type is also
very nice. If for example the value on which you want to order is a number
with key "price", you could use:

    my $heap = Heap::Simple->new(elements => [Hash => "price"]);
    print "The key is $object->{price}\n";
    $heap->insert($object);

=item X<Method>[Method => $method_name]

In case you don't want to (or can't) break the object encapsulation, but there
is a method that will return the key for a given object, you can use this.

The method method_name will be called like:

    $key = $element->$method_name();

and should return the key corresponding to $element.

Suppose that the elements are objects whose weight you can access using the
"weight" method. A heap ordered on weight then becomes:

    my $heap = Heap::Simple->new(elements => [Method => "weight"]);
    print "The key is ", $object->weight(), "\n";
    $heap->insert($object);

=item X<Object>[Object => $method_name]

The drawback of the L<"Method" element type|"Method"> is that the method will
be called every time the internals need ordering information, which will be
O(log n) for a single insert or extract on a heap of size n. So it's usually
better to first extract the key before insert, wrap the object with the key
such that key access is cheap and insert that. Since this is so common,
this element type is provided for that.

So this element type will only call $method_name once on the initial insert,
after which internally the key is entered together with the value. This makes
it faster, but it also uses more memory.

It also means that it's now perfectly fine to make changes to the object
that change the key while it is in the heap. This will have absolutely no
influence on the ordering anymore, and methods like L<first_key|"first_key">
will still return what the key value was at insert time.

Repeating the previous example in this style is a trivial variation:

    my $heap = Heap::Simple->new(elements => [Object => "weight"]);
    print "The key is ", $object->weight(), "\n";
    $heap->insert($object);

Since for this element type the key is almost completely decoupled from the
value and only fetched on insert, it often makes sense to not let the heap
calculate the key, but do it yourself before the insert, and then use
L<key_insert|"key_insert">. In fact, if you never use plain L<insert|"insert">
at all, you don't even have to bother passing a method name (though in that
case the fact that the thing you store is an object is pretty irrelevant and
it's probable more natural to use the L<Any element type|"Any">).

=item X<Function>[Function => $code_reference]

For completely general key calculation you can use this element type. The given
code reference will be called on an element like:

    $key = $code_reference->($element);

and should return the key corresponding to $element.

An example:

    sub price {
        my $items = shift;
        my $price = 0;
        $price += $_->price for @$items;
    }

    my $heap = Heap::Simple->new(elements => [Function => \&price]);
    print "All items together will cost ", $item_list->price, "\n";
    $heap->insert($item_list);

=item X<Any>[Any => $code_reference]

The same discussion as under L<Object|"Object"> applies for
L<Function|"Function">: single insert and extract on a size n heap will call
the code reference O(log n) times, which could be get slow.

So if you are prepared to use more memory, you can again tell Heap::Simple
to calculate the key already at insert time, and store it together with the
value. This will avoid the need for repeated key calculations.

The "Any" element type will do this for you transparantly.

The heap part of the above example becomes:

    my $heap = Heap::Simple->new(elements => [Any => \&price]);
    print "All items together will cost ", $item_list->price, "\n";
    $heap->insert($item_list);

Since for this element type the key is almost completely decoupled from the
value and only fetched on insert, it often makes sense to not let the heap
calculate the key, but do it yourself before the insert, and then use
L<key_insert|"key_insert">. In fact, if you never use plain L<insert|"insert">
at all, you don't even have to bother passing the code reference. So the last
example could look like:

    my $heap = Heap::Simple->new(elements => "Any");
    my $price = $item_list->price;
    print "All items together will cost $price\n";
    $heap->key_insert($price, $item_list);

Or we can use it to simplify the hash sort on key example a bit:

    use Heap::Simple;

    my $heap = Heap::Simple->new(order => "lt",
                                 elements => "Any");
    while (my ($key, $val) = each %hash) {
        $heap->key_insert($key, $val);
    }
    for (1..$heap->count) {
        print $heap->extract_top, "\n";
    }

=back

=item user_data => $user_data

You can associate one scalar worth of user data with any heap. This option
allows you to set its value already at object creation. You can use the
L<user_data|"user_data"> method to get/set the associated value.

If this option is not given, the heap starts with "undef" associated to it.

    my $heap = Heap::Simple->new(user_data => "foo");
    print $heap->user_data, "\n";
    # prints foo

=item infinity => $infinity

Associates $infinity as the highest possible key with the created heap.
($infinity may or may not be a possible key itself).
Setting it to "undef" means there is no infinity associated with the heap.

The default value depends on the L<order|"order"> relation that was
specified.

Usually you can just forget about this option. Only L<top_key|"top_key">
really cares.

=back

Notice that the class into which the resulting heap is blessed will B<not>
be Heap::Simple. It will be an on demand generated class that will have
Heap::Simple as an ancestor.

=item X<insert>$heap->insert($element)

Inserts the $element in the heap. On extraction you get back exactly the same
$element as you inserted, including a possible L<blessing|perlfunc/"bless">.

=item X<key_insert>$heap->key_insert($key, $element)

Inserts the $element in the heap ordered by the given $key. Since in this case
the key must be stored seperately from the element, this only works for
L<"Object"|"Object"> and L<"Any"|"Any"> heaps.

On extraction you get back exactly the same $element as you inserted,
including a possible L<blessing|perlfunc/"bless">.

=item X<extract_top>$element = $heap->extract_top

For all elements in the heap, find the top one (the one that is "lowest" in the
order relation), remove it from the heap and return it.

This method used to be called C<"extract_min"> instead of C<"extract_top">. 
The old name is still supported but is deprecated.

Throws an exception if the heap is empty.

=item X<extract_upto>@elements = $heap->extract_upto($value)

Finds all elements in the heap whose key is not above $value and removes them
from the heap. The list of removed element is returned ordered by key value
(low to high).

Returns an empty list for the empty heap.

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print join(", ", $heap->extract_upto(3)), "\n";
    # prints -1, 3, 3

=item X<min>$element = $heap->first

For all elements in the heap, find the one with the lowest key and return it.
Returns undef in case the heap is empty. The contents of the heap remain
unchanged.

Since the data returned from a non-empty heap can usually not be undef, you
could use this method to check if a heap is empty, but it's probably more
natural to use L<count|"count"> for that.

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->first, "\n";
    # prints -1

=item X<first_key>$top_key = $heap->first_key

Looks for the lowest key in the heap and returns its value. Returns undef
in case the heap is empty

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->first_key, "\n";
    # prints -1

=item X<top_key>$top_key = $heap->top_key

Looks for the lowest key in the heap and returns its value. Returns the highest
possible value (the infinity for the chosen order) in case the heap is empty.
If there is no infinity, it will throw an exception.

Example:

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->top_key, "\n";
    # prints -1

This method used to be called "min_key" instead of "top_key". The old name is 
still supported but is deprecated.

=item X<key>$key = $heap->key($value)

Calculates the key corresponding to $value in the same way as the internals
of $heap would. Can fail for L<Object|"Object"> and L<Any|"Any"> element
types if there was no method or function given on heap creation.

Notice that this does not access the elements in the heap in any way. 
In particular, it's B<not> looking for $value in the heap hoping to match its 
key.

=item X<count>$count = $heap->count

Returns the number of elements in the heap.

    use Heap::Simple;

    my $heap = Heap::Simple->new;
    $heap->insert($_) for 8, 3, 14, -1, 3;
    print $heap->count, "\n";
    # prints 5

=item X<clear>$heap->clear

Removes all elements from the heap.

=item X<keys>@keys = $heap->keys

Returns the keys of all elements in the heap in some unspecified order
(so don't expect them to be ordered). This may imply a lot of function
calls if getting the key from an element implies a function call
(as it does for the L<Method|"Method"> and L<Function|"Function"> element
types, but not for the L<Object|"Object"> and L<Any|"Any"> element types).

Multiple calls to an unchanged heap will return the keys in the same order,
which is also consistent with the order of L<values|"values">

=item X<values>@values = $heap->values

Returns all elements in the heap in some unspecified order
(does not remove them from the heap).

Multiple calls to an unchanged heap will return the values in the same order,
which is also consistent with the order of L<keys|"keys">

=item X<user_data>$user_data = $heap->user_data

Queries the user_data associated with the heap.

=item $old_data = $heap->user_data($new_data)

Associates new user_data with the heap. Returns the old value.

=item X<infinity>$infinity = $heap->infinity

Queries the infinity value associated with the heap. Returns undef if there
is none. The default infinity is implied by the chosen order relation.

=item $old_infinity = $heap->infinity($new_infinity)

Associates a new infinity with the heap. Returns the old value.

=item $key_index = $heap->key_index

Returns the index of the key for L<array reference based heaps|"Array">.
Doesn't exist for the other heap types.

=item $key_name = $heap->key_name

Returns the name of the key key for L<hash reference based heaps|"Hash">.
Doesn't exist for the other heap types.

=item $key_name = $heap->key_method

Returns the name of the method to fetch the key from an object. Only exists
for L<Method|"Method"> and L<Object|"Object"> based heaps.

=item $key_function = $heap->key_function

Returns the code reference of the function to fetch the key from an element.
Only exists for L<"Function"|"Function"> and L<"Any"|"Any"> heaps.

=back

=head1 SEE ALSO

L<Heap>,
L<Heap::Priority>

=head1 AUTHOR

Ton Hospel, E<lt>Heap::Simple@ton.iguana.beE<gt>

Parts are based on code by Joseph N. Hall (http://www.perlfaq.com/faqs/id/196)

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
