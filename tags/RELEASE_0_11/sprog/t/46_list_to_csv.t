use strict;
use Sprog::TestHelper tests => 23;

use_ok('TestApp');
use_ok('Sprog::Gear::ListToCSV');

my $app = TestApp->make_test_app;

my($source, $filter, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::ListToCSV
  LineSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($filter, 'Sprog::Gear::ListToCSV', 'filter gear');
isa_ok($filter, 'Sprog::Gear',            'filter gear also');

ok($filter->has_input, 'has input');
ok($filter->has_output, 'has output');
is($filter->input_type,  'A', 'correct input connector type (list)');
is($filter->output_type, 'P', 'correct output connector type (pipe)');
is($filter->title, 'List to CSV', 'title looks ok');
ok($filter->no_properties, "filter gear has no properties");

$source->messages(
  [ row => [ qw(surname firstname) ] ],
  [ row => [ qw(Bloggs Joe) ] ],
  [ row => [ qw(Smith Jane) ] ],
);

is($app->test_run_machine, '', 'processed 3 rows without errors');

is_deeply([ $sink->lines ], [
    "surname,firstname\n",
    "Bloggs,Joe\n",
    "Smith,Jane\n",
  ], "got expected output");


$source->messages(
  [ row => [ qw(one) ] ],
  [ row => [ qw(two three) ] ],
  [ row => [ qw(four five six) ] ],
);

is($app->test_run_machine, '', 'processed different length rows');

is_deeply([ $sink->lines ], [
    "one\n",
    "two,three\n",
    "four,five,six\n",
  ], "got expected output");


$source->messages(
  [ row => [ 'Sprat, Jack', '8 Main Street, Nurseryville'] ],
);

is($app->test_run_machine, '', 'processed row with embedded commas');

is_deeply([ $sink->lines ], [
    qq("Sprat, Jack","8 Main Street, Nurseryville"\n),
  ], "got expected output");


$source->messages(
  [ row => [ 'Jenny', 'the "Hulk"', 'Smith' ] ],
);

is($app->test_run_machine, '', 'processed row with embedded quotes');

is_deeply([ $sink->lines ], [
    qq(Jenny,"the ""Hulk""",Smith\n),
  ], "got expected output");


$source->messages(
  [ row => [ 'Thomas', 'Thumb', "The Little House\nUp the Road", 'Monday' ] ],
);

is($app->test_run_machine, '', 'processed row with embedded newline');

is_deeply([ $sink->lines ], [
    qq(Thomas,Thumb,"The Little House\n),
    qq(Up the Road",Monday\n),
  ], "got expected output");


$source->messages(
  [ row => [ "one\ntwo\nthree", 'Jimmy "Razor" Polenti', 'EOL'   ] ],
  [ row => [ 'three, two, one "Blast off!"', "red\tgreen\tblue"  ] ],
  [ row => [ qq(alpha,\nbeta,"Gamer"\tHippo), qw(red green blue) ] ],
  [ row => [ qw(Monday Wednesday Friday) ] ],
);

is($app->test_run_machine, '', 'processed rows with embedded everything');

is_deeply([ $sink->lines ], [
    qq("one\n),
    qq(two\n),
    qq(three","Jimmy ""Razor"" Polenti",EOL\n),
    qq("three, two, one ""Blast off!""","red\tgreen\tblue"\n),
    qq("alpha,\n),
    qq(beta,""Gamer""\tHippo",red,green,blue\n),
    qq(Monday,Wednesday,Friday\n),
  ], "got expected output");

