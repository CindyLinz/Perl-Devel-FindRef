# NAME

Devel::FindRef - where is that reference to my variable hiding?

# SYNOPSIS

    use Devel::FindRef;

    print Devel::FindRef::track \$some_variable;

# DESCRIPTION

Tracking down reference problems (e.g. you expect some object to be
destroyed, but there are still references to it that keep it alive) can be
very hard. Fortunately, perl keeps track of all its values, so tracking
references "backwards" is usually possible.

The `track` function can help track down some of those references back to
the variables containing them.

For example, for this fragment:

    package Test;

    use Devel::FindRef;
    use Scalar::Util;
                          
    our $var = "hi\n";
    my $global_my = \$var;
    our %global_hash = (ukukey => \$var);
    our $global_hashref = { ukukey2 => \$var };
                            
    sub testsub {
       my $testsub_local = $global_hashref;
       print Devel::FindRef::track \$var;
    }

    my $closure = sub {
       my $closure_var = \$_[0];
       Scalar::Util::weaken (my $weak_ref = \$var);
       testsub;
    };

    $closure->($var);

The output is as follows (or similar to this, in case I forget to update
the manpage after some changes):

    SCALAR(0x7cc888) [refcount 6] is
    +- referenced by REF(0x8abcc8) [refcount 1], which is
    |  the lexical '$closure_var' in CODE(0x8abc50) [refcount 4], which is
    |     +- the closure created at tst:18.
    |     +- referenced by REF(0x7d3c58) [refcount 1], which is
    |     |  the lexical '$closure' in CODE(0x7ae530) [refcount 2], which is
    |     |     +- the containing scope for CODE(0x8ab430) [refcount 3], which is
    |     |     |  the global &Test::testsub.
    |     |     +- the main body of the program.
    |     +- the lexical '&' in CODE(0x7ae530) [refcount 2], which was seen before.
    +- referenced by REF(0x7cc7c8) [refcount 1], which is
    |  the lexical '$global_my' in CODE(0x7ae530) [refcount 2], which was seen before.
    +- the global $Test::var.
    +- referenced by REF(0x7cc558) [refcount 1], which is
    |  the member 'ukukey2' of HASH(0x7ae140) [refcount 2], which is
    |     +- referenced by REF(0x8abad0) [refcount 1], which is
    |     |  the lexical '$testsub_local' in CODE(0x8ab430) [refcount 3], which was seen before.
    |     +- referenced by REF(0x8ab4f0) [refcount 1], which is
    |        the global $Test::global_hashref.
    +- referenced by REF(0x7ae518) [refcount 1], which is
    |  the member 'ukukey' of HASH(0x7d3bb0) [refcount 1], which is
    |     the global %Test::global_hash.
    +- referenced by REF(0x7ae2f0) [refcount 1], which is
       a temporary on the stack.

It is a bit convoluted to read, but basically it says that the value
stored in `$var` is referenced by:

- - the lexical `$closure_var` (0x8abcc8), which is inside an instantiated
closure, which in turn is used quite a bit.
- - the package-level lexical `$global_my`.
- - the global package variable named `$Test::var`.
- - the hash element `ukukey2`, in the hash in the my variable
`$testsub_local` in the sub `Test::testsub` and also in the hash
`$referenced by Test::hash2`.
- - the hash element with key `ukukey` in the hash stored in
`%Test::hash`.
- - some anonymous mortalised reference on the stack (which is caused
by calling `track` with the expression `\$var`, which creates the
reference).

And all these account for six reference counts.

# EXPORTS

None.

# FUNCTIONS

- $string = Devel::FindRef::track $ref\[, $depth\]

    Track the perl value pointed to by `$ref` up to a depth of `$depth` and
    return a descriptive string. `$ref` can point at any perl value, be it
    anonymous sub, hash, array, scalar etc.

    This is the function you most likely want to use when tracking down
    references.

- @references = Devel::FindRef::find $ref

    Return arrayrefs that contain \[$message, $ref\] pairs. The message
    describes what kind of reference was found and the `$ref` is the
    reference itself, which can be omitted if `find` decided to end the
    search. The returned references are all weak references.

    The `track` function uses this to find references to the value you are
    interested in and recurses on the returned references.

- $ref = Devel::FindRef::ptr2ref $integer

    Sometimes you know (from debugging output) the address of a perl value you
    are interested in (e.g. `HASH(0x176ff70)`). This function can be used to
    turn the address into a reference to that value. It is quite safe to call
    on valid addresses, but extremely dangerous to call on invalid ones.  _No
    checks whatsoever will be done_, so don't use this unless you really know
    the value is the address of a valid perl value.

        # we know that HASH(0x176ff70) exists, so turn it into a hashref:
        my $ref_to_hash = Devel::FindRef::ptr2ref 0x176ff70;

- $ptr = Devel::FindRef::ref2ptr $reference

    The opposite of `ptr2ref`, above: returns the internal address of the
    value pointed to by the passed reference. This function is safe to call on
    anything, and returns the same value that a normal reference would if used
    in a numeric context.

# ENVIRONMENT VARIABLES

You can set the environment variable `PERL_DEVEL_FINDREF_DEPTH` to an
integer to override the default depth in `track`. If a call explicitly
specifies a depth, it is not overridden.

# AUTHOR

Marc Lehmann <pcg@goof.com>.

# COPYRIGHT AND LICENSE

Copyright (C) 2007, 2008, 2009, 2013 by Marc Lehmann.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
