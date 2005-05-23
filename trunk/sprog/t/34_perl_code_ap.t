use strict;
use warnings;

use Test::More tests => 21;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::PerlCodeAP');

my $app = TestApp->make_test_app;

my($source, $perl, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::PerlCodeAP
  LineSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($perl, 'Sprog::Gear::PerlCodeAP', 'perl gear');
isa_ok($perl, 'Sprog::Gear');

ok($perl->has_input, 'has input');
ok($perl->has_output, 'has output');
is($perl->input_type,  'A', 'correct input connector type (list)');
is($perl->output_type, 'P', 'correct input connector type (pipe)');
is($perl->title, 'Perl Code', 'title looks ok');
like($perl->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($perl->perl_code, '', 'default Perl code is blank');

$source->messages(
  [ row => [ qw(one two three) ] ],
);


is($app->test_run_machine, '', 'one row processed without errors');
is_deeply([ $sink->lines ], [ ], 'no output by default');
$sink->reset;

$perl->perl_code('{');

like($app->test_run_machine, qr/syntax error/,
  'syntax error captured successfully');


$source->messages(
  [ row => [ qw(one two three) ] ],
);

$perl->perl_code('print "$r->[2]\n"');

is($app->test_run_machine, '', 'simple Perl snippet processed one row OK');
is_deeply([ $sink->lines ], [ "three\n" ], 'got expected output from $r');
$sink->reset;


$source->messages(
  [ row => [ qw(3 5 7) ] ],
  [ row => [ qw(one two three) ] ],
);

$perl->perl_code('print "$row[1]-$row[0]\n"');

is($app->test_run_machine, '', 'multiple rows processed successfully');
is_deeply([ $sink->lines ], [ "5-3\n", "two-one\n", ],
  'got expected output from @row');
$sink->reset;


$source->messages(
  [ row => [ qw(3 5 7) ] ],
  [ row => [ qw(one two three) ] ],
  [ row => [ "one\ntwo\n3\n", 'NULL', "At\nLast!"] ],
);

$perl->perl_code('
  my $first = shift @row;
  print "$r->[1] ($first)\n"
');

is($app->test_run_machine, '', 'shift caused no problem for multi-row input');
is_deeply([ $sink->lines ], [ 
    "7 (3)\n",
    "three (one)\n",
    "At\n",
    "Last! (one\n",
    "two\n",
    "3\n",
    ")\n",
  ], 'got expected output');
$sink->reset;

