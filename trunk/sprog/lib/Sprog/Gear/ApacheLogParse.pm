package Pstax::Gear::ApacheLogParse;

use strict;

use base qw(Pstax::Gear);

use Apache::LogRegex;

__PACKAGE__->declare_properties(
  log_format => 'combined',
);

sub title { 'Parse Apache Log' };

sub output_type   { 'H'; }

sub prime {
  my $self = shift;

  my $lr = eval {
    Pstax::Gear::ApacheLogParse::Parser->new($self->format_string) 
  };
  if ($@) {
    $self->app->alert("Unable to parse log format string", $@);
    return;
  }

  $self->{lr} = $lr;

  return $self->SUPER::prime;
}


sub format_string {
  my $self = shift;
  
  my $log_format = $self->log_format;
  if($log_format eq 'common') {
    return '%h %l %u %t \"%r\" %>s %b';
  }
  else {
    return '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"';
  }
}


sub line {
  my($self, $line) = @_;

  return unless $self->{lr};

  my %data = eval { $self->{lr}->parse($line); };

  if(%data) {
    $self->msg_out(data => \%data);
  }
  else {
    warn "Could not parse: $line\n";
  }
}


sub dialog_xml {
  return 'file:/home/grant/projects/pstax/glade/apache_log.glade';

  return <<'END_XML';

END_XML
}


package Pstax::Gear::ApacheLogParse::Parser;

use base 'Apache::LogRegex';

my %common_fields;

BEGIN {
  %common_fields = (
    '%a'  => 'client_ip',
    '%A'  => 'server_ip',
    '%b'  => 'bytes_sent',
    '%B'  => 'ibytes_sent',
    '%c'  => 'connection_status',
    '%f'  => 'filename',
    '%h'  => 'host',
    '%H'  => 'protocol',
    '%l'  => 'client_login',
    '%m'  => 'method',
    '%p'  => 'server_port',
    '%P'  => 'server_pid',
    '%q'  => 'query_string',
    '%r'  => 'request',
    '%>s' => 'status',
    '%s'  => 'initial_status',
    '%t'  => 'time',
    '%T'  => 'elapsed_time',
    '%u'  => 'auth_user',
    '%U'  => 'url_path',
    '%v'  => 'canonical_server_name',
    '%V'  => 'server_name',
  );
}

sub new {
  my($class, $log_format) = @_;

  return $class->SUPER::new($log_format);
}


sub rename_this_name {
  my($self, $name) = @_;

  return $common_fields{$name} if exists $common_fields{$name};

  if($name =~ /\{(.+?)\}(.)/) {
    if($2 eq 't') {
      return 'strftime';
    }
    $name = $1;
    $name .= '-out'  if $2 eq 'o';
    $name .= '-note' if $2 eq 'n';
  }

  return $name;
}
1;
