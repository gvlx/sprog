use strict;
use warnings;

use Test::More 'no_plan';# tests => 17;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TextGear');
use_ok('Sprog::Gear::ReadFile');
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
is($sink->title, '', 'default title is empty string');
$sink->text('');

my $reader = Sprog::Gear::ReadFile->new(app => $app, machine => $machine);

isa_ok($reader, 'Sprog::Gear::ReadFile');
isa_ok($reader, 'Sprog::Gear::InputFromFH');
isa_ok($reader, 'Sprog::Gear');

$reader->next($sink);
$reader->filename(File::Spec->catfile('t', 'bogus.txt'));

$reader->prime;

like($app->alerts, qr/Can't open ".*?bogus.txt"/,
  "correct alert generated when file does not exist");


$app->alerts('');

$reader->filename(File::Spec->catfile('t', 'rgb.txt'));

$sink->prime;
$reader->prime;

is($app->alerts, '', "successfully opened named file");

$reader->send_data;

my $io_queue = $app->io_readers || [];

is(scalar(@$io_queue), 1, "one io_reader message queued");

$reader->send_data;

is(scalar(@$io_queue), 1, "still only one io_reader message queued");

my $sub = shift @$io_queue;
is(scalar(@$io_queue), 0, "de-queued the io_reader message");
$sub->();

$reader->send_data;    # Go for the EOF event

is(scalar(@$io_queue), 1, "one new io_reader message queued");

$sub = shift @$io_queue;
is(scalar(@$io_queue), 0, "de-queued the io_reader message");
$sub->();

1 while($sink->turn_once);

is(scalar(@$io_queue), 0, "no io_reader messages queued after EOF");

is($reader->fh, undef, "file handle has been disposed");

$reader->send_data;

like($sink->text, qr{
  ^
    \#FF0000 \s+ Red    \s+
    \#00FF00 \s+ Green  \s+
    \#0000FF \s+ Blue   \s+
    \#FFFF00 \s+ Yellow \s+
    \#00FFFF \s+ Cyan   \s+
    \#FF00FF \s+ Purple \s+
  $
}xs, "read contents of file");
