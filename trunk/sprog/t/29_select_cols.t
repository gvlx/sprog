use strict;
use warnings;

use Test::More tests => 39;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::SelectColumns');

my $app = TestApp->make_test_app;

my($source, $cols, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::SelectColumns
  ListSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($cols, 'Sprog::Gear::SelectColumns', 'filter gear');
isa_ok($cols, 'Sprog::Gear',                'filter gear also');

ok($cols->has_input, 'has input');
ok($cols->has_output, 'has output');
is($cols->input_type,  'A', 'correct input connector type (list)');
is($cols->output_type, 'A', 'correct output connector type (list)');
is($cols->title, 'Select Columns', 'title looks ok');
like($cols->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($cols->columns, '', 'default column list is blank');
is($cols->base, '1', 'default base is 1');

my @data = (
  [ row => [ qw(one two three four five) ] ],
  [ row => [ qw(a b c d e) ] ],
  [ row => [ qw(Monday Tuesday Wednesday Thursday) ] ],
);

$source->messages(@data);

like($app->test_run_machine, qr/You must select some columns/, 
  "can't run gear without selecting columns");
$sink->reset;

$cols->columns('b');

like($app->test_run_machine, qr/Error in column list at: 'b'/,
  "caught bad column number");

$cols->columns('1,c');

like($app->test_run_machine, qr/Error in column list at: 'c'/,
  "caught bad column number after good");

$cols->columns('1,2-3,-d');

like($app->test_run_machine, qr/Error in column list at: '-d'/,
  "caught bad column number after good range");

$cols->columns('1,3-2,-d');

like($app->test_run_machine, qr/Error in column list at: '3-2'/,
  "caught reversed range");

$cols->columns('1,2-3,1-,-e');

like($app->test_run_machine, qr/Error in column list at: '-e'/,
  "caught bad column after range-to-end");

$cols->columns('1,2-3,1-,-2,-f');

like($app->test_run_machine, qr/Error in column list at: '-f'/,
  "caught bad column after range-from-start");

$cols->columns('1');

is($app->test_run_machine, '',
  "single column number parsed correctly");

is_deeply([ $sink->rows ], [
    [ 'one' ],
    [ 'a' ],
    [ 'Monday' ],
  ], "got expected output from column '1'");


$source->messages(@data);

$cols->columns('3,1');

is($app->test_run_machine, '',
  "two column numbers parsed correctly");

is_deeply([ $sink->rows ], [
    [ 'three', 'one' ],
    [ 'c', 'a' ],
    [ 'Wednesday', 'Monday' ],
  ], "got expected output from columns '3,1'");


$source->messages(@data);

$cols->columns('2-3');

is($app->test_run_machine, '',
  "range parsed correctly");

is_deeply([ $sink->rows ], [
    [ 'two', 'three' ],
    [ 'b', 'c' ],
    [ 'Tuesday', 'Wednesday' ],
  ], "got expected output from columns '2-3'");


$source->messages(@data);

$cols->columns('3,1-2');

is($app->test_run_machine, '',
  "number followed by range parsed correctly");

is_deeply([ $sink->rows ], [
    [ 'three', 'one', 'two' ],
    [ 'c', 'a', 'b' ],
    [ 'Wednesday', 'Monday', 'Tuesday' ],
  ], "got expected output from columns '3,1-2'");


$source->messages(@data);

$cols->columns('3,-2');

is($app->test_run_machine, '',
  "number followed by range-from-start parsed correctly");

is_deeply([ $sink->rows ], [
    [ 'three', 'one', 'two' ],
    [ 'c', 'a', 'b' ],
    [ 'Wednesday', 'Monday', 'Tuesday' ],
  ], "got expected output from columns '3,-2'");


$source->messages(@data);

$cols->columns('2,4-');

is($app->test_run_machine, '',
  "number followed by range-to-end parsed correctly");

is_deeply([ $sink->rows ], [
    [ 'two', 'four', 'five' ],
    [ 'b', 'd', 'e' ],
    [ 'Tuesday', 'Thursday' ],
  ], "got expected output from columns '2,4-'");


$source->messages(@data);

$cols->columns('2, 5 ,2 , 12');

is($app->test_run_machine, '',
  "repeated column and missing columns with spaces parsed correctly");

is_deeply([ $sink->rows ], [
    [ 'two', 'five', 'two', '' ],
    [ 'b', 'e', 'b', '' ],
    [ 'Tuesday', '', 'Tuesday', '' ],
  ], "got expected output from columns '2, 5 ,2 , 12'");


$source->messages(@data);

$cols->columns('0');

like($app->test_run_machine, qr/Error in column list at: '0'/,
  "column number 0 rejected when base = 1");


$cols->base('0');
$cols->columns('0');

is($app->test_run_machine, '',
  "column number 0 accepted when base = 0");

is_deeply([ $sink->rows ], [
    [ 'one' ],
    [ 'a' ],
    [ 'Monday' ],
  ], "got expected output from column '0'");



$source->messages(@data);

$cols->columns('-1');

is($app->test_run_machine, '',
  "range-from-start parsed OK when base = 0");

is_deeply([ $sink->rows ], [
    [ 'one', 'two' ],
    [ 'a', 'b' ],
    [ 'Monday', 'Tuesday' ],
  ], "got expected output from columns '-1'");


