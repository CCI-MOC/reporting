
package Reporting::DB::Project;
=head4 DB::Project

Database driver for the address model

=over
=cut

use strict;
use POSIX;
use v5.32;

=item $DB::Project::DEBUG

Enables debugging for the module when truthy. Looks at the $DEBUG environment 
variable.

=cut
my $DEBUG = $ENV{DEBUG};

# item $DB::Project::_ID_SEQ
# Name of the database sequence the table 
my $ID_SEQ              = 'project_project_id_seq';
# item @DB::Project::_INTERNAL_KEYS
# Listing of keys that will be generated when creating a new POC
my @_INTERNAL_KEYS      = ('project_id', 'moc_project_id', 'service_id');
# item @DB::Project::_MANDATORY_KEYS
# Listing of key names recognized as parameters to the new and lookup methods
my @_MANDATORY_KEYS    = ( 'project_uuid' );
# item $DB::Project::_FIELDS_HELP
# Pregenerated string listing keys recognized by create and lookup methods
my $_FIELDS_HELP          = join(',', (map { "$_ => \$$_" } @_MANDATORY_KEYS));

=item \$DB::Project->new($db)

Creates a new 'subdriver' for the Project table.. Uses the given database
handle to initialize the queries that will be used in its methods. 

=cut
sub new
{
    my ($cls, $dbh, $db_mocproj) = @_;
    die "Missing Database object" unless $dbh;
    die "Missing MOC Project handler" unless $db_mocproj;
    
    my @db_keys;
    push @db_keys, @_INTERNAL_KEYS;
    push @db_keys, @_MANDATORY_KEYS;
    my $columns = "(" . join(',', @db_keys) . ")";
    my $placeholders = "(" . join(',', ("?") x (scalar @db_keys)) . ")";

    return bless { 
        _create_moc_project_id  => sub { return $db_mocproj->create(@_) },
        _lookup_moc_project_id  => sub { return $db_mocproj->lookup(@_) },
        _lookup_from_id         => $dbh->prepare("select project_id from project where project_id=?"),
        _lookup_from_uuid       => $dbh->prepare("select project_id from project where project_uuid=?"),
        _insert                 => $dbh->prepare("insert into project $columns values $placeholders"),
        _next_id                => $dbh->prepare("SELECT NEXTVAL('$ID_SEQ')"),
    }, $cls;
}

# item \$DB::Project->_parse_args(@_)
# Internal helper method for converting a list of key-value argument pairs back
# back a hash
sub parse_args
{
    my %args;
    while (my $key = shift)
    {
        $args{$key} = shift;
    }
    %args;
}

=item \$DB::Project->create(%params)

Creates a new Project entry with the given parameters

=cut
sub create
{
    print("DB::Project::create\n") if $DEBUG;
    my $self = shift;

    die "Usage: project->create( service_id => \$service_id, [ $_FIELDS_HELP ]+)\n" unless @_;
    my %params = parse_args @_;

    die "Missing 'service_id'\n" unless $params{service_id};
    my $service_id      = $params{service_id};

    my $moc_project_id  = $params{moc_project_id};
    $moc_project_id     = $self->{_lookup_moc_project_id}->(@_) unless $moc_project_id;
    $moc_project_id     = $self->{_create_moc_project_id}->(@_) unless $moc_project_id;

    $self->{_next_id}->execute();
    my $project_id = $self->{_next_id}->fetchrow_arrayref->[0];

    my @data = ($project_id,  $moc_project_id,  $service_id);
    foreach my $key (@_MANDATORY_KEYS)
    {
        die "Missing mandatory key: $key" unless ($params{$key});
        push @data, $params{$key};
    }

    $self->{_insert}->execute(@data) or die $self->{_insert}->errstr;
    return $project_id;
}

=item \$DB::Project->lookup(...)

Searchs for a Project entry that best matches the parameters provided.
In order, prefers: 
 - Matching ID
 - Matching Service UUID
Returns one of:
 - undef when no matches were found
 - a scalar id when a single match is found
 - an array of scalar ids when multiple matches are found
Will die if executing the statement against the database fails. 

=cut
sub lookup
{
    print("DB::Project::lookup\n") if $DEBUG;
    my $self = shift;

    die "Usage: lookup( [ id => \$id, uuid => \$uuid ]+ )\n" unless @_;
    my %params = parse_args @_;

    if ($params{id})
    {
        $self->{_lookup_from_id}->execute($params{id});
        return $params{id} if $self->{_lookup_from_id}->rows > 0;
    }
    if ($params{uuid})
    {
        my @res = ();
        $self->{_lookup_from_uuid}->execute($params{uuid});
        while ( my $row = $self->{_lookup_from_uuid}->fetchrow_arrayref)
        {
            push @res, $row->[0];
        }
        return $res[0] if (scalar @res) == 1;
        return @res if (scalar @res);
    }
    return undef;
}

1;
__END__;
