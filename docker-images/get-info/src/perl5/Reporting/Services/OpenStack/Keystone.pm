
package Reporting::Services::OpenStack::Keystone;

use Data::Dumper;
use JSON;

use strict;


my $DEBUG = $ENV{DEBUG};

sub new
{
    my ($cls, $ua, $url) = @_;

    return bless {
            cached      => { },
            useragent   => $ua,
            url         => $url
        }, $cls;
}


my $_CACHE_FIELDS = {
    token => {
        catalog => "catalog"
    }
};
sub _cache_recurse
{
    my ($self, $data, $fields) = @_;

    foreach my $key (keys %$data) 
    {
        my $t_ref = ref $fields->{$key};
        if ($t_ref)
        {
            if ($t_ref eq 'HASH')
            {
                $self->_cache_recurse($data->{$key}, $fields->{$key})
            }
            elsif ($t_ref eq 'CODE')
            {
                $fields->{$key}->($self, $data->{$key})
            }
            else 
            {
                die "Unhandlable reference type $t_ref in {Dumper{$fields}}";
            }
        }
        elsif ($fields->{$key})
        {
            $self->{cached}->{$fields->{$key}} = $data->{$key};
        }
    }
}

sub _cache_result_data
{
    my ($self, $data) = @_;
    return $self->_cache_recurse($data, $_CACHE_FIELDS);
}

sub get_unscoped_token
{
    print("Keystone::get_unscoped_token\n") if $DEBUG;
    my ($self, $user, $pass) = @_;
    my $endpoint = "/v3/auth/tokens";
    my $post_fields = {
        auth => {
            identity => {
                methods => ["password"],
                password => {
                    user => {
                        domain      => { id => "default" },
                        name        => $user,
                        password    => $pass
                    }
                }
            }
        }
    };

    my $resp = $self->{useragent}->request("$self->{url}$endpoint", $post_fields);
    die $resp->status_line unless $resp->is_success;

    my $token       = $resp->header('X-Subject-Token');
    my $json_fields = from_json($resp->decoded_content);
    $self->_cache_result_data($json_fields);
    print("Unscoped Token: ", $token, "\n") if $DEBUG;
    return ({
            token           => $token,
            token_expiry    => $json_fields->{token}->{expires_at},
            user_id         => $json_fields->{token}->{user}->{id}
            # domain_id       => $json_fields->{token}->{user}->{domain}->{id}
        }, undef);
}

sub get_scoped_token
{
    print("Keystone::get_scoped_token\n") if $DEBUG;
    my ($self, $token, $scope) = @_;
    my $endpoint = "/v3/auth/tokens";
    my $post_fields = {
        auth => {
            scope => $scope,
            identity => {
                methods => [ "token" ],
                token   => { id => $token },
            }
        }
    };

    # foreach my $l (split /\n/,$resp)
    # {
    #     if($l =~ /X-Subject-Token: ([a-zA-Z0-9\-_]+)/) 
    #     {
    #         $ret->{token}=$1; 
    #         print "token: $1\n"; 
    #     }
    #     $json=$l; #this is a simple stupid way of setting $json_str to the last element of the array.
    # }
    # print $url."--".$json."\n";

    my ($resp, $err) = $self->{useragent}->request("$self->{url}$endpoint", $post_fields);
    die $err                if $err;
    die $resp->status_line  unless $resp->is_success;

    my $token       = $resp->header('X-Subject-Token');
    my $json_fields = from_json($resp->decoded_content);
    print("Scoped Token: ", $token, "\n") if $DEBUG;
    print("Token Fields: ", Dumper{%$json_fields}, "\n") if $DEBUG;

    return ({
            token           => $token,
            token_expiry    => $json_fields->{token}->{expires_at},
            user_id         => $json_fields->{token}->{user}->{id},
            domain_id       => $json_fields->{token}->{user}->{domain}->{id}
        }, undef)
}

sub get_catalog
{
    print("Keystone::get_catalog\n") if $DEBUG;
    my ($self, $token) = @_;
    #my $endpoint = "/v3/auth/catalog";

    unless ($self->{cached}->{catalog})
    {
        my $endpoint = "/v3/services";
        my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint");
        return (undef, $resp->status_line) unless $resp->is_success;

        my $json_data = from_json($resp->decoded_content);
        # TODO: may have field {links}->{next}, which indicates more data; unroll
        self->_cache_result_data($json_data);
    }

    # print("Catalog:", Dumper{%$json_fields}) if $DEBUG;
    return ($self->{cached}->{catalog}, undef)
}

sub store_project_json
{
    my ($store, $obj) = @_;

    die "Missing object to be stored?" unless $obj;
    # print("-- (", $p->{domain_id}, ") ", $p->{name}, "\n") if $DEBUG;
    print("-- ", $obj->{id}, " \"", $obj->{name}, "\"\n") if $DEBUG;
    $store->{projects}->{$obj->{id}} = {
        name => $obj->{name}
        # domain => $obj->{domain_id}
    };
}

sub get_all_projects
{
    print("Keystone::get_all_projects\n") if $DEBUG;
    my ($self, $store) = @_;
    my $endpoint = "/v3/projects";

    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint");
    return $resp->status_line   unless $resp->is_success;

    my $json_fields = from_json($resp->decoded_content);
    # print Dumper{%$json_fields} if $DEBUG;
    return "Could not load projects from Keystone" unless $json_fields->{projects};

    foreach my $project (@{$json_fields->{projects}})
    {
        store_project_json($store, $project);
    }
    return undef;
}

sub get_add_project
{
    print("Keystone::get_add_project") if $DEBUG;
    my ($self, $store, $project_id) = @_;
    print(": $project_id\n") if $DEBUG;

    # Return if the project is already there
    $store->{project} = {} unless exists $store->{project};
    if (exists $store->{projects}->{$project_id})
    {
        print("-- Return early; project already loaded\n") if $DEBUG;
        return undef;
    }

    my $endpoint = "/v3/projects/$project_id";
    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint");
    # Skip end early on response failure as we handle in following if block
    # return $resp->status_line   unless $resp->is_success;
    my $json_fields = from_json($resp->decoded_content);
    # print Dumper{%{$json_fields->{project}}};
    # exit;

    # if( (exists $json_fields->{error}) and (exists $json_fields->{error}->{code}) and ($json_fields->{error}->{code} =~ /^4.*/) )
    # {
    #     print("INFO: keystone reports: $json_fields->{error}->{message}\n");
    #     $store->{projects}->{$project_id}->{name}='unknown';
    #     $store->{projects}->{$project_id}->{status}="NotFound - ".$json_fields->{error}->{code};
    # }

    # foreach my $p (@{$json_fields->{projects}})
    #    {
    #    $os_info->{projects}->{$p->{id}}->{name}=$p->{name};
    #    $os_info->{projects}->{$p->{id}}->{domain}=$p->{domain_id};
    #    $os_info->{projects}->{$p->{id}}->{status}=$p->{enabled};
    #    }

    store_project_json($store, $json_fields->{project});

    return undef;
}

sub get_user2project
{
    print("Keystone::get_user2project\n") if $DEBUG;
    my ($self, $store, $user_id) = @_;
    my $endpoint = "/v3/users/$user_id/projects";

    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint");
    return $resp->status_line   unless $resp->is_success;

    my $json_fields = from_json($resp->decoded_content);
    # print Dumper{%$json_fields} if $DEBUG;

    foreach my $p (@{$json_fields->{projects}})
    {
        print("---- ", $user_id, " => ", $p->{id}, "\n") if $DEBUG;
        # TODO: Fetch User Role Data
        $store->{users2projects}->{$user_id}->{$p->{id}}=1;
    }
    return undef;
}

sub get_all_users
{
    print("Keystone::get_all_users\n") if $DEBUG;
    my ($self, $store) = @_;
    my $endpoint="/v3/users";

    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint");
    return $resp->status_line   unless $resp->is_success;

    my $json_fields = from_json($resp->decoded_content);
    # print Dumper{%$json_fields} if $DEBUG;

    foreach my $user (@{$json_fields->{"users"}})
    {
        print("-- ", $user->{id}, " == ", $user->{name}, " <", $user->{email}, ">\n") if $DEBUG;
        # $store->{users}->{$user->{id}}->{domain}=$user->{domain_id};
        $store->{users}->{$user->{id}}->{name}=$user->{name};
        $store->{users}->{$user->{id}}->{email}=$user->{email};
        $store->{users}->{$user->{id}}->{enabled}=$user->{enabled};
        $store->{users}->{$user->{id}}->{default_project}=$user->{default_project};
        # $store->{users}->{$user->{id}}->{enabled}=$user->{};
        # $store->{users}->{$user->{id}}->{email}=$user->{email};

        #for each user get the list of projects
        $self->get_user2project($store, $user->{id});
    }
    return undef;
}

1;
__END__
