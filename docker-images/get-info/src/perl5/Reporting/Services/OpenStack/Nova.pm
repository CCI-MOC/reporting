
package Reporting::Services::OpenStack::Nova;

use JSON;
use strict;


my $DEBUG = $ENV{DEBUG};


sub new
{
    my ($cls, $ua, $url) = @_;

    return bless {
            useragent => $ua,
            url => $url,
        }, $cls;
}

# This needs to be generalized
# currently only accepts the admin token;
sub get_os_flavors
{
    print("Nova::get_os_flavors\n") if $DEBUG;
    my ($self, $store) = @_;
    my $endpoint = "/flavors/detail";

    # Tariq: Not sure why this is different from the other methods; all are using
    # the Admin Token as X-Auth-Token
    # 
    # if(!(exists $os_info->{admin}->{token}))
    # {
    #     warn "get os_flavors(...) needs to be generalized to take any token\n";
    #     return undef;
    # }

    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint");
    return $resp->status_line unless $resp->is_success;
    my $flavor_array=from_json($resp->decoded_content);
    foreach my $f (@{$flavor_array->{flavors}})
    {
        print("-- $f->{id} => $f->{name}\t($f->{vcpus} cores, $f->{ram}MB RAM, $f->{disk}(G?)B store)\n") if $DEBUG;
        $store->{flavors}->{$f->{id}} = {
            name    => $f->{name},
            vcpus   => $f->{vcpus},
            ram     => $f->{ram},
            disk    => $f->{disk}
        };
    }
    return undef;
}

sub get_vm_details
{
    print("Nova::get_vm_details\n") if $DEBUG;
    my ($self, $store, $vm_id) = @_;

    # Note: Function doesn't change store so made no-op ~Tariq
    return undef;

    # if(!defined($vm_id) or length($vm_id)==0)
    # {
    #     print STDERR "Invalid vm_id passed to get_vm_details\n";
    #     return ("","","");
    # }
    # my $endpoint = "/servers/$vm_id";
    # my ($resp, $err) = $self->{useragent}->authorized_request("$self->{url}$endpoint");

    # #$vm_details = from_json($resp);
    # print "====>>>>  \n";
    # print $resp;
    # #print Dumper(%$vm_details);
}

sub get_all_vm_details
{
    print("Nova::get_all_vm_details\n") if $DEBUG;
    my ($self, $store) = @_;

    my $flavors = $store->{flavors};
    $flavors = $self->get_os_flavors($store) unless $flavors;

    my $endpoint = "/servers/detail";
    my $query = "?all_tenants=true";
    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint$query");
    return $resp->status_line unless $resp->is_success;
    my $vm_details = from_json($resp->decoded_content);

    foreach my $vm (@{$vm_details->{servers}})
    {
        #print "$user_id, $vm->{id}\n";
        #print Dumper $vm;
        #exit;

        #$VAR1 = {
        #  'links' => [
        #               {
        #                 'href' => 'https://kaizen.massopen.cloud:8774/v2/344583b960c146319398dffb1d7b43b6/servers/dded8ecd-a03a-4dd1-9988-464c053eaef1',
        #                 'rel' => 'self'
        #               },
        #               {
        #                 'href' => 'https://kaizen.massopen.cloud:8774/344583b960c146319398dffb1d7b43b6/servers/dded8ecd-a03a-4dd1-9988-464c053eaef1',
        #                 'rel' => 'bookmark'
        #               }
        #             ],
        #  'OS-SRV-USG:terminated_at' => undef,
        #  'hostId' => '',
        #  'id' => 'dded8ecd-a03a-4dd1-9988-464c053eaef1',
        #  'OS-EXT-STS:task_state' => 'scheduling',
        #  'user_id' => '719dda5b42a74aceae60b9c2bcb7d6b3',
        #  'OS-EXT-SRV-ATTR:hypervisor_hostname' => undef,
        #  'updated' => '2018-10-03T22:49:09Z',
        #  'OS-EXT-SRV-ATTR:host' => undef,
        #  'image' => '',
        #  'OS-EXT-SRV-ATTR:instance_name' => '',
        #  'OS-EXT-AZ:availability_zone' => 'nova',
        #  'os-extended-volumes:volumes_attached' => [],
        #  'OS-DCF:diskConfig' => 'AUTO',
        #  'name' => 'rabbitmq',
        #  'created' => '2018-09-18T21:29:45Z',
        #  'OS-EXT-STS:power_state' => 0,
        #  'tenant_id' => '54e3468f0fd849709f2e6716f11f62cb',
        #  'accessIPv4' => '',
        #  'accessIPv6' => '',
        #  'flavor' => {
        #                'id' => '73ae9789-4fe9-4299-978c-9cb8f4964298',
        #                'links' => [
        #                             {
        #                               'href' => 'https://kaizen.massopen.cloud:8774/344583b960c146319398dffb1d7b43b6/flavors/73ae9789-4fe9-4299-978c-9cb8f4964298',
        #                               'rel' => 'bookmark'
        #                             }
        #                           ]
        #              },
        #  'progress' => 0,
        #  'config_drive' => '',
        #  'metadata' => {},
        #  'addresses' => {},
        #  'OS-SRV-USG:launched_at' => undef,
        #  'status' => 'BUILD',
        #  'OS-EXT-STS:vm_state' => 'building',
        #  'key_name' => 'vinaykns'
        #};
        # 
        # Not sure if the VM status is:
        #    'OS-EXT-STS:power_state' => 0
        #    'status' => 'BUILD'
        #    'OS-EXT-STS:vm_state' => 'building'
        #    'status' => 'BUILD'

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my $ts = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

        my $project_id=$vm->{tenant_id};
        $project_id = $vm->{project_id} if length($vm->{project_id});

        $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{user_id}=$vm->{user_id};
        $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{end_ts}=$ts;
        $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{state}=$vm->{status};
        $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{name}=$vm->{name};
        $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{flavor}=$vm->{flavor};
        $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{event_type}="instant";

        if (defined($flavors->{$vm->{flavor}}) and $flavors->{$vm->{flavor}}->{vcpus})
        {
            # First try to get it from the flavor - in the case of resizing, this doesn't always work.
            $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{vcpus}=$flavors->{$vm->{flavor}}->{vcpus};
            $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{mem}=$flavors->{$vm->{flavor}}->{ram}/1024;
            $store->{project}->{$project_id}->{VM}->{$vm->{id}}->{events}->{$ts}->{disk_gb}=$flavors->{$vm->{flavor}}->{disk};
        }
        else
        {
            #my ($vcpu, $ram, $disk) =get_vm_details($store,$vm->{id});
        }

        #need to get the floating ip addresses done first
        #maybe need to get the networks/subnets done first 
        # example of address:
        #     'addresses' => {
        #         'mosaic_network' => [
        #             {
        #             'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:f9:60',
        #             'OS-EXT-IPS:type' => 'fixed',
        #             'version' => 4,
        #             'addr' => '192.168.0.4'
        #             },
        #             {
        #             'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:f9:60',
        #             'OS-EXT-IPS:type' => 'floating',
        #             'version' => 4,
        #             'addr' => '128.31.22.24'
        #             }
        #         ]
        #     }
        #$store = add_networks($store, $project_id, $vm->{id}, $vm->{addresses});
        
    }
    return undef;
}

1;
__END__
