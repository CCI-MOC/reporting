    
package Reporting::Services::OpenStack;

use strict;
use POSIX;

use Data::Dumper;
use Date::Parse;
use JSON;
use Parse::CSV;
use Time::Local;
use YAML::XS;

use Reporting::Services::OpenStack::Catalog;
use Reporting::Services::OpenStack::Cinder;
use Reporting::Services::OpenStack::Dump qw/ dump_to_db /;
use Reporting::Services::OpenStack::Keystone;
use Reporting::Services::OpenStack::Neutron;
use Reporting::Services::OpenStack::Nova;
use Reporting::Services::OpenStack::Panko;
use Reporting::Services::OpenStack::UserAgent;


my $DEBUG = $ENV{DEBUG};

sub new
{
    my ($cls, $service, $ua) = @_;

    return (undef, "Missing URL")           unless $service->{url};
    return (undef, "Missing User")          unless $service->{user};
    return (undef, "Missing Password")      unless $service->{pass};
    return (undef, "Missing Service Name")  unless $service->{id};
    return (undef, "Missing UserAgent")     unless $ua;

    my $self = bless {
            id => $service->{id}
    }, $cls;
    my $err;

    print("OpenStack: Create Useragent\n") if $DEBUG;
    $self->{useragent}          = Reporting::Services::OpenStack::UserAgent->new( $ua, 
                                                                                  $service->{user}, 
                                                                                  $service->{pass});
    print("OpenStack: Create Keystone\n") if $DEBUG;
    $self->{keystone}           = Reporting::Services::OpenStack::Keystone->new( $self->{useragent}, $service->{url} );
    $self->{useragent}->set_auth_provider($self->{keystone});
    $self->{useragent}->get_unscoped_token();

    print("OpenStack: Load Catalog\n") if $DEBUG;
    ($self->{catalog}, $err)    = Reporting::Services::OpenStack::Catalog-> new( $self->{keystone} );
    return (undef, $err) if $err;

    print("OpenStack: Create Subservices\n") if $DEBUG;
    # TODO: Refactor to create a corresponding backend for every (supported?) item in the catalog
    $self->{cinder}             = Reporting::Services::OpenStack::Cinder->  new( $self->{useragent}, $self->{catalog}->cinderv3->{url});
    $self->{neutron}            = Reporting::Services::OpenStack::Neutron-> new( $self->{useragent}, $self->{catalog}->neutron->{url});
    $self->{nova}               = Reporting::Services::OpenStack::Nova->    new( $self->{useragent}, $self->{catalog}->nova->{url});
    $self->{panko}              = Reporting::Services::OpenStack::Panko->   new( $self->{useragent}, $self->{catalog}->panko->{url});

    return ($self, undef);
}

# stage2 process how long it has been used

# data->$project_id->project_name
#                  ->user_id->username
#                           ->$instance_id->instance_name
#                                         ->{timestamp}->event_type
#                                                      ->vCPU
#                                                      ->mem
#                                                      ->disk

sub build_instace_to_proj_index
{
    my $proj = shift;

    my $index;
    for my $proj_id (keys %{$proj}) 
    {
        if($proj->{$proj_id}->{vm_cnt} > 0)
        {
            my $vms = $proj->{$proj_id}->{VM};
            foreach my $vm_id (keys %{$vms})
            {
                $index->{$vm_id}=$proj_id;
            }
        } 
    }
    return $index;
}

# get all volumes


#sub add_addresses
#    {
#    my $os_info=shift;
#    my $project_id=shift;
#    my $vm_id=shift;
#    my %addresses=shift;
#
#    $os_info->{floating_ip}->
#    
#    }

# sub hash_merge
# {
#     my ($tgt, $src) = @_;
#     die if ((not (ref $tgt eq 'HASH')) or (not (ref $src eq 'HASH')));

#     my $rv = $tgt;
#     for my $key (keys %$src) 
#     {
#         if (not $tgt->{$key}) 
#         {
#             $tgt->{$key} = $src->{$key};
#         }
#         elsif ((ref $tgt->{$key} eq 'HASH') and (ref $src->{$key} eq 'HASH'))
#         {
#             $tgt->{$key} = hash_merge($tgt->{$key}, $src->{$key});
#         }
#         elsif ((ref $tgt->{$key} eq 'ARRAY') and (ref $src->{$key} eq 'ARRAY'))
#         {
#             push @{$tgt->{$key}}, @{$src->{$key}};
#         }
#         else 
#         {
#             $tgt->{'{$key}_0'} = $tgt->{$key} if (not $tgt->{'{$key}_0'});
#             delete $tgt->{$key} if $tgt->{$key};

#             my $i = 1;
#             $i += 1 while ($tgt->{'{$key}_{$i}'});
#             $tgt->{'{$key}_{$i}'} = $src->{$key};
#         }
#     }
# }

sub store
{
    my ($self, $db) = @_;

    my $timestamp   = $db->get_timestamp();
    my $service_id  = $db->get_service_id($self->{id});
    my @steps = (
        # [ "Get OpenStack Projects",     sub { return $self->{keystone}->    load_os_projects(@_) } ],
        [ "Load Project Info",          sub { return $self->{keystone}->get_all_projects(@_) } ],
        [ "Load Users",                 sub { return $self->{keystone}->get_all_users(@_) } ],
        [ "Get OpenStack VM Flavors",   sub { return $self->{nova}->    get_os_flavors(@_) } ],
        [ "Get Network Configuration",  sub { return $self->{neutron}-> get_floating_ips(@_) } ],
        [ "Get OpenStack Instances",    sub { return $self->{nova}->    get_all_vm_details(@_) } ],
        [ "Load Cinder Volume Data",    sub { return $self->{cinder}->  get_volumes(@_) } ],
        [ "Load Panko Data",            sub { return $self->{panko}->   get_data(@_) } ],
        [ "End of OpenStack Info",      sub { } ],
    );

    # TODO: Database description Re-encapsulation
    ### TD A: Begin Transaction (Possibly in GetInfo Driver?)
    my $i = 1;
    for my $tupl (@steps)
    {
        my ($text, $step) = @$tupl;
        if ($text)
        {
            print "$i ---> $text\n";
            $i++;
        }
        ### TD B: Haveeach step write directly to the database
        ####        eg. my $err = $step->($db)
        ####        requries db object cleanly handle direct calls on 'tables'
        my $err = $step->($self);
        return $err if $err;
    }

    ### TD C: Commit Transaction (Possibly in GetInfo Driver?)
    dump_to_db($self, $db, $service_id, $timestamp);
    return undef;
}

1;
__END__;
