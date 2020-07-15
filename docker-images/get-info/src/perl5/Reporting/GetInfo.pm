
package Reporting::GetInfo;

use strict;
use POSIX;

use LWP::UserAgent;

use Reporting::Creds;
use Reporting::DB;
use Reporting::Services;


my $DEBUG = $ENV{DEBUG};


sub main
{
    my $creds = Reporting::Creds::load();

    die "ERROR: Missing Database Credentials\n"                     if (!($creds->{database})) ;
    die "ERROR: Credentials not an object:\n$creds->{database}\n"   if (ref $creds->{database} != 'HASH');
    die "ERROR: Missing Services\n"                                 if (!($creds->{services}));
    die "ERROR: Services not an array:\n$creds->{services}\n"       if (ref $creds->{services} != 'ARRAY');

    if (scalar @{$creds->{services}} == 0)
    {
        print "No Services to be run\n";
        return 1;
    }

    my $db   = $creds->{database}->{db_name} or die "Database Spec missing key 'db_name'\n";
    my $host = $creds->{database}->{host}    or die "Database Spec missing key 'host'\n";
    my $user = $creds->{database}->{user}    or die "Database Spec missing key 'user'\n";
    my $pass = $creds->{database}->{pass}    or die "Database Spec missing key 'pass'\n";

    print ("Connecting...") if $DEBUG;
    my $db = Reporting::DB->connect("dbi:Pg:host='$host';db='$db'", $user, $pass, {
        PrintError => 0,
        RaiseError => 1
    });
    print "\n" if $DEBUG;
    die "Could not connect to database?\n" unless $db;

    my $ua = LWP::UserAgent->new(
            #protocols_allowed   => [ 'http', 'https' ],
            timeout             => 15
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
        $service->store($db);
        die $_ if $_;
    }

    $db->disconnect();
    die $_ if $_;

    return 0;
}

1;
__END__;
