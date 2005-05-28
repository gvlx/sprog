use strict;
use warnings;

use Test::More tests => 17;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::ListToRecord');

my $app = TestApp->make_test_app;

my($source, $filter, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::ListToRecord
  RecordSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($filter, 'Sprog::Gear::ListToRecord', 'filter gear');
isa_ok($filter, 'Sprog::Gear',               'filter gear also');

ok($filter->has_input, 'has input');
ok($filter->has_output, 'has output');
is($filter->input_type,  'A', 'correct input connector type (list)');
is($filter->output_type, 'H', 'correct output connector type (record)');
is($filter->title, 'List to Record', 'title looks ok');
ok($filter->no_properties, "filter gear has no properties");

$source->messages(
  [ row => [ qw(surname firstname) ] ],
  [ row => [ qw(Bloggs Joe) ] ],
  [ row => [ qw(Smith Jane) ] ],
);

is($app->test_run_machine, '', 'ran machine without errors');

is_deeply([ $sink->records ], [
    {
      firstname => 'Joe',
      surname   => 'Bloggs',
    },
    {
      firstname => 'Jane',
      surname   => 'Smith',
    },
  ], "got expected output");

$source->messages(
  [ row => [ 'Surname', 'First Name' ] ],
  [ row => [ qw(Bloggs Joe) ] ],
  [ row => [ qw(Smith Jane) ] ],
);

is($app->test_run_machine, '', 'ran machine without errors');

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


$source->messages(
  [ row => [ qw(one two three) ] ],
  [ row => [ qw(1 2) ] ],
  [ row => [ qw(3 4 5 6) ] ],
);

is($app->test_run_machine, '', 'ran machine again without errors');

is_deeply([ $sink->records ], [
    {
      one   => 1,
      two   => 2,
      three => undef,
    },
    {
      one   => 3,
      two   => 4,
      three => 5,
    },
  ], "got expected output (including undefined field)");

