use strict;
use warnings;

use Test::More tests => 27;

use File::Spec;
use YAML;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}


use_ok('Sprog::ClassFactory');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'         => 'TestApp',
  '/app/machine' => 'TestMachine',
  '/app/view'    => 'DummyView',
);

isa_ok($app, 'TestApp');
isa_ok($app, 'Sprog');

my $machine = $app->machine;
isa_ok($machine, 'TestMachine');
isa_ok($machine, 'Sprog::Machine');


my $test_file = File::Spec->catfile('t', 'ffff.sprog'); # Does not exist yet
unlink($test_file); # just in case

$app->load_from_file($test_file);
like($app->alerts, qr/Error reading .*?ffff.sprog/, 
  'correct alert when reading from non-existant file');
$app->alerts('');


unlink($test_file);
open my $out, '>', $test_file or die "open($test_file): $!";
close($out);

$app->load_from_file($test_file);
like($app->alerts, qr/Error reading .*?ffff.sprog\s+Unrecognised data format/, 
  'correct alert when reading from empty file');
$app->alerts('');


unlink($test_file);
open $out, '>', $test_file or die "open($test_file): $!";
print $out "Hello World!\n";
close($out);

$app->load_from_file($test_file);
like($app->alerts, qr/Error reading .*?ffff.sprog\s+Unrecognised data format/, 
  'correct alert when reading from malformed file');
$app->alerts('');


unlink($test_file);
open $out, '>', $test_file or die "open($test_file): $!";
print $out YAML::Dump([
  'Some Bogus App',
  'x',
  {},          # Machine-level properties
  [],          # Gears and their properties
]);
close($out);

$app->load_from_file($test_file);
like($app->alerts, qr/
  Unrecognised \s file \s type             \s+
  Expected \s Application \s ID: \s Sprog  \s+
  Got: \s Some \s Bogus \s App
/xs, 
  'correct alert when App ID is incorrect');
$app->alerts('');


unlink($test_file);
open $out, '>', $test_file or die "open($test_file): $!";
print $out YAML::Dump([
  'Sprog',
  'x',
  {},          # Machine-level properties
  [],          # Gears and their properties
]);
close($out);

$app->load_from_file($test_file);
like($app->alerts, qr/
  Unrecognised \s file \s version     \s+
  Expected \s Format \s Version: \s 1 \s+
  Got: \s x
/xs, 
  'correct alert when file format version is incorrect');
$app->alerts('');


unlink($test_file);
open $out, '>', $test_file or die "open($test_file): $!";
print $out YAML::Dump([
  'Sprog',
  '1',
  {},          # Machine-level properties
  [],          # Gears and their properties
]);
close($out);

$app->load_from_file($test_file);
is($app->alerts, '', 'successfully loaded file with no gears');
$app->alerts('');


my $bad_file = File::Spec->catfile('bogus_dir', 'file.sprog');
$app->filename($bad_file);
$app->file_save;
like($app->alerts, qr/Error saving file.*bogus_dir.*file.sprog/s, 
  'correct alert when file_save fails');
$app->alerts('');


$app->machine->add_gear('Bogus::Gear::Class');
like($app->alerts, qr/Unable to create a Bogus::Gear::Class object/,
  'correct alert when add_gear fails');
$app->alerts('');

my $head = $app->machine->head_gear;
is($head, undef, 'correct value returned from head_gear');


like($app->test_run_machine, qr/^You must add an input gear\s+<undef>/s,
  'correct alert when running an empty machine');
$app->alerts('');


$app->machine->add_gear('Sprog::Gear::ReadFile');
is($app->alerts, '', 'successfully added a ReadFile gear');
$app->alerts('');

my $reader = $app->machine->head_gear;
isa_ok($reader, 'Sprog::Gear::ReadFile', 'return value from head_gear');


like($app->test_run_machine, qr/^You must complete your machine with an output gear\s+<undef>/s,
  'correct alert when running an incomplete machine');
$app->alerts('');


$INC{'AcceptNothingGear.pm'} = __FILE__;
my $last = $app->machine->add_gear('AcceptNothingGear');
is($app->alerts, '', 'added a test gear to the machine');
$app->alerts('');

$reader->next($last);
isa_ok($reader->last, 'AcceptNothingGear', 'the last gear');


like($app->test_run_machine, qr/^I will not accept input!/,
  'building of gear chain was successfully aborted');
$app->alerts('');

is($app->machine->turn_gears, 0, "can't turn gears unless machine is running");

$app->detach_gear($last);
ok(!$reader->next, 'last gear is no longer attached to first');
ok($app->machine->parts->{$last->id}, 'but still exists');

$app->machine->delete_gear_by_id($last->id);
ok(!exists $app->machine->parts->{$last->id}, 'successfully removed last gear');


$INC{'StopOnInput.pm'} = __FILE__;
$last = $app->machine->add_gear('StopOnInput');
is($app->alerts, '', 'added another test gear to the machine');
$app->alerts('');
$reader->next($last);
$reader->filename(File::Spec->catfile('t', 'rgb.txt'));

like($app->test_run_machine, qr/^Stopped/, 'stop method seems to work');
$app->alerts('');

unlink($test_file);

exit;


package AcceptNothingGear;

use base qw(Sprog::Gear::Bottom);

sub prime {
  my $self = shift;

  return $self->app->alert('I will not accept input!');
}


package StopOnInput;

use base qw(Sprog::Gear::Bottom);

sub data {
  my $self = shift;

  $self->app->alert('Stopped');
  $self->app->stop_machine;
}


1;

