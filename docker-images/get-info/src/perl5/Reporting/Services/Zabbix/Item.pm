
package Reporting::Services::Zabbix::Item;
=head4 Services::Zabbix::Item

TBD (To Be Documented)

=over
=cut

use strict;
use POSIX;
use v5.32;

use JSON::MaybeXS;


my $DEBUG = $ENV{DEBUG};

sub new {
	my ($cls, $rpc, $uri) = @_;

	return bless {
		rpc => $rpc,
	}, $cls;
}

sub get {
	my ($self) = @_;
	
	my $result = $self->{rpc}->call_named("item.get");
	print(json_encode($result));
	die;
}

=back
=cut

1;
__END__
