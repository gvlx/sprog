package SprogWeb::Template::Plugin::SiteNav;

use strict;
use warnings;

use base qw( Template::Plugin );

use YAML;
use URI;
use File::Spec;

our $VERSION = 1.23;

my $link_data = undef;

sub new {
  my $class   = shift;
  my $context = shift;
  
  my $self = {
    @_ ,
    _CONTEXT => $context,
  };

  $self->{_TEMPLATE} ||= 'site_nav.inc';

  $link_data ||= get_link_data();

  return bless $self, $class;
}


sub get_link_data {
  my $self = shift;

  my($v, $p) = File::Spec->splitpath(__FILE__);
  @_ = File::Spec->splitdir($p);
  pop foreach(1..5);
  $p = File::Spec->catdir(@_, 'inc');

  my $file = File::Spec->catpath($v, $p, 'site_nav.yaml');

  return YAML::LoadFile($file);
}


sub links {
  my $self = shift;

  my $rel_links = $self->relative_links();

  $self->{_CONTEXT}->include($self->{_TEMPLATE}, { links => $rel_links });
}


sub relative_links {
  my $self = shift;

  my $curr_path = $self->current_path
    or die "Can't get pathname of calling template\n";

  my @links;

  foreach (@$link_data) {
    my $item = { %$_ };
    if($item->{href} eq $curr_path) {
      $item->{current_page} = 1;
    }
    else {
      $item->{href} = $self->abs2rel($item->{href}, $curr_path);
    }
    push @links, $item;
  };

  return \@links;
}


sub current_path {
  my $self = shift;

  my $context   = $self->{_CONTEXT}        or return;
  my $stash     = $context->{STASH}        or return;
  my $component = $stash->get('component') or return;
  return '/' . $component->{name};
}


sub abs2rel {
  my($self, $target, $base) = @_;

  return $target if $target =~ m{^\w+:};

  my $uri = URI->new("http://SITE$target");

  return '' . $uri->rel("http://SITE$base");
}

1;

