use strict;
use warnings;

use Test::More tests => 19;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::TemplateTT2');

my $app = TestApp->make_test_app;

my($source, $filter, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::TemplateTT2
  LineSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($filter, 'Sprog::Gear::TemplateTT2', 'filter gear');
isa_ok($filter, 'Sprog::Gear',              'filter gear also');

ok($filter->has_input, 'has input');
ok($filter->has_output, 'has output');
is($filter->input_type,  'H', 'correct input connector type (record)');
is($filter->output_type, 'P', 'correct output connector type (pipe)');
is($filter->title, 'Apply Template (TT2)', 'title looks ok');
like($filter->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($filter->template, '', "default template is blank");

$source->messages(
  [ record => { name => 'Bob' } ],
);

is($app->test_run_machine, '', 'processed a record without errors');

is_deeply([ $sink->lines ], [ ], "got no output - as expected");


$filter->template(qq{Bad template [% my->name %]\n});

$source->messages(
  [ record => { name => 'Bob' } ],
);

like($app->test_run_machine, 
  qr/parse\s+error.*my->name/si, 
  'template error generated expected alert');


$filter->template(qq{My name is [% name %]\n});

$source->messages(
  [ record => { name => 'Bob' } ],
);

is($app->test_run_machine, '', 'ran machine with a template defined');

is_deeply([ $sink->lines ], [
    "My name is Bob\n",
  ], "got the expected output");


$filter->template(qq{Name: [% name %]\nNickname: [% nick %]\n\n});

$source->messages(
  [ record => { name => 'Bob',  nick => 'John Wayne' } ],
  [ record => { name => 'Kate', nick => 'Bob' } ],
);

is($app->test_run_machine, '', 'ran machine with a template defined');

is_deeply([ $sink->lines ], [
    "Name: Bob\n",
    "Nickname: John Wayne\n",
    "\n",
    "Name: Kate\n",
    "Nickname: Bob\n",
    "\n",
  ], "got the expected output");


