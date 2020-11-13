
package Reporting::Services::OpenStack::Panko;

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

sub compute_instance_event
{
    print("Panko::compute_instance_event\n") if $DEBUG;
    my ($self, $store, $event) = @_;

    my $rec = {};
    $rec->{event_type} = $event->{event_type};
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

sub floating_ip_event
{
    print("Panko::floating_ip_event: TODO\n") if $DEBUG;
    my ($self, $store, $event) = @_;
    # TODO
}

sub volume_event
{
    print("Panko::volume_event: TODO\n") if $DEBUG;
    my ($self, $store, $event) = @_;
    # TODO
}

sub identity_event
{
    if ($DEBUG)
    {
        state $warn_written = 0;
        unless ($warn_written)
        {
            print "WARN: identity events skipped\n";
            $warn_written = 1;
        }
    }
}


my $RECOGNIZED_EVENTS = {
    'compute.instance'  => sub { return compute_instance_event(@_); },
    floatingip          => sub { return floating_ip_event(@_); },
    volume              => sub { return volume_event(@_); },
    identity            => sub { return identity_event(@_); }
};
sub get_data
    {
    my ($self, $store) = @_;
    my $endpoint = "/v2/events";
    my $query = '?q.field=all_tenants&q.op=eq&q.value=True';

    my $resp = $self->{useragent}->authorized_request("$self->{url}$endpoint$query");

    my $json_fields = from_json($resp->decoded_content);
    event: foreach my $event (@$json_fields)
    {
        local $_ = $event->{event_type};
        while (my ($prefix, $handler) = (each %$RECOGNIZED_EVENTS))
        {
            if (/$prefix/)
            {
                $handler->($self, $store, $event);
                next event;
            }
        }

        state %warned_types;
        unless ($warned_types{$event->{event_type}})
        {
            print "WARN: Unhandeled event class: '$event->{event_type}'\n";
            $warned_types{$event->{event_type}} = 1;
        }
    }
    return undef;
}

sub get_volumes
{
    my ($self, $store) = @_;

    return undef;
}

1;
__END__
