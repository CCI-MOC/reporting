
package Reporting::DB::Project;

use strict;
use v5.32;


my $DEBUG = $ENV{DEBUG};


sub new
{
    my ($cls, $db) = @_;
    die "Missing Database object" unless $db;
    return bless { db => $db }, $cls;
}

sub parse_args
{
    my %args;
    while (my $key = shift)
    {
        $args{$key} = shift;
    }
    %args;
}

my $ID_SEQ          = 'project_project_id_seq';
my @RECOGNIZED_KEYS = ( 'project_uuid' );
my $USAGE_HELP      = "Usage: project->create( service_id => \$service_id, [ " . \
                        join(',', (map { "$_ => \$$_" } @RECOGNIZED_KEYS)) . \
                        " ]+ )";
sub create
{
    print("DB::Project::create\n") if $DEBUG;
    my $self = shift;

    die "$USAGE_HELP\n" unless @_;
    my %params = parse_args @_;

    die "$USAGE_HELP\nMissing 'service_id'\n" unless $params{service_id};
    my $service_id      = $params{service_id};
    my $moc_project_id  = $params{moc_project_id};
    $moc_project_id     = $self->{db}->{moc_project}->create(@_) unless $moc_project_id;

    my $next_id_stmt = $self->{db}->prepare("SELECT NEXTVAL('$ID_SEQ')");
    $next_id_stmt->execute();
    my $project_id = $next_id_stmt->fetchrow_arrayref->[0];

    my @used_keys = ('project_id', 'moc_project_id', 'service_id');
    my @real_data = ($project_id,  $moc_project_id,  $service_id);
    foreach my $key (@RECOGNIZED_KEYS)
    {
        if ($params{$key})
        {
            push @used_keys, $key;
            push @real_data, $params{$key};
        }
    }

    my $columns = join(',', @used_keys);
    my $placeholders = join(',', ("?") x (scalar @used_keys));
    my $stmt = $self->{db}->prepare("insert into project ($columns) values ($placeholders)");
    $stmt->execute(@real_data);
    return $project_id;
}

sub lookup
{
    print("DB::Project::lookup\n") if $DEBUG;
    my $self = shift;

    die "Usage: lookup( [ id => \$id, uuid => \$uuid ]+ )\n" unless @_;
    my %params = parse_args @_;

    my $get_project_id          = $self->{db}->prepare("select project_id from project where project_id=?");
    my $get_project_from_uuid   = $self->{db}->prepare("select project_id from project where project_uuid=?");

    if ($params{id})
    {
        $get_project_id->execute($params{id});
        return $params{id} if $get_project_id->rows > 0;
    }
    if ($params{uuid})
    {
        my @res = ();
        $get_project_from_uuid->execute($params{uuid});
        while ( my $row = $get_project_from_uuid->fetchrow_arrayref)
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
