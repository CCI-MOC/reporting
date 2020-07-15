
package Reporting::Services;

use Reporting::Services::OpenStack;

use strict;

my $DEBUG = $ENV{DEBUG};

sub create {
    my ( $service, $ua ) = @_;

    return ( undef, "ERROR: Service Item should be object:\n$service\n" )
        if ( not( ref $service eq 'HASH' ) );
    print Dumper{%$service} if ($DEBUG);

    # TODO: Dynamic loading over modules in Reporting::Services
    if ( $service->{type} eq 'OpenStack' ) {
        return Reporting::Services::OpenStack->new( $service, $ua );
    }
    elsif ( $service->{type} eq 'OpenShift' ) {
        return ( undef,
            "Warning: Not Implemented: \$service{type} == OpenShift\n" );

        #get_openshift_info(..., $service);
    }
    elsif ( $service->{type} eq 'Zabbix' ) {
        return ( undef,
            "Warning: Not Implemented: \$service{type} == Zabbix\n" );

        #get_zabbix_info(..., $service);
    }
    else {
        return ( undef,
            "ERROR: Unknown Service Type '$service->{type}' in:\n$service\n"
        );
    }
}

1;
__END__;
