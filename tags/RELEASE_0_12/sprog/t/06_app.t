# Test some obscurish corner cases not otherwise tested

use strict;
use Sprog::TestHelper tests => 4;

use_ok('Sprog');
my $app = eval { Sprog->new(); };

like($@, qr/No class factory/, 'constructor died without class factory object');

use_ok('Sprog::ClassFactory');

my $test_file = File::Spec->catfile('t', 'ffff.sprog'); # Does not exist yet
unlink($test_file); # just in case


@ARGV = ( $test_file );

$app = make_app(               # Imported from ClassFactory.pm
  '/app'           => 'TestApp',
  '/app/machine'   => 'TestMachine',
  '/app/eventloop' => 'Sprog::GlibEventLoop',
  '/app/view'      => 'DummyView',
);

$app->add_timeout(100, sub { $app->quit } );
$app->run;
like($app->alerts, qr/Error reading .*?ffff.sprog/, 
  'correct alert when supplying name of a non-existant file to run method');

