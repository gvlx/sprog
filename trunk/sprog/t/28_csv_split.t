use strict;
use Sprog::TestHelper tests => 31;

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
isa_ok($splitter, 'Sprog::Gear',              'splitter gear also');
ok($splitter->has_input, 'has input');
ok($splitter->has_output, 'has output');
is($splitter->input_type,  'P', 'correct input connector type (pipe)');
is($splitter->output_type, 'A', 'correct input connector type (list)');
is($splitter->title, 'CSV Split', 'title looks ok');
ok($splitter->no_properties, 'has no properties');


$source->messages(
  [ file_start => "data.csv" ],
  [ data => "\n" ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'parsed one blank line');

is_deeply([ $sink->rows ], [ [ '' ], ], "got one empty field");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => ",\n" ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'parsed a line with only a comma');

is_deeply([ $sink->rows ], [ [ '', '' ], ], "got two empty fields");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => "one,t" ],
  [ data => "wo,three,four\n" ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'parsed a broken line of four fields');

is_deeply([ $sink->rows ], [
  [ 'one', 'two', 'three', 'four' ],
], "got the expected list of field values");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => ",two,three,\n" ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'parsed line with leading and trailing commas');

is_deeply([ $sink->rows ], [
  [ '', 'two', 'three', '' ],
], "got the expected list of field values");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => qq(one,"two,three",four\n) ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'parsed a line containing a quoted comma');

is_deeply([ $sink->rows ], [
  [ 'one', 'two,three', 'four' ],
], "got the expected list of field values");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => qq(one,"two"",""""three",four\n) ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'parsed a line containing escaped quotes');

is_deeply([ $sink->rows ], [
  [ 'one', 'two",""three', 'four' ],
], "got the expected list of field values");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => qq(one,"two\nthree",four\n) ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'parsed a field with a quoted newline');

is_deeply([ $sink->rows ], [
  [ 'one', "two\nthree", 'four' ],
], "got the expected list of field values");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => qq(one,"two\n) ],
  [ data => qq(three",four\n) ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'same data but split on quoted newline');

is_deeply([ $sink->rows ], [
  [ 'one', "two\nthree", 'four' ],
], "got the expected list of field values");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => "one,two,three\nfirst" ],
  [ data => ",second,third" ],
  [ data => qq(\nein,zwei,drei\n,,\n"""Home"", sweet home",\n) ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'complex assortment of well formed fields');

is_deeply([ $sink->rows ], [
  [ 'one', 'two', 'three' ],
  [ 'first', 'second', 'third' ],
  [ 'ein', 'zwei', 'drei' ],
  [ '', '', '' ],
  [ '"Home", sweet home', '' ],
], "got the expected list of lists of field values");


$source->messages(
  [ file_start => "data.csv" ],
  [ data => qq(one"two,three\n"1"first) ],
  [ data => qq(-second,third) ],
  [ data => qq(\nfields,with,no newline) ],
  [ file_end => "data.csv" ],
);

is($app->test_run_machine, '', 'survived some badly formed lines');

is_deeply([ $sink->rows ], [
  [ 'one"two', 'three' ],
  [ '1first-second', 'third' ],
  [ 'fields', 'with', 'no newline' ],
], "got the expected list of lists of field values");


