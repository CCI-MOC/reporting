
package Reporting::Services::OpenStack::Panko;

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

#  use panko this to find the instances.
#  This needs to be stored in a dababase.
sub get_data
    {
    my ($self, $store) = @_;
    my $endpoint = "/v2/events";
    my $query = '?q.field=all_tenants&q.op=eq&q.value=True';

    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint$query");

    my $json_fields = from_json($resp->decoded_content);
    my $rec;
    foreach my $event (@$json_fields)
    {
        if($event->{event_type}=~/compute\.instance/)
        {
            $rec=undef;
            $rec->{event_type}=$event->{event_type};
            # print Dumper $event;
            foreach my $trait (@{$event->{traits}})
            {
                $rec->{$trait->{name}} = $trait->{value};
                # if   ($trait->{name} eq  'project_id')             { $rec->{project_id}  = $trait->{value}; }
                # elsif($trait->{name} eq  'instance_id')            { $rec->{instance_id} = $trait->{value}; }
                # elsif($trait->{name} eq  'audit_period_beginning') { $rec->{start_ts}    = $trait->{value}; }
                # elsif($trait->{name} eq  'audit_period_ending')    { $rec->{end_ts}      = $trait->{value}; }
                # elsif($trait->{name} eq  'state')                  { $rec->{state}       = $trait->{value}; }
                # elsif($trait->{name} eq  'instance_type')          { $rec->{flavor}      = $trait->{value}; }
                # elsif($trait->{name} eq  'vcpus')                  { $rec->{vcpus}       = $trait->{value}; }
                # elsif($trait->{name} eq  'memory_mb')              { $rec->{mem}         = $trait->{value}; }
                # elsif($trait->{name} eq  'disk_gb')                { $rec->{disk_gb}     = $trait->{value}; }
            }
            $store->{project}->{$rec->{project_id}}->{vm_cnt}=1;
            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{event_cnt}=1;

            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{events}->{$rec->{start_ts}}->{end_ts}=$rec->{end_ts};
            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{events}->{$rec->{start_ts}}->{state}=$rec->{state};
            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{events}->{$rec->{start_ts}}->{flavor}=$rec->{flavor};
            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{events}->{$rec->{start_ts}}->{vcpus}=$rec->{vcpus};
            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{events}->{$rec->{start_ts}}->{mem}=$rec->{mem}/1024;
            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{events}->{$rec->{start_ts}}->{disk_gb}=$rec->{disk_gb};
            $store->{project}->{$rec->{project_id}}->{VM}->{$rec->{instance_id}}->{events}->{$rec->{start_ts}}->{event_type}=$rec->{event_type};
        }
        else 
        {
            print STDERR "---> Unhandeled event: $event->{event_type}\n";
        }    
    }
    #print Dumper{@$json_fields};
    #print Dumper{%$store};
    #exit;
    return undef;
}

sub get_volumes
{
    my ($self, $store) = @_;

    return undef;
}

1;
__END__
