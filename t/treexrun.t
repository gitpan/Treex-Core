#!/usr/bin/env perl
use strict;
use warnings;
use Treex::Core::Run;
use Test::More;
use File::Slurp;
use File::Basename;
use Treex::Core::Config;
use Cwd qw(realpath);

if ( $^O =~ /^MSWin/ ) { # system calls of treex must be treated differently under MSWin
    done_testing();
    exit;
}

my $my_dir = dirname($0);
my @tasks  = (
    [ q(treex -q -- dummy.treex),                                        '' ],     # reading an empty file
    [ q(treex -q -s -- dummy.treex),                                     '' ],     # reading and saving an empty file
    [ q(treex -q -g '*dummy.treex'),                                     '' ],     # postponed wildcard expansion
    [ q(echo | treex -q -Len Read::Text Util::Eval document='print 0;'), '0' ],    # @ARGV contains q{document=print 0;}

    # It is questionable whether we want to allow the following four constructions
    # [q(echo | treex -q -Len Read::Text Util::Eval document=\'print 1;\'), '1'],# @ARGV contains q{document='print}, q{1;'}
    # [q(echo | treex -q -Len Read::Text Util::Eval document=\"print 1;\"), '1'],# @ARGV contains q{document="print}, q{1;"}
    # [q(echo | treex -q -Len Read::Text Util::Eval document='"print 1;"'), '1'],# @ARGV contains q{document="print 1;"}
    # [q(echo | treex -q -Len Read::Text Util::Eval document="'print 1;'"), '1'],# @ARGV contains q{document='print 1;'}

    [ q(echo | treex -q -Len Read::Text Util::Eval document='print "hello";'),                            'hello' ],
    [ q(echo | treex -q -Len Read::Text Util::Eval document="print 'hi';"),                               'hi' ],
    [ q(echo | treex -q -Len Read::Text Util::Eval document='my @a=("#","is not a comment");print $#a;'), '1' ],
    [ q(echo | treex -q -Len Read::Text Util::Eval document='print "a=b  c";'),                           'a=b  c' ],
    [ q(echo | treex -q -Len Read::Text Util::Eval document='$_="a=b";print;'),                           'a=b' ],
    [   q(echo | treex -q -Len Read::Text Util::Eval document='my $code_with_newlines;
                                                          print 2;'), '2'
    ],
    [ qq(echo | treex -q -Len Read::Text $my_dir/scenarios/print3.scen),       '3' ],
    [ qq(echo | treex -q -Len Read::Text $my_dir/scenarios/scen_in_scen.scen), '4' ],    # scenario file in scenario file

    # try to confuse the scenario parser with a parameter which looks like scenario
    [ q(echo | treex -q -Len Read::Treex from=confuse.scen), '' ],

    # parameters with quotes
    [ q(echo | treex -q -Len Read::Sentences Util::Eval param= document='print $self->_args->{param};'),   '' ],
    [ q(echo | treex -q -Len Read::Sentences Util::Eval param="" document='print $self->_args->{param};'), '' ],
    [ q(echo | treex -q -Len Read::Sentences Util::Eval param='' document='print $self->_args->{param};'), '' ],
    [ q(echo | treex -q -Len Read::Sentences Util::Eval param=" " document='print $self->_args->{param};'), ' ' ],
    [ q(echo | treex -q -Len Read::Sentences Util::Eval param=' ' document='print $self->_args->{param};'), ' ' ],
);

plan tests => scalar @tasks;

# We want to check execution of treex exactly as from the command line.
# Originally, we tried to
# use Test::Output;
# and then is_combined(), but this does not check output of "system" calls,
# so we must use temporary output file.
my $combined_file = 'combined.out';

#TODO $command cannot contain "cd" (change directory), because $combined_file would be saved to that directory
sub is_bash_combined_output {
    my ( $command, $expected_output, $description ) = @_;
    system( 'bash', '-c', $command . "> $combined_file 2>&1" );
    my $content = read_file($combined_file);
    return is( $content, $expected_output, $description );
}
SKIP: {
    my $PERL_X  = $^X;
    my $core_dir = Treex::Core::Config->lib_core_dir();
    my $TREEX_X = realpath( $core_dir . '/../../../bin/treex' );    #development location - lib_core_dir is lib/Treex/Core
    if ( !defined $TREEX_X || !-e $TREEX_X ) {
        $TREEX_X = realpath( $core_dir . '/../../../script/treex' );    #blib location
    }
    skip "Cannot find treex executable", scalar @tasks if !defined $TREEX_X || !-e $TREEX_X;
    my $TREEX = "$PERL_X $TREEX_X";

    my $perl_v = Treex::Core::Run::get_version();
    note("Perl run: \n$perl_v");
    my $sys_v = `$TREEX -v`;
    note("Sys run: \n$sys_v");

    #is( $perl_v, $sys_v, 'We are running same version from perl and from system' );

    # prepare dummy input files
    my $test_data_file    = 'dummy.treex';
    my $confuse_data_file = 'confuse.scen';
    my $doc               = Treex::Core::Document->new();
    $doc->save($test_data_file);
    $doc->save( '2' . $test_data_file );
    $doc->save($confuse_data_file);

    skip 'We run different versions of treex binary', scalar @tasks if $perl_v ne $sys_v;
    foreach my $task_rf (@tasks) {
        my ( $command, $expected_output ) = @$task_rf;
        my $original_cmd = $command;
        $command =~ s/treex/$TREEX/;
        is_bash_combined_output( $command, $expected_output, $original_cmd );
    }
}

#done_testing;
END {
    if ( $^O !~ /^MSWin/ ) {
        unlink $combined_file;
        unlink glob "*dummy.treex*";
        unlink "confuse.scen";
    }
}
