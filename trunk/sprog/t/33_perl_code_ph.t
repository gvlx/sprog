use strict;
use Sprog::TestHelper tests => -1;

use_ok('TestApp');
use_ok('Sprog::Gear::PerlCodePH');

my $app = TestApp->make_test_app;

my($source, $perl, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::PerlCodePH
  RecordSink
));
is($app->alerts, '', 'no alerts while creating machine');


isa_ok($perl, 'Sprog::Gear::PerlCodePH',  'perl gear     ');
isa_ok($perl, 'Sprog::Gear::InputByLine', 'perl gear also');
isa_ok($perl, 'Sprog::Gear',              'perl gear also');

ok($perl->has_input, 'has input');
ok($perl->has_output, 'has output');
is($perl->input_type,  'P', 'correct input connector type (pipe)');
is($perl->output_type, 'H', 'correct input connector type (list)');
is($perl->title, 'Perl Code', 'title looks ok');
like($perl->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($perl->perl_code, '', 'default Perl code is blank');


my @data = (
  [ data => "12:36:05 mike arrived\n" ],
  [ data => "12:38:12 bob left\n" ],
  [ data => "12:39:46 kate arrived\n" ],
);
$source->messages(@data);

is($app->test_run_machine, '', 'three lines processed without errors');
is_deeply([ $sink->records ], [ ], 'no output by default');
$sink->reset;


$perl->perl_code('{');

like($app->test_run_machine, qr/syntax error/,
  'syntax error captured successfully');


$source->messages(@data);

$perl->perl_code('@rec{qw(time name op)} = split / /;');

is($app->test_run_machine, '', 'simple Perl snippet processed three rows');
is_deeply([ $sink->records ], [
    { 'time' => "12:36:05", 'name' => "mike", 'op' => "arrived\n" },
    { 'time' => "12:38:12", 'name' => "bob",  'op' => "left\n"    },
    { 'time' => "12:39:46", 'name' => "kate", 'op' => "arrived\n" },
  ], 'got expected output');
$sink->reset;


@data = (
  [ data => "12:36:05 mike arrived\n12:38:12 "  ],
  [ data => "bob left\n12:39:46 kate arrived\n" ],
);
$source->messages(@data);

$perl->perl_code('
  @rec{qw(time name op)} = /^\d+:(\d+:\d+)\s+(\S+)\s+(\w+)/;
  next LINE if $rec{name} eq "bob";
');

is($app->test_run_machine, '', 'passed a multi-line text block');
is_deeply([ $sink->records ], [
    { 'time' => "36:05", 'name' => "mike", 'op' => "arrived" },
    { 'time' => "39:46", 'name' => "kate", 'op' => "arrived" },
  ], 'got expected output');
$sink->reset;

