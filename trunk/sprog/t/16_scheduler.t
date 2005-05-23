# This script tests the setup and cleanup code in Sprog::Machine::Scheduler.
# It never actually runs the scheduler though - plenty of other test scripts
# do that.

use strict;
use warnings;

use Test::More tests => 47;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::WriteFile');
use_ok('Sprog::Gear::TextInput');

my $app = TestApp->make_test_app;

my($source, $filter, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::UpperCase
  TextSink
));
is($app->alerts, '', 'no alerts while creating machine');

my $sched = $app->factory->make_class('/app/machine/scheduler', $source);

isa_ok($sched, 'Sprog::Machine::Scheduler', 'scheduler object');

my $train = $sched->{gear_train};
isa_ok($train, 'ARRAY', 'gear train');
is(scalar @$train, 3, 'three gears in train');

my $gear_by_id = $sched->{gear_by_id};
isa_ok($gear_by_id, 'HASH', 'gear_by_id');

my($source_id, $filter_id, $sink_id) = @$train;
is($gear_by_id->{$source_id}->title, 'Text Input', 'first gear looks good');
is($gear_by_id->{$filter_id}->title, 'Uppercase',  'second gear looks good');
is($gear_by_id->{$sink_id}->title,   'Text Gear',  'third gear looks good');

my $next_id = $sched->{next_id};
isa_ok($next_id, 'HASH', 'next_id');
is($next_id->{$source_id}, $filter_id, 'source gear points to filter gear');
is($next_id->{$filter_id}, $sink_id,   'filter gear points to sink gear');
is($next_id->{$sink_id}, undef,        'sink gear points to nothing');

my $prev_id = $sched->{prev_id};
isa_ok($prev_id, 'HASH', 'prev_id');
is($prev_id->{$source_id}, undef,      'source gear preceded by nothing');
is($prev_id->{$filter_id}, $source_id, 'filter gear preceded by source gear');
is($prev_id->{$sink_id},   $filter_id, 'sink gear preceded by filter gear');

my $providers = $sched->{providers};
isa_ok($providers, 'ARRAY', 'provider list');
is(scalar @$providers, 1, 'machine has one provider');
is($providers->[0], $source_id, 'provider is the source gear');

is_deeply(
  $gear_by_id->{$source_id}->msg_queue, undef, 'source gear has no input queue'
);
is_deeply(
  $gear_by_id->{$filter_id}->msg_queue, [], 'filter gear has empty input queue'
);
is_deeply(
  $gear_by_id->{$sink_id}->msg_queue, [],   'sink gear has empty input queue'
);

$sink->msg_out(data => 'message one');
my $msg_queue = $sched->{msg_queue};
is_deeply([ map { $_ ? @$_ : () } values %$msg_queue ], [ ],
  'sink->msg_out was quietly ignored');

$filter->requeue_message_delayed(data => 'message two');

my $redo_queue = $sched->{redo_queue};
is_deeply($redo_queue->{$filter_id}, [ [ data => 'message two' ] ], 
  're-queued message is in the redo queue for the filter');
is_deeply($msg_queue->{$filter_id}, [ ], 
  'and not in the message queue');

$source->msg_out(data => 'message three');
is_deeply(
  $msg_queue->{$filter_id}, 
  [ 
    [ data => 'message two'],
    [ data => 'message three'],
  ], 
  'requeued message and source->msg_out landed in queue for second gear'
);

$source->disengage;

is_deeply(
  [ map { $gear_by_id->{$_}->title } @$train ],
  [ 'Uppercase', 'Text Gear' ],
  'source gear has been removed from the train'
);

is_deeply($providers, [], 'source gear has been removed from the provider list');

ok(!exists $gear_by_id->{$source_id}, 'scheduler does not know source by ID');
ok(!exists $next_id->{$source_id},    'scheduler does not know next for ID');

is_deeply(
  $msg_queue->{$filter_id}, 
  [ 
    [ data => 'message two'],
    [ data => 'message three'],
    [ no_more_data => ()   ]
  ], 
  'disengaging source gear queued no_more_data message for filter'
);


# Create a second test machine

$app = TestApp->make_test_app;
($source, $filter, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::UpperCase
  TextSink
));
$sched = $app->factory->make_class('/app/machine/scheduler', $source);
isa_ok($sched, 'Sprog::Machine::Scheduler', 'second scheduler object');

$train = $sched->{gear_train};
is(scalar @$train, 3, 'three gears in train');
($source_id, $filter_id, $sink_id) = @$train;

$msg_queue = $sched->{msg_queue};
$source->msg_out(data => 'message one');

is_deeply(
  $msg_queue->{$filter_id}, 
  [ [ data => 'message one' ] ], 
  'one data message is queued for filter'
);

$filter->requeue_message_delayed(data => 'message zero');
is_deeply( $msg_queue->{$filter_id}, [ ], 'filter message queue is empty');

$redo_queue = $sched->{redo_queue};
is_deeply(
  $redo_queue->{$filter_id}, 
  [
    [ data => 'message zero' ],
    [ data => 'message one' ],
  ], 
  'two data messages are in the redo queue for filter'
);

$source->msg_out(data => 'message two');
is_deeply(
  $msg_queue->{$filter_id}, 
  [
    [ data => 'message zero' ],
    [ data => 'message one' ],
    [ data => 'message two' ],
  ], 
  'three data messages queued for filter'
);
is_deeply( $redo_queue->{$filter_id}, [ ], 'filter redo queue is now empty');

$filter->disengage;
is(scalar @$train, 1, 'disengage from filter gear rippled back to source');

ok(!exists $gear_by_id->{$filter_id}, 'scheduler does not know filter by ID');
ok(!exists $next_id->{$filter_id},    'scheduler does not know next for ID');
ok(!exists $prev_id->{$filter_id},    'scheduler does not know prev for ID');
ok(!exists $gear_by_id->{$source_id}, 'scheduler does not know source by ID');

is_deeply(
  $msg_queue->{$sink_id}, 
  [ [ no_more_data => ()   ] ], 
  'no_more_data message is queued for sink'
);

