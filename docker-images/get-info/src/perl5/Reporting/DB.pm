
package Reporting::DB;

use DBI;

use strict;

my $DEBUG = $ENV{DEBUG} or 0;

sub connect
{
    my ($class, $db_spec) = @_;

    my $db   = $db_spec->{db_name} or die "Database Spec missing key 'db_name'\n";
    my $host = $db_spec->{host}    or die "Database Spec missing key 'host'\n";
    my $user = $db_spec->{user}    or die "Database Spec missing key 'user'\n";
    my $pass = $db_spec->{pass}    or die "Database Spec missing key 'pass'\n";

    print "Connecting..." if ($DEBUG);
    my $conn = DBI->connect("dbi:Pg:host='$host';db='$db'", $user, $pass) or return undef;
    print "\n" if ($DEBUG);

    return bless {
        conn => $conn,
    }, $class;
}

sub get_timestamp
{
    my ($self) = @_;

    my $stmt = $self->{conn}->prepare("select now()");
    $stmt->execute();
    return $stmt->fetchrow_arrayref()->[0];    
}

sub close
{
    my ($self) = @_;
    $self->{conn}->disconnect();
    delete $self->{conn};
}

# FROM: https://perldoc.perl.org/perlobj.html#AUTOLOAD
# Used as a shim layer to dispatch DBI methods to the underlying object
# Should be removed once direct calls to DBI are no longer used by GetInfo & Co
# Would have implemented as inheritance stack except DBI hides its internals
our $AUTOLOAD;
sub AUTOLOAD {
    my ($self) = @_;
    my $called = $AUTOLOAD =~ s/.*:://r;
    return $self->{conn}->{$called}(@_) if $self->{conn}->{$called};
    die "No method \"$called\" in Reporting::DB or DBI";
}

sub DESTROY { 
    local($., $@, $!, $^E, $?);
    my ($self,) = @_;

    $self->{conn}->disconnect() if $self->{conn};
}

1;
__END__;
