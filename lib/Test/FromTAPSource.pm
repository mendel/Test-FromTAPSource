package Test::FromTAPSource;

use 5.10.0;

use TAP::Parser;
use Test::Builder;
use Try::Tiny;

use base 'Test::Builder::Module';

=head1 NAME

Test::FromTAPSource - TAP format tests relayed as Test::Builder based tests

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Test::More;
    use Test::FromTAPSource;

    test_from_tap(\$tap_text);

    test_from_tap(\$tap_text, "Overall resulf of the TAP is PASS");

    test_from_tap({ exec => $tap_generator_command }, "The test suite passes");

    test_from_tap({ source => $tap_source_instance }, "The test suite passes");

    ...

    done_testing;


=head1 DESCRIPTION

This module allows you to mix and mash test results from any TAP source with
L<Test::Builder> tests in the same test file. The whole TAP pulled from the TAP
source will show up as a subtest (and L<Test::Builder> will know about its
overall result).

=head1 EXPORTS

The C<test_from_tap> function is exported.

=head1 FUNCTIONS

=cut

=head2 test_from_tap

FIXME allow to use the right subset of the TAP::Parser->new() options (tap, exec, perl, source, sources, switches, ...)
    test_from_tap($tap_source);
    test_from_tap($tap_source, $description);
    $passed = test_from_tap($tap_source);
    $passed = test_from_tap($tap_source, $description);

FIXME

C<$tap_source> is an L<TAP::Parser::Source> instance.

=cut

sub test_from_tap {
    my ($tap_source, $description) = @_;

    $description //= 'Tests from TAP source';

    # Try::Tiny::try uses an unspecified number of nested subroutine calls to
    # perform its job, so instead we just calculate how much deeper the call
    # stack is inside the try and add it to $Test::Builder::Level (in addition
    # to the +1 level for the test_from_tap() sub)
    my $outer_level = _get_stack_level;

    my $tb = __PACKAGE__->builder->child($description);

    return try {
        local $Test::Builder::Level
            = $Test::Builder::Level + 1 + _get_stack_level - $outer_level;

        _run_tests_from_TAP($tb, $tap_source);

        $tb->finalize;  # cannot call it from "finalize", we need the return
                        # value
    }
    catch {
        $tb->finalize;
        die $_ unless eval { $_->isa('Test::Builder::Exception') };
    };
}

sub _get_stack_level {
    my $i;
    while (scalar caller ++$i) { }

    return $i - 1;
}

sub _run_tests_from_TAP {
    my ($tb, $tap_source) = @_;

    my $parser = TAP::Parser->new({ source => $tap_source });

    while (my $result = $parser->next) {
       given ($result->type) {
           when ('version') {
               # ignore version
           }
           when ('pragma') {
               $tb->diag("Ignored TAP pragma '$_'");
           }
           when ('plan') {
               if ($_->has_skip) {
                   $tb->plan(skip_all => $_->explanation);
               }
               else {
                   $tb->plan(tests => $_->tests_planned);
               }
           }
           when ('bailout') {
               $tb->BAIL_OUT($_->explanation);
           }
           when ('comment') {
               $tb->diag($_->comment);
           }
           when ('yaml') {
               $tb->note($_->data);
           }
           when ('test') {
                my @explanation = $_->explanation ? ($_->explanation) : ();

                if ($_->has_skip) {
                    if ($_->has_todo) {
                        $tb->todo_skip(@explanation);
                    }
                    else {
                        $tb->skip(@explanation);
                    }
                }
                elsif ($_->has_todo) {
                    $tb->todo_start(@explanation);
                    $tb->ok($_->is_actual_ok, $_->description);
                    $tb->todo_end;
                }
                else {
                    $tb->ok($_->is_actual_ok, $_->description);
                }
           }
           default {
               die sprintf q{Unknown TAP token type '%s', raw TAP: <<%s>>},
                $_, $result->raw;
           }
       }
    }
}


=head1 SEE ALSO

L<TAP::Parser>, L<TAP::Parser::Source>, L<Test::Builder>

=head1 AUTHOR

Norbert Buchmuller, C<< <norbi at nix.hu> >>

=head1 TODO

=over

=item *

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-fromtapsource at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-FromTAPSource>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::FromTAPSource

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-FromTAPSource>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-FromTAPSource>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-FromTAPSource>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-FromTAPSource/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Norbert Buchmuller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::FromTAPSource
