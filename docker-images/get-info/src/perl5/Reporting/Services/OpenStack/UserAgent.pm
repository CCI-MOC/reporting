
package Reporting::Services::OpenStack::UserAgent;

#use LWP::UserAgent;
use parent qw(LWP::UserAgent);
use HTTP::Request;
use JSON;
use strict;


my $DEBUG = $ENV{DEBUG};

sub new
{
	my ($cls, $ua, $user, $pass) = @_;

    die "$cls: Missing underlying user agent from LWP\n"    unless $ua;
    die "$cls: Missing Username\n"                          unless $user;
    die "$cls: Missing Password\n"                          unless $pass;

    # TODO: Validate types of input objects

	my $self = bless {
			useragent => $ua,
            user => $user,
            pass => $pass,
		}, $cls;

    return $self;
}

sub __gen_request
{
    my ($url, $body) = @_;
    print(": ", $url) if $DEBUG;

    # my $curl = WWW::Curl::Easy->new();
    # $curl->setopt(CURLOPT_URL,$url);
    # $curl->setopt(WWW::Curl::Easy::CURLOPT_HTTPHEADER(),["Content-Type: application/json"]);
    # $curl->setopt(CURLOPT_POSTFIELDS,$post_fields);
    # $curl->setopt(CURLOPT_HEADER,1);
    # $curl->setopt(CURLOPT_WRITEDATA, \$resp);

    my $req;
    if (ref $body)
    {
        $req = HTTP::Request->new(POST => $url);
        $req->content_type('application/json');
        $req->content(to_json($body));
    }
    elsif ($body)
    {
        $req = HTTP::Request->new(POST => $url);
        $req->content($body);
    }
    else 
    {
        $req = HTTP::Request->new(GET => $url);
    }
    return $req;
}


sub _perform_request
{
    my ($self, $req) = @_;

    # $curl->setopt(CURLOPT_WRITEDATA, \$resp);
    # $curl->perform();

    my $resp = $self->{useragent}->request($req);
    if ($DEBUG)
    {
        if ($resp->is_success)
        {
            print(" -- OK: ", $resp->code, "\n");
        }
        else 
        {
            print(" -- ERR: ", $resp->status_line, "\n");
            print($resp->decoded_content, "\n");
        }
    }
    return $resp;
}

sub request
{
    print("UserAgent::request") if $DEBUG;
    my $self = shift;
    return $self->_perform_request(__gen_request(@_));
}

sub set_auth_provider
{
    my ($self, $auth_obj) = @_;
    my $old = $self->{auth_obj};
    $self->{auth_obj} = $auth_obj;
    return $old;
}

sub get_unscoped_token
{
    print("UserAgent::get_unscoped_token\n") if $DEBUG;
    my ($self) = @_;
    my $err;

    die "Auth Provider Not Yet Set\n" unless $self->{auth_obj};

    ($self->{token}, $err) = $self->{auth_obj}->get_unscoped_token($self->{user}, $self->{pass});
    return $err if $err;
    return undef;
}

sub authorized_request
{
    print("UserAgent::authorized_request") if $DEBUG;
    my $self = shift;

    die "No Token Loaded" unless ($self->{token});

    # $curl->setopt(WWW::Curl::Easy::CURLOPT_HTTPHEADER(),["X-Auth-Token: $os_info->{admin}->{token}"]);
    # $curl->setopt(CURLOPT_WRITEDATA, \$resp);
    # $curl->perform();

    my $req = __gen_request(@_);
    $req->header('X-Auth-Token' => $self->{token}->{token});
    return $self->_perform_request($req);
}

sub agent_scoped_by_name
{
    print("UserAgent::agent_scoped_by_name\n") if $DEBUG;
    my ($self, $domain_name, $project_name) = @_;

    my $err;
    my $new = Reporting::Services::OpenStack::UserAgent->new();
    $new->{auth_obj}        = \$self->{auth_obj};
    ($new->{token}, $err)   = $self->{auth_obj}->get_scoped_token(
        $self->{unscoped_token}->{token},
        {
            project => {
                domain  => { name => $domain_name },
                name    => $project_name
            }
        });
    die $err if $err;
    return $new;
}

sub agent_scoped_by_id 
{
    print("UserAgent::agent_scoped_by_id\n") if $DEBUG;
    my ($self, $id) = @_;

    my $err;
    my $new = Reporting::Services::OpenStack::UserAgent->new();
    $new->{auth_obj}        = \$self->{auth_obj};
    ($new->{token}, $err)   = $self->{auth_obj}->get_scoped_token(
        $self->{unscoped_token}->{token}, 
        {
            project => { id => $id }
        });
    die $err if $err;
    return $new;
}

1;
__END__;
