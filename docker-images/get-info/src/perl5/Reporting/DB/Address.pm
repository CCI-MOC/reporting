
package Reporting::DB::Address;

use strict;
use v5.32;


my $DEBUG           = $ENV{DEBUG};
my $ID_SEQ          = 'address_address_id_seq';
my @RECOGNIZED_KEYS = ( 'address_id', 'line1', 'line2', 'city', 'state', 'postal_code', 'country' );
my $FIELDS_HELP     = '[ ' . join(',', (map { "$_ => \$$_" } @RECOGNIZED_KEYS)) . ' ]+';

sub new
{
    my ($cls, $db) = @_;
    die "Missing Database object" unless $db;

    my $columns = "(" . join(',', @RECOGNIZED_KEYS) . ")";
    my $placeholders = "(" . join(',', ("?") x (scalar @RECOGNIZED_KEYS)) . ")";

    return bless { 
        next_id => $db->prepare("SELECT NEXTVAL('$ID_SEQ')"),
        insert  => $db->prepare("INSERT INTO address $columns VALUES $placeholders")
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
    my $self = shift;
    my %params = parse_args @_;

    $self->{next_id}->execute();
    my $id = $self->{next_id}->fetchrow_arrayref->[0];

    my @real_data = ($id); 
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
    return $id;
}

sub lookup
{
    my $self = shift;
    my %params = parse_args @_;


}


1;
__END__
