use strict;
use warnings;

use Test::More tests => 21;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::TextInput');
use_ok('Sprog::Gear::CommandFilter');
use_ok('LineSink');

my $app = TestApp->make_test_app;

my($src, $filter, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::CommandFilter
  LineSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($filter, 'Sprog::Gear::CommandFilter', 'filter gear');
isa_ok($filter, 'Sprog::Gear::OutputToFH',    'filter gear also');
isa_ok($filter, 'Sprog::Gear::InputFromFH',   'filter gear also');
isa_ok($filter, 'Sprog::Gear',                'filter gear also');

ok($filter->has_input,   'has input');
ok($filter->has_output,  'has output');
is($filter->input_type,  'P', 'input connector is a pipe');
is($filter->output_type, 'P', 'output connector is a pipe');
is($filter->title, 'Run Filter Command', 'title looks ok');
like($filter->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');

my $data = "January\nFebruary\nMarch\nApril\n";

$src->text($data);
like($app->test_run_machine, qr/you must enter a filter command/i, 
  'got expected alert when no command entered');

SKIP: {
  open my $save_fd, '>&', STDERR;
  open STDERR, '>', '/dev/null' or skip 'unable to redirect STDERR', 1;

  $filter->command('bogus_non_existant_script.pl');
  is($app->test_run_machine, '', 
    "unfortunately exec errors after the fork aren't caught");

  open STDERR, '>&', $save_fd or die "$!";
}

$filter->command(q(perl -e '$|=1; print uc while sysread STDIN, $_, 1'));
$src->text($data);
is($app->test_run_machine, '', 'successfully executed an unbuffered filter');

is_deeply(
  [ $sink->lines ],
  [
    "JANUARY\n",
    "FEBRUARY\n",
    "MARCH\n",
    "APRIL\n",
  ],
  'data was filtered successfully'
);

$filter->command(q(perl -pe 's/a/[A]/ig'));
$src->text($data);
is($app->test_run_machine, '', 'successfully executed a buffered filter');

is_deeply(
  [ $sink->lines ],
  [
    "J[A]nu[A]ry\n",
    "Febru[A]ry\n",
    "M[A]rch\n",
    "[A]pril\n",
  ],
  'data was filtered successfully'
);
