use Sprog::TestHelper tests => 20;

use_ok('TestApp');
use_ok('Sprog::Gear::SelectFields');

my $app = TestApp->make_test_app;

my($source, $fields, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::SelectFields
  ListSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($fields, 'Sprog::Gear::SelectFields', 'filter gear');
isa_ok($fields, 'Sprog::Gear',               'filter gear also');

ok($fields->has_input, 'has input');
ok($fields->has_output, 'has output');
is($fields->input_type,  'H', 'correct input connector type (record)');
is($fields->output_type, 'A', 'correct output connector type (list)');
is($fields->title, 'Select Fields', 'title looks ok');
like($fields->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($fields->fields, '', 'default field list is blank');


my @data = (
  [ record => { first_name => 'Bob',  surname => 'Smith',  age => 26 } ],
  [ record => { first_name => 'Kate', surname => 'Jones',  age => 32 } ],
  [ record => { first_name => 'John', surname => 'Friday', age => 48 } ],
);

$source->messages(@data);

like($app->test_run_machine, qr/You must select some fields/, 
  "can't run gear without selecting fields");
$sink->reset;


$fields->fields('surname');
$source->messages(@data);

is($app->test_run_machine, '', "selected one field from three records");
is_deeply([ $sink->rows ], [
    [ 'Smith'  ],
    [ 'Jones'  ],
    [ 'Friday' ],
  ], "got expected output from field 'surname'");


$fields->fields('  age ,  first_name ');
$source->messages(@data);

is($app->test_run_machine, '', "selected two fields from three records");
is_deeply([ $sink->rows ], [
    [ 26, 'Bob'  ],
    [ 32, 'Kate' ],
    [ 48, 'John' ],
  ], "got expected output from field '  age ,  first_name '");


$fields->fields('height,age');
$source->messages(@data);

is($app->test_run_machine, '', "selected one bogus field and one good one");
my @result = $sink->rows;
is_deeply([ @result ], [
    [ '', 26 ],
    [ '', 32 ],
    [ '', 48 ],
  ], "got expected output from field 'height,age'");

ok(defined($result[0]->[0]), "undefined fields passed as ''");



