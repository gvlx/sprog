use strict;
use warnings;

# Test some obscurish corner cases not otherwise tested

use Test::More tests => 4;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('Sprog');
my $app = eval { Sprog->new(); };

like($@, qr/No class factory/, 'constructor died without class factory object');

use_ok('Sprog::ClassFactory');

$app = make_app(               # Imported from ClassFactory.pm
  '/app'         => 'TestApp',
  '/app/machine' => 'TestMachine',
  '/app/view'    => 'DummyView',
);

my $test_file = File::Spec->catfile('t', 'ffff.sprog'); # Does not exist yet
unlink($test_file); # just in case

$app->add_timeout(100, sub { $app->quit } );
$app->run($test_file);
like($app->alerts, qr/Error reading .*?ffff.sprog/, 
  'correct alert when supplying name of a non-existant file to run method');

