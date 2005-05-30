use strict;
use File::Spec;

my $test_command;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');

  $test_command = q{perl -le "print foreach(qw(one two three))"};
  my $out = `$test_command 2>&1`;
  if($out !~ /one\s+two\s+three/s) {
    use Test::More;
    plan skip_all => 'unable to run external command';
  }
};

use Sprog::TestHelper tests => 13;

use_ok('TestApp');

my $app = TestApp->make_test_app;

my($src, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::CommandIn
  TextSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($sink, 'TextSink');
$sink->text('');

isa_ok($src, 'Sprog::Gear::CommandIn');
isa_ok($src, 'Sprog::Gear::InputFromFH');
isa_ok($src, 'Sprog::Gear');
is($src->title, 'Run Command', 'title looks good');
like($src->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');


$src->command(undef);

like($app->test_run_machine, qr/You must enter an input command/,
  "correct alert generated when command undefined");


$src->command('');

like($app->test_run_machine, qr/You must enter an input command/,
  "correct alert generated when command blank");


SKIP: {
  open my $save_fd, '>&', STDERR;
  open STDERR, '>', '/dev/null' or skip 'unable to redirect STDERR', 1;

  $src->command(File::Spec->catfile('t', 'bogus.txt'));

  like($app->test_run_machine, qr/Can't run ".*?bogus.txt.*"/,
    "correct alert generated for bad command");

  open STDERR, '>&', $save_fd or die "$!";
}

$src->command($test_command);

is($app->test_run_machine, '', "run completed without timeout or alerts");

like($sink->text, qr{
  ^
    one   \s+
    two   \s+
    three \s+
  $
}xs, "read output from command");
