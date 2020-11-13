
package Reporting::DB::MOCProject;
=head4 DB::MOCProject

Database driver for the moc_project model

=over
=cut

use strict;
use POSIX;
use v5.32;

=item $DB::MOCProject::DEBUG

Enables debugging for the module when truthy. Looks at the $DEBUG environment 
variable.

=cut
my $DEBUG               = $ENV{DEBUG};

# item $DB::MOCProject::_ID_SEQ
# Name of the database sequence the table 
my $_ID_SEQ             = 'moc_project_moc_project_id_seq_1';
# item @DB::POC::_INTERNAL_KEYS
# Listing of keys that will be generated when creating a new MOC Project
my @_INTERNAL_KEYS      = ( 'moc_project_id' );
# item @DB::MOCProject::_RECOGNIZED_KEYS
# Listing of key names recognized as parameters to the new and lookup methods
my @_RECOGNIZED_KEYS    = ( 'project_name' );
# item $DB::MOCProject::_FIELDS_HELP
# Pregenerated string listing keys recognized by create and lookup methods
my $_FIELDS_HELP        = join(',', (map { "$_ => \$$_" } @_RECOGNIZED_KEYS));

=item \$DB::MOCProject->new($db)

Creates a new 'subdriver' for the moc_project table. Uses the given database 
handle to initialize the queries that will be used in its methods.

=cut
sub new
{
    my ($cls, $db) = @_;
    die "Missing Database object" unless $db;

    my @columns;
    push @columns, @_INTERNAL_KEYS;
    push @columns, @_RECOGNIZED_KEYS;
    my $columns = "(" . join(',', @columns) . ")";
    my $placeholders = "(" . join(',', ("?") x (scalar @columns)) . ")";

    return bless { 
        _get_moc_project_id => $db->prepare("select moc_project_id from moc_project where moc_project_id=?"),
        _get_id_from_name   => $db->prepare("select moc_project_id from moc_project where project_name=?"),
        _insert             => $db->prepare("insert into moc_project $columns values $placeholders"),
        _next_id            => $db->prepare("SELECT NEXTVAL('$_ID_SEQ')"),
    }, $cls;
}

# item \$DB::MOCProject->_parse_args(@_)
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

=item \$DB::MOCProject->create(%params)

Creates a new MOC Project entry with the given 
Will die if executing the statement against the database fails. 

=cut
sub create
{
    print("DB::MOCProject::create\n") if $DEBUG;
    my $self = shift;

    die 'Usage: moc_project->create( [ $FIELDS_HELP ]+ )\n'  unless @_;
    my %params = _parse_args @_;

    $self->{_next_id}->execute();
    my $moc_project_id = $self->{_next_id}->fetchrow_arrayref->[0];

    my @real_data = ( $moc_project_id );
    foreach my $key (@_RECOGNIZED_KEYS)
    {
        if ($params{$key})
        {
            push @real_data, $params{$key};
        }
        else 
        {
            push @real_data, 'null';
        }
    }

    $self->{_insert}->execute(@real_data);
    return $moc_project_id;
}

=item \$DB::MOCProject->lookup(...)

Searchs for a MOC Project entry that best matches the parameters provided.
In order, prefers: 
 - Matching ID
 - Matching Project Name
Returns one of:
 - undef when no matches were found
 - a scalar id when a single match is found
 - an array of scalar ids when multiple matches are found
Will die if executing the statement against the database fails. 

=cut
sub lookup
{
    print("DB::MOCProject::lookup\n") if $DEBUG;
    my $self = shift;

    die "Usage moc_project->lookup( [ id => \$id, project_name => \$project_name]+ )\n" unless @_;
    my %params = _parse_args @_;

    if ($params{id})
    {
        my $stmt    = $self->{_get_moc_project_id};
        $stmt->execute($params{id});
        return $stmt->fetchrow_arrayref()->[0] if $stmt->rows > 0;
    }
    if ($params{project_name})
    {
        my $stmt    = $self->{_get_id_from_name};
        my @res     = ();
        $stmt->execute($params{project_name});
        while ( my $row = $stmt->fetchrow_arrayref() )
        {
            push @res, $row->[0];
        }
        return $res[0]  if (scalar @res) == 1;
        return @res     if (scalar @res);
    }
    return undef;
}

1;
__END__
