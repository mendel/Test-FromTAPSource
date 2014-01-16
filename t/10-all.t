#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use IPC::Cmd qw(run);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
                   run( command => $cmd, verbose => 0 );



done_testing;
