
package Reporting::DB::POC;

use strict;
use Data::Dumper;


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

my $ID_SEQ = 'poc_poc_id_seq';
my @RECOGNIZED_KEYS = ( 'first_name', 'last_name', 'username', 'email', 'phone' );
my $FIELDS_HELP = join(',', (map { "$_ => \$$_" } @RECOGNIZED_KEYS));
sub create
{
    print("DB::POC::create\n") if $DEBUG;
    my $self = shift;

    die "Usage: poc->create($FIELDS_HELP, \%address_params)\n" unless @_;
    my %params = parse_args @_;

    my $next_id_stmt = $self->{db}->prepare("SELECT NEXTVAL('$ID_SEQ')");
    $next_id_stmt->execute();
    my $id = $next_id_stmt->fetchrow_arrayref->[0];

    my $addr_id = $self->{db}->{address}->create(@_);

    my @used_keys = ('poc_id', 'address_id');
    my @real_data = ($id, $addr_id); 
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
    my $stmt = $self->{db}->prepare("insert into poc ($columns) values ($placeholders)");
    $stmt->execute(@real_data);
    return $id;
}

sub lookup
{
    print("DB::POC::lookup\n") if $DEBUG;
    my $self = shift;

    die "Usage: lookup( [ id => \$id, service_ids => { \$service => \$uuid ... } ]+ )\n" unless @_;
    my %params = parse_args @_;

    my $get_poc_id          = $self->{db}->prepare("select poc_id from poc where poc_id=?");
    my $get_poc_sth         = $self->{db}->prepare("select poc_id, project_id from poc2project where service_uuid=?");
    my $get_sid_from_uuid   = $self->{db}->prepare("select service_id from project where project_id=?");

    if ($params{id})
    {
        $get_poc_id->execute($params{id});
        return $params{id} if $get_poc_id->rows > 0;
    }
    if ($params{service_ids})
    {
        while ( my ($service_id, $uuid) = (each %{$params{service_ids}}) )
        {
            $get_poc_sth->execute($uuid);
            while ( my ($poc_id, $project_id) = $get_poc_sth->fetchrow_array() )
            {
                $get_sid_from_uuid->execute($project_id);
                return $poc_id if $service_id == $get_sid_from_uuid->fetchrow_arrayref->[0];
            }
        }
    }
    return undef;
}

1;
__END__
