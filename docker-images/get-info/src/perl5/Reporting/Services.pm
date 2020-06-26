
package Reporting::Services;

use strict;


my $DEBUG = $ENV{DEBUG} or 0;

sub create
{
	my ($service, $ua) = @_;

	# TODO: Dynamic loading over modules in Reporting::Services
	if (not (ref $service eq 'HASH'))
    {
    	return (undef, "ERROR: Service Item should be object:\n$service\n");
    }

    if ($DEBUG) 
    {
        print Dumper{%$service};
    }

    if ($service->{type} eq 'OpenStack')
    {
        return (Reporting::Services::OpenStack->new($ua, $service), undef);
    }
    elsif ($service->{type} eq 'OpenShift') 
    {
        return (undef, 'Warning: Not Implemented: $service{type} == OpenShift');
        #get_openshift_info(..., $service);
    }
    elsif ($service->{type} eq 'Zabbix')
    {
        return (undef, 'Warning: Not Implemented: $service{type} == Zabbix');
        #get_zabbix_info(..., $service);
    }
    else 
    {
        return (undef, "ERROR: Unknown Service Type '$service->{type}' in:\n$service\n");
    }
}

1;
__END__;
