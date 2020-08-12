
package Reporting::DB::Address;
=head4 DB::Address

Database driver for the address model

=over
=cut

use strict;
use POSIX;
use v5.32;

=item $DB::Address::DEBUG

Enables debugging for the module when truthy. Looks at the $DEBUG environment 
variable.

=cut
my $DEBUG = $ENV{DEBUG};

# item $DB::Address::_ID_SEQ
# Name of the database sequence the table 
my $_ID_SEQ = 'address_address_id_seq';
# item @DB::POC::_INTERNAL_KEYS
# Listing of keys that will be generated when creating a new POC
my @_INTERNAL_KEYS = ( 'address_id' );
# item @DB::Address::_RECOGNIZED_KEYS
# Listing of key names recognized as parameters to the new and lookup methods
my @_RECOGNIZED_KEYS = ( 'line1', 'line2', 'city', 'state', 'postal_code', 'country' );
# # item $DB::Address::FIELDS_HELP
# # Pregenerated message with the list of keys recognized by the new and 
# my $FIELDS_HELP = '[ ' . join(',', (map { "$_ => \$$_" } @_RECOGNIZED_KEYS)) . ' ]+';

=item \$DB::Address->new($db)

Creates a new 'subdriver' for the Address table. Uses the given database handle
to initialize the queries that will be used in its methods. 

=cut
sub new
{
    my ($cls, $dbh) = @_;
    die "Missing Database handle" unless $dbh;

    my @keys;
    push @keys, @_INTERNAL_KEYS;
    push @keys, @_RECOGNIZED_KEYS;
    my $columns = "(" . join(',', @keys) . ")";
    my $placeholders = "(" . join(',', ("?") x (scalar @keys)) . ")";

    return bless { 
        next_id => $dbh->prepare("SELECT NEXTVAL('$_ID_SEQ')"),
        insert  => $dbh->prepare("INSERT INTO address $columns VALUES $placeholders")
    }, $cls;
}

# item \$DB::Address->_parse_args(@_)
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

=item \$DB::Address->create(%params)

Creates a new Address entry with the given 
Will die if executing the statement against the database fails. 

=cut
sub create
{
    my $self = shift;
    my %params = _parse_args @_;

    $self->{next_id}->execute();
    my $id = $self->{next_id}->fetchrow_arrayref->[0];

    my @data = ($id); 
    foreach my $key (@_RECOGNIZED_KEYS)
    {
        if ($params{$key})
        {
            push @data, $params{$key};
        }
        else
        {
            push @data, 'null';
        }
    }

    $self->{insert}->execute(@data);
    return $id;
}

# TODO: Address Lookup? 
# TODO Priority: low
# sub lookup
# {
#     my $self = shift;
#     my %params = _parse_args @_;
# }


1;
__END__
