use strict;
use Sprog::TestHelper tests => 48;

use_ok('TestApp');
use_ok('Sprog::MakeCmndGear');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'             => 'TestApp',
  '/app/machine'     => 'TestMachine',
  '/app/eventloop'   => 'Sprog::GlibEventLoop',
  '/app/view'        => 'DummyView',
  '/app/preferences' => 'TestPrefs',
);


my $prefs = $app->prefs;
isa_ok($prefs, 'TestPrefs', 'app->prefs');

my $builder = $app->make_class('/app/make_cmnd_gear', $app);
is($builder, undef, 'command gear builder constructor aborted');
like($app->alerts,
  qr/You must first define your Personal Gear Folder in preferences/i, 
  'because personal gear folder not defined'
);

my $gear_dir = File::Spec->catdir('t', 'xxgears');
$app->set_pref('private_gear_folder' => $gear_dir);
is($prefs->get_pref('private_gear_folder'), $gear_dir, 'set priv gear folder');

$app->reset_alerts;
$builder = $app->make_class('/app/make_cmnd_gear', $app);
is($builder, undef, 'command gear builder constructor aborted again');
like($app->alerts,
  qr/Personal Gear Folder does not exist.*?t.*?xxgears: no such file/si, 
  'because personal gear folder does not exist'
);

$gear_dir = File::Spec->catdir('t', 'gears');
$app->set_pref('private_gear_folder' => $gear_dir);
$app->init_private_path;
$app->reset_alerts;
$builder = $app->make_class('/app/make_cmnd_gear', $app);
is($app->alerts, '', 'constructor did not abort this time');
isa_ok($builder, 'Sprog::MakeCmndGear', 'command gear builder');

is($builder->type,     'filter', 'default type is "filter"');
is($builder->title,    '',       'default title is blank');
is($builder->command,  '',       'default command is blank');
is($builder->keywords, '',       'default keywords is blank');
is($builder->filename, '',       'default filename is blank');

$app->reset_alerts;
$builder->save;
like($app->alerts, qr/You must enter a title/, "can't save without title");

$builder->title('Quick Brown Fox');
$app->reset_alerts;
$builder->save;
like($app->alerts, qr/You must enter a command/, "can't save without command");

$builder->command(q(perl -le 'print "The quick brown fox"'));
$app->reset_alerts;
$builder->save;
like($app->alerts, qr/You must enter a filename/, "can't save without filename");

$builder->keywords('silly sentence');
$builder->filename($builder->default_filename('quick Brown _FOX'));

is($builder->filename, 'QuickBrownFox.pm',
  'output from default_filename() looks good');

$builder->filename('Quick/Brown Fox.pm');
$app->reset_alerts;
$builder->save;
like($app->alerts, qr{Invalid character in filename: '/'},
  "invalid filename blocked save");

$builder->filename('QuickBrownFox');
my $gear_file = File::Spec->catfile($gear_dir, 'QuickBrownFox.pm');
unlink($gear_file);
ok(!-e $gear_file, 'gear file does not exist before save');

ok($builder->save, 'save returned successfully');
ok(-e $gear_file, 'gear file was created');

my $gear_class = 'SprogEx::Gear::QuickBrownFox';
my $info = $app->gear_class_info($gear_class);
isa_ok($info, 'Sprog::GearMetadata', 'object returned by gear_class_info');
is($info->title, 'Quick Brown Fox', 'saved title looks good');
is($info->keywords, 'quick brown fox silly sentence', 
  'saved keywords look good');

$@ = '';
my $gear = eval {
  $app->machine->require_gear_class($gear_class);
  $gear_class->new(app => $app);
};
is("$@", '', 'instantiated the generated class without error');
is($gear->command, q(perl -le 'print "The quick brown fox"'),
  'saved command looks good');


$app->reset_alerts;
$builder = $app->make_class('/app/make_cmnd_gear', $app,
  'SprogEx::Gear::TenRandomNumbers');
is($app->alerts, '', 'successfully initialised from an existing gear class');
isa_ok($builder, 'Sprog::MakeCmndGear', 'command gear builder');

is($builder->type, 'input', 'correctly extracted type as "input"');
is($builder->title, 'Ten Random Numbers', 'extracted title from class');
is($builder->command, q(perl -le 'print int(rand(100)) foreach(1..10)'),
  'extracted command-line from class');
is($builder->keywords, 'monkey butter', 'extracted keywords from class');
is($builder->filename, 'TenRandomNumbers.pm', 'extracted filename from class');


my $fox_class = 'SprogEx::Gear::QuickBrownFox';
$app->reset_alerts;
$builder = $app->make_class('/app/make_cmnd_gear', $app, $fox_class);
is($app->alerts, '', 'successfully initialised from last generated gear');

my $new_title = 'The Quick Brown Fox';
$builder->title($new_title);

my $prompt = '';
$app->confirm_yes_no_handler(sub { shift; $prompt = shift; return 0 });
$builder->save;
is($prompt, 'File exists.  Overwrite?', 'save triggered overwrite? prompt');

$app->reset_alerts;
$builder = $app->make_class('/app/make_cmnd_gear', $app, $fox_class);
is($app->alerts, '', 'read the gear in from file again');

is($builder->title, 'Quick Brown Fox', 'file was not overwritten');

$builder->title($new_title);
$prompt = '';
$app->confirm_yes_no_handler(sub { shift; $prompt = shift; return 1 });
$builder->save;
is($prompt, 'File exists.  Overwrite?', 'answered yes to overwrite? prompt');

$app->reset_alerts;
$builder = $app->make_class('/app/make_cmnd_gear', $app, $fox_class);
is($app->alerts, '', 'read the gear in from file again');

is($builder->title, 'The Quick Brown Fox', 'file was overwritten');

$prompt = '';
$app->confirm_yes_no_handler(sub { shift; $prompt = shift; return 0 });
ok(!$app->delete_command_gear($fox_class), 'delete return false');
is($prompt, "Are you sure you wish to delete the gear from\n" .
  "the palette and from your personal gear folder?",
  'delete triggered "Are you sure?" prompt');
ok(-e $gear_file, 'gear file was not deleted');

$prompt = '';
$app->confirm_yes_no_handler(sub { shift; $prompt = shift; return 1 });
ok($app->delete_command_gear($fox_class), 'delete return true');
isnt($prompt, '', 'answered yes to prompt this time');
ok(!-e $gear_file, 'gear file was deleted');

