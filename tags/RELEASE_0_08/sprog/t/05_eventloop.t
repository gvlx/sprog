use strict;
use warnings;

use Test::More tests => 6;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('Sprog::ClassFactory');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'           => 'Sprog',
  '/app/machine'   => 'DummyMachine',
  '/app/view'      => 'DummyView',
  '/app/eventloop' => 'Sprog::GtkEventLoop',
);

isa_ok($app, 'Sprog');

my $event = {};

$app->add_timeout(2000, sub { $event->{timeout}++; $app->quit } );

$app->add_idle_handler(sub {return if($event->{idle}++ > 3); return 1; });

my $text_file = File::Spec->catfile('t', 'rgb.txt');
if(open my $fh, '<', $text_file) {
  $app->add_io_reader($fh, sub { $event->{io_reader} = <$fh>; return 0; });
}

$app->run;

ok(1, 'we made it out of the event loop alive');

ok($event->{timeout}, 'timeout event was triggered');

ok($event->{idle} > 3, 'idle handler ran enough times');

like($event->{io_reader}, qr/#FF0000\s+Red/, 'io_reader event was triggered');

