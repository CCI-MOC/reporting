
package Reporting::DB::Role;
=head4 DB::Role

Database driver for user roles

=over
=cut

use strict;
use POSIX;
use v5.32;

=item $DB::Role::DEBUG

Enables Debugging for the module when truthy. Looks at the $DEBUG environment 
variable.

=cut
my $DEBUG = $ENV{DEBUG};

=item \$DB::Role->new


Creates a new 'subdriver' for the Address table. 
=cut
# TODO: Uses the given database handle
# to initialize the queries that will be used in its methods. 
sub new
{
    my ($cls, $db) = @_;
    die "Missing Database object" unless $db;
    return bless { 
        _select => $db->prepare("select role_id from role where role_name=? and role_level=?"),
    }, $cls;
}

# Re: Creation: should be handled statically at db_init time

# item \%DB::Role::_LEVELS
# Mapping of level names to their corresponding values in the database
my $_LEVELS = {
    institution => 1,
    moc_project => 2,
    project     => 3,
};

=item \$DB::Role->lookup($name, $level)

Returns the id corresponding to the given role descriptionat the given level

=cut
sub lookup
{
    print("DB::Roles::lookup") if $DEBUG;
    my ($self, $name, $level) = @_;
    print(": $level('$name')\n") if $DEBUG;

    die "Missing role name"             unless $name;
    die "Missing role level name"       unless $level;
    die "Unknown role level: $level\n"  unless $_LEVELS->{$level};

    $self->{_select}->execute($name, $_LEVELS->{$level});
    return $self->{_select}->fetchrow_arrayref->[0];
}

=back
=cut

1;
__END__
