
package Reporting::DB::MOCProject;

use strict;
use v5.32;


my $DEBUG           = $ENV{DEBUG};
my $ID_SEQ          = 'moc_project_moc_project_id_seq_1';
my @RECOGNIZED_KEYS = ( 'project_name' );
my $FIELDS_HELP     = '[ ' . join(',', (map { "$_ => \$$_" } @RECOGNIZED_KEYS)) . ' ]+';


sub new
{
    my ($cls, $db) = @_;
    die "Missing Database object" unless $db;

    my $columns = join(',', @RECOGNIZED_KEYS);
    my $placeholders = join(',', ("?") x (scalar @RECOGNIZED_KEYS));

    return bless { 
        next_id             => $db->prepare("SELECT NEXTVAL('$ID_SEQ')"),
        insert              => $db->prepare("insert into project ($columns) values ($placeholders)"),
        get_moc_project_id  => $db->prepare("select moc_project_id from moc_project where moc_project_id=?"),
        get_id_from_name    => $db->prepare("select moc_project_id from moc_project where project_name=?"),
    }, $cls;
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

sub create
{
    print("DB::MOCProject::create\n") if $DEBUG;
    my $self = shift;

    die 'Usage: moc_project->create( $FIELDS_HELP )\n'  unless @_;
    my %params = parse_args @_;

    $self->{next_id}->execute();
    my $moc_project_id = $self->{next_id}->fetchrow_arrayref->[0];

    my @real_data = ( $moc_project_id );
    foreach my $key (@RECOGNIZED_KEYS)
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

    $self->{insert}->execute(@real_data);
    return $moc_project_id;
}

sub lookup
{
    print("DB::MOCProject::lookup\n") if $DEBUG;
    my $self = shift;

    die "Usage moc_project->lookup( [ id => \$id, project_name => \$project_name]+ )\n" unless @_;
    my %params = parse_args @_;

    if ($params{id})
    {
        my $stmt    = $self->{get_moc_project_id};
        $stmt->execute($params{id});
        return $stmt->fetchrow_arrayref()->[0] if $stmt->rows > 0;
    }
    if ($params{project_name})
    {
        my $stmt    = $self->{get_id_from_name};
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
