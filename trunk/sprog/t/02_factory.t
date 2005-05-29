use strict;
use Sprog::TestHelper tests => 15;

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'         => 'DummyApp',
  '/app/machine' => 'Dummy',
  '/app/view'    => 'Dummy',
  '/bogus'       => 'Bogus',
);

isa_ok($app, 'DummyApp');

my $factory = $app->factory;
isa_ok($factory,           'Sprog::ClassFactory');
isa_ok($app->machine,      'Dummy'              );
isa_ok($app->view,         'Dummy'              );
isa_ok($app->view->{app},  'DummyApp'           );

my $obj = $factory->make_class('/app/view', one => 'two');
isa_ok($obj, 'Dummy');
is($obj->{one}, 'two', 'Arguments were passed via factory');

$factory->inject('/app/view' => 'DummyView');
$obj = $factory->make_class('/app/view', three => 'four');
isa_ok($obj, 'Dummy');
is($obj->{three}, 'four', 'Arguments were passed via factory');

$factory->override('/app/view' => 'DummyView');
$obj = $factory->make_class('/app/view', five => 'six');
isa_ok($obj, 'DummyView');
is($obj->{five}, 'six', 'Arguments were passed via factory');

$@ = '';
eval { $factory->make_class('bogus'); };
like("$@", qr/No class registered for 'bogus'.*02_factory.t/s,
     "Creating bogus class failed with correct message");


$app = make_app('/app' => 'DummyApp'); # Use defaults

isa_ok($app,          'DummyApp'    );
isa_ok($app->machine, 'DummyMachine');
isa_ok($app->view,    'DummyView'   );


