package Sprog::Gear::Top;

use strict;

use base qw(Sprog::Gear);

sub input_type { undef; }

sub msg_queue { die __PACKAGE__ . " has no input queue\n"; }

1;
