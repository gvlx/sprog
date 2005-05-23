use strict;
use warnings;

use Test::More tests => 16;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::CSVSplit');

my $app = TestApp->make_test_app;

my($source, $splitter, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::CSVSplit
  ListSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($splitter, 'Sprog::Gear::CSVSplit',    'splitter gear');
isa_ok($splitter, 'Sprog::Gear::InputByLine', 'splitter gear also');
isa_ok($splitter, 'Sprog::Gear',              'splitter gear also');
ok($splitter->has_input, 'has input');
ok($splitter->has_output, 'has output');
is($splitter->input_type,  'P', 'correct input connector type (pipe)');
is($splitter->output_type, 'A', 'correct input connector type (list)');
is($splitter->title, 'CSV Split', 'title looks ok');
ok($splitter->no_properties, 'has no properties');

$source->messages(
  [ data => "one,two,three\n" ],
);

is($app->test_run_machine, '', 'one line of data processed with no errors');

is_deeply([ $sink->rows ], [
  [ 'one', 'two', 'three' ],
], "got the expected list of field values");


$source->messages(
  [ data => "one,two,three\nfirst" ],
  [ data => ",second,third" ],
  [ data => "\nein,zwei,drei\n" ],
);

is($app->test_run_machine, '', 'multiple lines of data processed with no errors');

is_deeply([ $sink->rows ], [
  [ 'one', 'two', 'three' ],
  [ 'first', 'second', 'third' ],
  [ 'ein', 'zwei', 'drei' ],
], "got the expected list of lists of field values");


