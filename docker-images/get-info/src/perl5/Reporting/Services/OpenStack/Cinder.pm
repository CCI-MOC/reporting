
package Reporting::Services::OpenStack::Cinder;

use JSON;
use strict;
use v5.32;


my $DEBUG = $ENV{DEBUG};


sub new
{
    my ($cls, $ua, $url) = @_;

    return bless {
                useragent => $ua,
                url => $url,
        }, $cls;
}

sub get_volumes
{
    print("Cinder::get_volumes\n") if $DEBUG;
    # TODO?: $url should be something of the form
    #
    #    address                       :port/ version / admin uuid
    #    https://engage1.massopen.cloud:8776/v3/c53c18b2d29641e0877bbbd8d87f8267

    my ($self, $store) = @_;
    my $endpoint = "/volumes/detail";
    my $query = "?all_tenants=1";

    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint$query");
    return $resp->status_line           unless $resp->is_success;
    my $fields = from_json($resp->decoded_content);
    die "Could not load Cinder Volumes" unless $fields->{volumes};

    foreach my $v (@{$fields->{volumes}})
    {
        my $project_uid = $v->{'os-vol-tenant-attr:tenant_id'};
        my $volume_uid  = $v->{'id'};

        $store->{project}->{$project_uid}->{Vol}->{$volume_uid} = {
            status  => $v->{status},
            size    => $v->{size},
        };

        foreach my $attachment (@{$v->{attachments}})
        {
            $store->{item_ts2item_ts}->{$attachment->{attachment_id}} = {
                type    => "vm-disk",
                project => $project_uid,
                id1     => $attachment->{server_id},
                id2     => $volume_uid,
            };
        }
    }
    return undef;
}

1;
__END__
