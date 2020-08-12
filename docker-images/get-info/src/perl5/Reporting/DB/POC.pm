
package Reporting::DB::POC;
=head4 DB::POC

Database driver for the moc_project model

=over
=cut

use strict;
use POSIX;
use v5.32;

=item $DB::POC::DEBUG

Enables debugging for the module when truthy. Looks at the $DEBUG environment 
variable.

=cut
my $DEBUG = $ENV{DEBUG};

# item $DB::POC::_ID_SEQ
# Name of the database sequence the table 
my $_ID_SEQ = 'poc_poc_id_seq';
# item @DB::POC::_INTERNAL_KEYS
# Listing of keys that will be generated when creating a new POC
my @_INTERNAL_KEYS = ( 'poc_id', 'address_id' );
# item @DB::POC::_RECOGNIZED_KEYS
# Listing of key names recognized as parameters to the new and lookup methods
my @_RECOGNIZED_KEYS = ( 'first_name', 'last_name', 'username', 'email', 'phone' );
# item $DB::POC::_FIELDS_HELP
# Pregenerated string listing keys recognized by create and lookup methods
my $_FIELDS_HELP = join(',', (map { "$_ => \$$_" } @_RECOGNIZED_KEYS));

=item \$DB::POC->new($db)

Creates a new 'subdriver' for the Address table.. 

=cut
# TODO: Uses the given database handle
# to initialize the queries that will be used in its methods. 
sub new
{
    my ($cls, $dbh, $db_addr) = @_;
    die "Missing Database handle" unless $dbh;
    die "Missind Address Handler" unless $db_addr;

    my @keys;
    push @keys, @_INTERNAL_KEYS;
    push @keys, @_RECOGNIZED_KEYS;
    my $columns = "(" . join(',', @keys) . ")";
    my $placeholders = "(" . join(',', ("?") x (scalar @keys)) . ")";

    return bless {
        _get_poc_from_id    => $dbh->prepare("select poc_id from poc where poc_id=?"),
        _next_id            => $dbh->prepare("SELECT NEXTVAL('$_ID_SEQ')"),
        _insert             => $dbh->prepare("insert into poc $columns values $placeholders"),
        _new_addr_id        => sub { return $db_addr->create(@_); },

        # TODO: Change to be lookups against other handlers
        _get_poc_from_suuid => $dbh->prepare("select poc_id, project_id from poc2project where service_uuid=?"),
        _get_sid_from_puuid => $dbh->prepare("select service_id from project where project_id=?"),
    }, $cls;
}

# item \$DB::POC->_parse_args(@_)
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

=item \$DB::POC->create(%params)

Creates a new POC entry with the given parameters

=cut
sub create
{
    print("DB::POC::create\n") if $DEBUG;
    my $self = shift;

    die "Usage: poc->create($_FIELDS_HELP, \%address_params)\n" unless @_;
    my %params = _parse_args @_;

    $self->{_next_id}->execute();
    my $id = $self->{_next_id}->fetchrow_arrayref->[0];

    my $addr_id = $self->{_new_addr_id}->(@_);

    my @data = ($id, $addr_id); 
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

    $self->{_insert}->execute(@data);
    return $id;
}

=item \$DB::POC->lookup(...)

Searchs for a POC entry that best matches the parameters provided.
In order, prefers: 
 - Matching ID
 - Matching Service UUID
Returns one of:
 - undef when no matches were found
 - a scalar id when a single match is found
 - an array of scalar ids when multiple matches are found
Will die if executing the statement against the database fails. 

=cut
# TODO: Match against email address
sub lookup
{
    print("DB::POC::lookup\n") if $DEBUG;
    my $self = shift;

    die "Usage: lookup( [ id => \$id, service_ids => { \$service => \$uuid ... } ]+ )\n" unless @_;
    my %params = _parse_args @_;

    if ($params{id})
    {
        $self->{_get_poc_from_id}->execute($params{id});
        return $params{id} if $self->{_get_poc_from_id}->rows > 0;
    }
    if ($params{service_ids})
    {
        while ( my ($service_id, $uuid) = (each %{$params{service_ids}}) )
        {
            $self->{_get_poc_from_suuid}->execute($uuid);
            while ( my ($poc_id, $project_id) = $self->{_get_poc_from_suuid}->fetchrow_array() )
            {
                $self->{_get_sid_from_puuid}->execute($project_id);
                return $poc_id if $service_id == $self->{_get_sid_from_puuid}->fetchrow_arrayref->[0];
            }
        }
    }
    return undef;
}

1;
__END__
