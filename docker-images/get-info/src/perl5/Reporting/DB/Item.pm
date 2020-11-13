
package Reporting::DB::Item;
=head4 DB::Item

Database driver for the item model

=over
=cut

use strict;
use POSIX;
use v5.32;

=item $DB::Item::DEBUG

Enables debugging for the module when truthy. Looks at the $DEBUG environment 
variable.

=cut
my $DEBUG = $ENV{DEBUG};


=item \$DB::Item->new($db)

Creates a new 'subdriver' for the Item table. Uses the given database handle
to initialize the queries that will be used in its methods. 

=cut
sub new
{
	print("DB::Item::new\n") if $DEBUG > 1;
    my ($cls, $dbh) = @_;
    die "Missing Database handle" unless $dbh;

    return bless {
    	_lookup_by_id 	=> $dbh->prepare("select item_id from item where item_id=?"),
    	_lookup_by_uuid => $dbh->prepare("select item_id from item where item_uid=?"),
	}, $cls;
}

# item \$DB::Item->_parse_args(@_)
# Internal helper method for converting a list of key-value argument pairs back
# back a hash
sub _parse_args
{
    my %args;
    while (my $key = shift)
    {
        $args{$key} = shift;
    }
    %args;
}

=item \$DB::Item->create(%params)

Creates a new Item entry with the given parameters
Will die if executing the statement against the database fails. 

=cut
sub create {
	print("DB::Item::create\n") if $DEBUG > 1;
	my $self = shift;
	my %params = _parse_args @_;


}

=item \$DB::Item->create(%params)

Creates a new Item entry with the given 
Will die if executing the statement against the database fails. 

=cut
sub lookup {
	print("DB::Item::lookup\n") if $DEBUG > 1;
	my $self = shift;

    die "Usage: lookup( [ id => \$id, uuid => \$uuid ]+ )\n" unless @_;
	my %params = _parse_args @_;

	if ($params{id}) 
	{
		$self->{_lookup_by_id}->execute($params{id});
        return $params{id} if $self->{_lookup_by_id}->rows > 0;
	}
	if ($params{uuid})
	{
		my @res = ();
        $self->{_lookup_by_uuid}->execute($params{uuid});
        while ( my $row = $self->{_lookup_by_uuid}->fetchrow_arrayref)
        {
            push @res, $row->[0];
        }
        return $res[0] if (scalar @res) == 1;
        return @res if (scalar @res);
	}
}

1;
__END__
