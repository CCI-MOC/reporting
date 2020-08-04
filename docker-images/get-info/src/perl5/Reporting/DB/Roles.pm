
package Reporting::DB::Role;

use strict;
use Data::Dumper;


my $DEBUG = $ENV{DEBUG};


sub new
{
    my ($cls, $db) = @_;
    die "Missing Database object" unless $db;
    return bless { db => $db }, $cls;
}

my $LEVELS = {
    institution => 1,
    moc_project => 2,
    project     => 3,
};
sub lookup
{
    print("DB::Roles::lookup") if $DEBUG;
    my ($self, $name, $level) = @_;
    print(": $level('$name')\n") if $DEBUG;

    die "Missing role name"             unless $name;
    die "Missing role level name"       unless $level;
    die "Unknown role level: $level\n"  unless $LEVELS->{$level};

    my $stmt = $self->{db}->prepare("select role_id from role where role_name=? and role_level=?");
    $stmt->execute($name, $LEVELS->{$level});
    return $stmt->fetchrow_arrayref->[0];
}

1;
__END__
