#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most tests => 1;

BEGIN {
	use_ok( 'Test::FromTAPSource' );
}

diag( "Testing Test::FromTAPSource $Test::FromTAPSource::VERSION, Perl $], $^X" );
