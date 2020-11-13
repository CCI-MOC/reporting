
package Reporting::Services;

use strict;
use POSIX;
use v5.32;

use Data::Dumper;

use Reporting::Services::OpenStack;
use Reporting::Services::Zabbix;


my $DEBUG = 0;

sub _dispatch {
    my ( $service, $ua ) = @_;

    return ( undef, "ERROR: Service Item should be object:\n$service\n" )
        if ( not( ref $service eq 'HASH' ) );

    my ($obj, $err);
    # TODO: Dynamic loading over modules in Reporting::Services
    if ( $service->{type} eq 'OpenStack' ) {
        ($obj, $err) = Reporting::Services::OpenStack->new( $service, $ua );
    }
    elsif ( $service->{type} eq 'OpenShift' ) {
        ($obj, $err) = ( undef, "Not Implemented");
        #get_openshift_info(..., $service);
    }
    elsif ( $service->{type} eq 'Zabbix' ) {
        ($obj, $err) = Reporting::Services::Zabbix->new( $service, $ua );
    }
    else {
        ($obj, $err) = ( undef, "Unknown Service Type. In:\n$service");
    }
    $err = "$service->{type} ($service->{id}): $err" if $err and $service->{type};
    return ($obj, $err);
}

sub create {
    my ( $service, $ua ) = @_;
    
    print Dumper{%$service} if ($DEBUG);

    my ( $obj, $err ) = _dispatch( $service, $ua );
    return ( undef, "Reporting::Services: $err" ) if $err;
    return ( $obj, undef );
}

1;
__END__;
