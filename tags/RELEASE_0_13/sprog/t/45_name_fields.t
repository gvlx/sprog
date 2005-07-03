use strict;
use Sprog::TestHelper tests => 22;

use_ok('TestApp');
use_ok('Sprog::Gear::NameFields');

my $app = TestApp->make_test_app;

my($source, $filter, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::NameFields
  RecordSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($filter, 'Sprog::Gear::NameFields', 'filter gear     ');
isa_ok($filter, 'Sprog::Gear',             'filter gear also');

ok($filter->has_input, 'has input');
ok($filter->has_output, 'has output');
is($filter->input_type,  'A', 'correct input connector type (list)');
is($filter->output_type, 'H', 'correct output connector type (record)');
is($filter->title, 'Add Field Names', 'title looks ok');
like($filter->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($filter->names, '', 'default name list is blank');

like($app->test_run_machine, qr/You must enter some field names/, 
  'got expected error when no names entered');

$filter->names('surname,first_name');
$source->messages(
  [ row => [ qw(Bloggs Joe) ] ],
  [ row => [ qw(Smith Jane) ] ],
);

is($app->test_run_machine, '',
  'successfully processed two rows with two column names');

is_deeply([ $sink->records ], [
    {
      first_name => 'Joe',
      surname    => 'Bloggs',
    },
    {
      first_name => 'Jane',
      surname    => 'Smith',
    },
  ], "got expected output");


$filter->names(' surname , first_name ');
$source->messages(
  [ row => [ 'Van Nisseldorf', 'Bob'         ] ],
  [ row => [ 'Plumley-Walker', 'Frank Lloyd' ] ],
);

is($app->test_run_machine, '',
  'processed two rows using column names with extra spaces');

is_deeply([ $sink->records ], [
    {
      first_name => 'Bob',
      surname    => 'Van Nisseldorf',
    },
    {
      first_name => 'Frank Lloyd',
      surname    => 'Plumley-Walker',
    },
  ], "got expected output");


$filter->names(' surname first_name ');
$source->messages(
  [ row => [ 'Van Nisseldorf', 'Bob'         ] ],
  [ row => [ 'Plumley-Walker', 'Frank Lloyd' ] ],
);

is($app->test_run_machine, '',
  'two columns of data into one column name with embedded space');

is_deeply([ $sink->records ], [
    {
      'surname first_name' => 'Van Nisseldorf',
    },
    {
      'surname first_name' => 'Plumley-Walker',
    },
  ], "got expected output");


$filter->names('surname, first_name, dob');
$source->messages(
  [ row => [ 'Van Nisseldorf', 'Bob', '1958-10-03' ] ],
  [ row => [ 'Plumley-Walker', 'Frank Lloyd' ] ],
  [ row => [ 'Eccles' ] ],
  [ row => [ 'Walker', 'Jameson', '1972-07-18' ] ],
);

is($app->test_run_machine, '',
  'processed rows with missing column values');

my $output = [ $sink->records ];
is_deeply($output, [
    {
      first_name => 'Bob',
      surname    => 'Van Nisseldorf',
      dob        => '1958-10-03',
    },
    {
      first_name => 'Frank Lloyd',
      surname    => 'Plumley-Walker',
      dob        => '',
    },
    {
      first_name => '',
      surname    => 'Eccles',
      dob        => '',
    },
    {
      first_name => 'Jameson',
      surname    => 'Walker',
      dob        => '1972-07-18',
    },
  ], "got expected output");

ok(defined($output->[1]->{dob}), "missing value came through as ''");


