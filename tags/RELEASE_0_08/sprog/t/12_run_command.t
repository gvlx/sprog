
use strict;
use Test::More;
use File::Spec;

my $test_command;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');

  $test_command = q{perl -le "print foreach(qw(one two three))"};
  my $out = `$test_command 2>&1`;
  if($out !~ /one\s+two\s+three/s) {
    plan skip_all => 'unable to run external command';
  }
};

plan tests => 23;

use_ok('TextGear');
use_ok('Sprog::Gear::CommandIn');
use_ok('Sprog::ClassFactory');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'         => 'DummyApp',
  '/app/machine' => 'DummyMachine',
);

isa_ok($app, 'DummyApp');

my $machine = $app->machine;
isa_ok($machine, 'DummyMachine');

my $sink = TextGear->new(machine => $machine);
isa_ok($sink, 'TextGear');
$sink->text('');

my $src = Sprog::Gear::CommandIn->new(app => $app, machine => $machine);

isa_ok($src, 'Sprog::Gear::CommandIn');
isa_ok($src, 'Sprog::Gear::InputFromFH');
isa_ok($src, 'Sprog::Gear');
is($src->title, 'Run a Command', 'title looks good');
like($src->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');


$src->next($sink);
$src->command(undef);

$src->prime;

like($app->alerts, qr/You must enter an input command/,
  "correct alert generated when command undefined");
$app->alerts('');


$src->command('');

$src->prime;

like($app->alerts, qr/You must enter an input command/,
  "correct alert generated when command blank");
$app->alerts('');


SKIP: {
  open my $save_fd, '>&', STDERR;
  open STDERR, '>', '/dev/null' or skip 'unable to redirect STDERR', 1;

  $src->command(File::Spec->catfile('t', 'bogus.txt'));

  $src->prime;

  open STDERR, '>&', $save_fd or die "$!";

  like($app->alerts, qr/Can't run ".*?bogus.txt.*"/,
    "correct alert generated for bad command");
  $app->alerts('');
}

$src->command($test_command);

$sink->prime;
$src->prime;

is($app->alerts, '', "successfully started command");

$src->send_data;

my $io_queue = $app->io_readers || [];

is(scalar(@$io_queue), 1, "one io_reader message queued");

$src->send_data;

is(scalar(@$io_queue), 1, "still only one io_reader message queued");

my $sub = shift @$io_queue;
is(scalar(@$io_queue), 0, "de-queued the io_reader message");
$sub->();

$src->send_data;    # Go for the EOF event

is(scalar(@$io_queue), 1, "one new io_reader message queued");

$sub = shift @$io_queue;
is(scalar(@$io_queue), 0, "de-queued the io_reader message");
$sub->();

1 while($sink->turn_once);

is(scalar(@$io_queue), 0, "no io_reader messages queued after EOF");

is($src->fh, undef, "file handle has been disposed");

$src->send_data;

like($sink->text, qr{
  ^
    one   \s+
    two   \s+
    three \s+
  $
}xs, "read output from command");
