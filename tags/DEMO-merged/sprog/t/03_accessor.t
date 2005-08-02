use strict;
use  Sprog::TestHelper tests => -5;

use_ok('Sprog::Accessor');
use_ok('AccTest');

$@ = '';
my $obj = eval { AccTest->new(prop1 => 'bob', prop3 => 'tom') };
is($@, '', 'created a test object using default constructor');

isa_ok($obj, 'AccTest',         'test object     ');
isa_ok($obj, 'Sprog::Accessor', 'test object also');
can_ok($obj, 'prop1');
is($obj->prop1, 'bob', 'prop1 initialised OK');
is($obj->prop3, 'tom', 'prop3 initialised OK too');
ok(!defined($obj->prop2), 'prop2 uninitialised (OK)');

$obj->prop2('kate');
is($obj->prop2, 'kate', 'successfully set prop2');

$obj->prop1('mary');
is($obj->prop1, 'mary', 'successfully overwrote prop1');

eval { $obj->prop3('jane') };
like($@, qr/'prop3' is a read-only property of AccTest/, 
     "can't write to prop3 - readonly");
is($obj->prop3, 'tom', 'prop3 was unscathed');

$@ = '';
$obj = eval { AccTest2->new(propA => 'cat', propC => 'dog') };
is($@, '', 'created a test object using subclassed constructor');

isa_ok($obj, 'AccTest2',        'test object     ');
isa_ok($obj, 'Sprog::Accessor', 'test object also');
can_ok($obj, 'propA');
is($obj->propA, 'CAT', 'propA two-phase initialisation worked OK');
is($obj->propC, 'dog', 'propC initialised OK too');
ok(!defined($obj->propB), 'propB uninitialised (OK)');

$obj->propB('hedgehog');
is($obj->propB, 'hedgehog', 'successfully set propB');

$obj->propA('bird');
is($obj->propA, 'bird', 'successfully overwrote propA');

eval { $obj->propC('goat') };
like($@, qr/'propC' is a read-only property of AccTest2/, 
     "can't write to propC - readonly");
is($obj->propC, 'dog', 'propC was unscathed');

