use strict;
use Sprog::TestHelper tests => -1;

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

is($builder->default_filename('quick Brown _FOX'), 'QuickBrownFox.pm',
  'output from default_filename() looks good');


$builder = $app->make_class('/app/make_cmnd_gear', $app, 'TenRandomNumbers');
is($app->alerts, '', 'successfully initialised from a gear class');
isa_ok($builder, 'Sprog::MakeCmndGear', 'command gear builder');

is($builder->type, 'input', 'correctly extracted type as "input"');
is($builder->title, 'Ten Random Numbers', 'extracted title from class');
is($builder->command, q(perl -le 'print int(rand(100)) foreach(1..10)'),
  'extracted command-line from class');
is($builder->keywords, 'monkey butter', 'extracted keywords from class');
is($builder->filename, 'TenRandomNumbers.pm', 'extracted filename from class');

