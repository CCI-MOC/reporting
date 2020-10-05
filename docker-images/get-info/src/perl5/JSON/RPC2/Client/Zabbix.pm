
package JSON::RPC2::Client::Zabbix;
=head3 JSON::RPC2::Client::Zabbix

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

# Note: Reimplementing portions of the underlying class
#		Reason being that Zabbix JSONRPC is non-standard and requires
# 		a top-level 'auth' object, plus the underlying class does not
# 		have good pluggability to adjust the output format
# Original code base at:
# <https://github.com/powerman/perl-JSON-RPC2/blob/master/lib/JSON/RPC2/Client.pm>
use parent 'JSON::RPC2::Client';

my $DEBUG = $ENV{DEBUG};

sub new {
	print("JSON::RPC2::Client::new\n") if $DEBUG > 1;
	my ($class) = @_;
	my $self = $class->SUPER::new();
	return bless $self, $class;
}

sub call_named {
	print("JSON::RPC2::Client::call_named\n") if $DEBUG > 1;
	my ($self, $method, $no_auth, @params) = @_;
	my %params = @params;

	my ($id, $call) = $self->_get_id();
	my $request = encode_json({
		jsonrpc	=> '2.0',
		method 	=> $method,
		id 		=> $id,
		($no_auth ? () : (
		auth 	=> $self->{_auth},
		)),
		params  => \%params,
	});

	return wantarray ? ($request, $call) : $request;
}

sub auth {
	print("JSON::RPC2::Client::auth\n") if $DEBUG > 1;
	my ($self, $ua, $user, $password) = @_;

	my ($result, $err) = $ua->call_named('user.login', 1,
		user => $user,
		password => $password
	);
	return $err if $err;

	$self->{_auth} = $result;
	return undef;
}

1;
__END__
