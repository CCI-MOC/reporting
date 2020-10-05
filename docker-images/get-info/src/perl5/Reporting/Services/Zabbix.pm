
package Reporting::Services::Zabbix;
=head3 Services::Zabbix

TBI (To be Implemented)
TBD (To be Documented)

=over
=cut
#TODO

use strict;
use POSIX;
use v5.32;

use Data::Dumper;
use JSON::MaybeXS;

use JSON::RPC2::Client::Zabbix;
use JSON::RPC2::Transport::HTTP::LWP;

use Reporting::Services::Zabbix::Host;
use Reporting::Services::Zabbix::Item;


my $DEBUG = $ENV{DEBUG};

sub new
{
	print("Zabbix::new\n") if $DEBUG > 1;
	my ($cls, $service, $ua) = @_;

	return (undef, "Missing URL")           unless $service->{url};
	return (undef, "Missing Service Name")  unless $service->{id};
	return (undef, "Missing Username") 		unless $service->{user};
	return (undef, "Missing Password")		unless $service->{password};
	return (undef, "Missing UserAgent")     unless $ua;

	my ($ua, $err) = JSON::RPC2::Transport::HTTP::LWP->new(
		JSON::RPC2::Client::Zabbix->new(),
		$ua,
		$service->{url});
	return (undef, $err) if $err;

	$err = $ua->auth($service->{user}, $service->{password});
	return (undef, "Auth: $err") if $err;

	my $self = bless {
			id => $service->{id},
			ua => $ua,
	}, $cls;

	$self->{host} = Reporting::Services::Zabbix::Host->new($ua);
	$self->{item} = Reporting::Services::Zabbix::Item->new($ua);

	return ($self, undef);
}

sub test_jsonrpc {
	print("Zabbix::test_jsonrpc\n") if $DEBUG > 1;
	my ($self) = @_;

 	my $result = $self->{ua}->call_named('apiinfo.version', 1);
 	print("Zabbix API Version: $result\n") if $DEBUG;

	return undef;
}

sub _load_hosts {
	print("Zabbix::_load_hosts\n") if $DEBUG > 1;

	my ($self, $store) = @_;

	my $data = $self->{host}->get();

	foreach my $host (@$data) {
		my $uuid = $host->{host};
		if ($uuid == "Zabbix Server") 
		{
			next;
		}

		$store->{hosts}->{$uuid} = $host;
		if ($DEBUG > 1)
		{
			print(encode_json($host));
		}
	}
}

sub store
{
	print("Zabbix::store\n") if $DEBUG > 1;
	my ($self, $db) = @_;

	my @steps = (
		( !$DEBUG ? () : (
		["", sub { return $self->test_jsonrpc(); }],
		)),
		[ "Load Hosts", sub { return $self->_load_hosts(@_); } ],
	);

	my $i = 1;
	for my $tupl (@steps)
	{
		my ($text, $step) = @{$tupl};
		if ($text) {
			print("$i ---> $text\n");
			$i++;
		}
		my $err = $step->($self);
		return $err if $err;
	}

    my $service_id = $db->get_service_id($self->{id});
	$db->dump($self, $service_id);
	return undef;
}

=back
=cut

1;
__END__
