
package JSON::RPC2::Transport::HTTP::LWP;
=head3 JSON::RPC2::Transport::HTTP::LWP

JSONRPC2 Transport for HTTP based on LWP
TBI (To be Implemented)
TBD (To be Documented)

=over
=cut
#TODO

use strict;
use POSIX;
use v5.32;

use Data::Dumper;
use HTTP::Request;
use JSON::RPC2::Client;


my $DEBUG = $ENV{DEBUG};


sub new {
	print("Transport::HTTP::LWP::new\n") if $DEBUG > 1;
	my ($cls, $rpc, $ua, $url) = @_;

	return (undef, "Missing real JSONRPC obj") 	unless $rpc;
	return (undef, "Missing UserAgent") 		unless $ua;
	return (undef, "Missing URL")				unless $url;

	my $self = bless {
		rpc => $rpc,
		ua => $ua,
		url => $url
	}, $cls;
	return ($self, undef);
}

sub call_named {
	print("Transport::HTTP::LWP::call_named\n") if $DEBUG > 1;
	my $self = shift;

	my ($json_request, $call) = $self->{rpc}->call_named(@_);
	print("-> $json_request\n") if $DEBUG > 2;

	my $req = HTTP::Request->new(POST => $self->{url});
	$req->header("Content-Type" => "application/json");
	$req->header("Accept" => "application/json");
	$req->content($json_request);

	my $res = $self->{ua}->request($req);
	if ($res->code != 200) {
		die "JSONRPC request returned \"" . $res->status_line . "\"";
	}

	my $text_res = $res->decoded_content;
	print("<- $text_res\n") if $DEBUG > 2;

	my ($failed, $result, $error, $call) = $self->{rpc}->response($text_res);

	return (undef, "Internal Error: $failed\n") 											if $failed;
	return (undef, "JSONRPC2 Error: $error->{message}: $error->{data} ($error->{code})\n") 	if $error;
	return (undef, "Command apiinfo.version failed without error return\n") 				if not $result;

	return $result;
}

sub auth {
	print("Transport::HTTP::LWP::auth\n") if $DEBUG > 1;
	my $self = shift;
	return $self->{rpc}->auth($self, @_);
}

1;
__END__
