use strict;
use Sprog::TestHelper tests => 23;

use_ok('TestApp');
use_ok('Sprog::Gear::PerlCodeHP');

my $app = TestApp->make_test_app;

my($source, $perl, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::PerlCodeHP
  LineSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($perl, 'Sprog::Gear::PerlCodeHP', 'perl gear     ');
isa_ok($perl, 'Sprog::Gear::PerlBase',   'perl gear also');
isa_ok($perl, 'Sprog::Gear',             'perl gear also');
ok($perl->has_input, 'has input');
ok($perl->has_output, 'has output');
is($perl->input_type,  'H', 'correct input connector type (record)');
is($perl->output_type, 'P', 'correct input connector type (pipe)');
is($perl->title, 'Perl Code', 'title looks ok');
like($perl->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($perl->perl_code, '', 'default Perl code is blank');

isa_ok($sink, 'LineSink', 'output gear');

my @data = (
  [ record => { surname => 'Jones', first_name => 'Kate', age => 32 } ],
  [ record => { surname => 'Smith', first_name => 'John', age => 27 } ],
);

$source->messages(@data);

is($app->test_run_machine, '', 'successfully processed two messages');
is_deeply([ $sink->lines ], [ ], 'no output by default');
$sink->reset;

$perl->perl_code('{');

like($app->test_run_machine, qr/syntax error/, 'syntax error captured successfully');

$perl->perl_code('print "$r->{surname}\n"');
$source->messages(@data);

is($app->test_run_machine, '', 'compiled code to use $r');
is_deeply([ $sink->lines ], [ "Jones\n", "Smith\n" ], 'got expected output from $r');
$sink->reset;

$perl->perl_code('print "$rec{first_name}\n"');
$source->messages(@data);

is($app->test_run_machine, '', 'compiled code to use %rec');
is_deeply([ $sink->lines ], [ "Kate\n", "John\n" ], 'got expected output from %rec');
$sink->reset;

$perl->perl_code('
  next RECORD if $r->{surname} =~ /jones/i;
  print "$r->{first_name}\n"
');
$source->messages(@data);

is($app->test_run_machine, '', "compiled code to use 'next RECORD'");
is_deeply([ $sink->lines ], [ "John\n" ], 'got expected output');
$sink->reset;

exit;
