
package Reporting::Services::Zabbix::Host;
=head4 Services::Zabbix::Host

TBD (To Be Documented)

=over
=cut

use strict;
use POSIX;
use v5.32;


my $DEBUG = $ENV{DEBUG};

sub new {
	print("Zabbix::Host::new\n") if $DEBUG > 1;

	my ($cls, $rpc) = @_;

	return bless {
		rpc => $rpc,
	}, $cls;
}

sub get {
	print("Zabbix::Host::get\n") if $DEBUG > 1;

	my ($self) = @_;

	return $self->{rpc}->call_named("host.get");
}

=back
=cut

1;
__END__
