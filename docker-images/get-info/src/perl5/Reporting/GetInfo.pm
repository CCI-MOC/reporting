
package Reporting::GetInfo;

use strict;
use POSIX;
use v5.32;

use LWP::UserAgent;

use Reporting::Creds;
use Reporting::DB;
use Reporting::Services;


my $DEBUG = $ENV{DEBUG};


sub main
{
    my $creds = Reporting::Creds::load();

    die "ERROR: Missing Database Credentials\n"                     if (!($creds->{database})) ;
    die "ERROR: Credentials not an object:\n$creds->{database}\n"   if (ref $creds->{database} ne 'HASH');
    die "ERROR: Missing Services\n"                                 if (!($creds->{services}));
    die "ERROR: Services not an array:\n$creds->{services}\n"       if (ref $creds->{services} ne 'ARRAY');

    if (scalar @{$creds->{services}} == 0)
    {
        print "No Services to be run\n";
        return 1;
    }

    print ("Connecting...") if $DEBUG;
    my $db = Reporting::DB->connect($creds->{database});
    print "\n" if $DEBUG;
    die "Could not connect to database?\n" unless $db;

    # Note: Proposed driver Changes ~TS
    #       (Perform a symmetric set diff operation)
    #       - Load State from Database
    #           - Initialize proper objects based on loaded state
    #       - Load State in Underlying Services
    #           - 'RAII': when hitting an unseen object, auto create db entry/s
    #       - Mark Objects that have disappeared

    # Note: Algorithm of the above ~TS
    #   100 var active      <= db_load_active
    #   150 var inactive    <= db_load_inactive
    #   199 var active_seen <= []
    #   200 loop services:
    #   210     if service in active:
    #   211         active_seen += [service]
    #   212         active      -= [service]
    #   220     else:
    #   221         db_create(service)
    #   222         active_seen += [service]
    #   300 loop active:
    #   310     inactive    += [entry]

    # Note: Program Stucture Goals ~TS
    #       - Simplify mapping between service data and db tables
    #           - Would like a declarative binding; eg:
    #               Keystone->users <=> db->users
    #               Keystone->users->projects <=> db->users2projects
    #       - 


    my $ua = LWP::UserAgent->new(
            #protocols_allowed   => [ 'http', 'https' ],
            keep_alive  => 1,
            timeout     => 15
        );

    my @loaded_services;
    foreach my $service (@{$creds->{services}})
    {
        my ($svc, $err) = Reporting::Services::create( $service, $ua );
        die $err if $err;
        push @loaded_services, $svc;
    } 
    foreach my $service (@loaded_services)
    {
        my $err = $service->store($db);
        die $err if $err;
    }

    $db->disconnect();
    return 0;
}

1;
__END__;


=head1 MOC Reporting
=head2 GetInfo.pm

Get Info is the component of the Reporting stack that collects data from
underlying infrastructure and stores it into a postgres database. Both the 
services from which data needs to be collected and the datbase into which that
data is being stored are configured via a json file. GetInfo.pm recieves the
location of the json file via the environment variable ${CREDS_FILE}.
Alternatively, the text can be passed directly using the environment variable
${CREDS_TEXT}. The expected format of the json file is as follows:

=begin json

{
    "database": [
        "mandatory", 
        "Configuration block for the underlying database",
        {
            "host":     [ "mandatory", "Hostname of the machine with the database", "hostname" ],
            "db_name":  [ "mandatory", "Name of the database in postgresql", "database" ],
            "user":     [ "mandatory", "Usernaem to authenticate to the database", "username" ],
            "pass":     [ "mandatory", "User password for the database", "password" ],
            "port":     [ "optional", "Port Postgresql is listening on", 5432 ],
            "ssl":      [ 
                "optional", 
                "SSL Configuration. See DBI::Pg for more info", 
                { "enum": [ "disable", "allow", "prefer", "require" ] } 
            ]
        }
    ], 
    "services": [
        "mandatory",
        "List of services to collect data from",
        [
            {
                "_": "See Reporting::Services.pm for specification"
            },
            ...
        ]
    ]
}

=end json

Example configuration files are provided in Reporting/docker-images/get-info.

=cut
