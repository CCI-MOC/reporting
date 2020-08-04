
package Reporting::Services::OpenStack::Neutron;

use JSON;
use strict;


my $DEBUG = $ENV{DEBUG};


sub new 
{
    my ($cls, $ua, $service_url) = @_;

    return bless {
            service_url => $service_url,
            useragent   => $ua,
        }, $cls;
}

sub get_floating_ips
{
    my ($self, $store) = @_;
    my $endpoint="/v2.0/floatingips";

    my $resp = $self->{useragent}->authorized_request("$self->{service_url}$endpoint");
    return $resp->status_line unless $resp->is_success;
    my $json_fields = from_json($resp->decoded_content);
    foreach my $fip (@{$json_fields->{floatingips}})
    {
        #print "$user_id, $fip->{id}\n";
        $store->{floating_ips}->{$fip->{id}} = {
            fixed_ip_address    => $fip->{fixed_ip_address},
            floating_ip_address => $fip->{floating_ip_address},
            floating_network_id => $fip->{floating_network_id},
            port_id             => $fip->{port_id},
            project_uuid        => $fip->{project_id},
            status              => $fip->{status},
            router_id           => $fip->{router_id},
        };

        # TODO: Signal pathway to indicate work needs to be added
        # Note: I wrote this TODO, but have now forgotton what I meant/why the below doesn't work ~TS
        $store->{keystone}->get_add_project($store, $fip->{project_id});
    }
    return undef;
}

1;
__END__
