
package Reporting::DB;

use strict;
use POSIX;
use v5.32;

use Data::Dumper;
use DBI;

use Reporting::DB::Address;
use Reporting::DB::MOCProject;
use Reporting::DB::POC;
use Reporting::DB::Project;
use Reporting::DB::Roles;


my $DEBUG = $ENV{DEBUG};


sub connect 
{
    print("DB::connect\n") if $DEBUG;

    my ($cls, $params) = @_;

    die "Missing dbname for DB\n"       unless $params->{db_name};
    die "Missing host for DB\n"         unless $params->{host};
    die "Missing user for DB\n"         unless $params->{user};
    die "Missing password for user\n"   unless $params->{pass};
    $params->{port} = 5432              unless $params->{port};
    $params->{ssl}  = "prefer"          unless $params->{ssl};
    my $conn = DBI->connect("dbi:Pg:host=$params->{host} port=$params->{port} sslmode=$params->{ssl} dbname=$params->{db_name}",
                            $params->{user}, 
                            $params->{pass},
                            {
                                RaiseError => 1 # Force db calls to die upon failure
                            })
             or die $DBI::errstr;

    return bless {
        address     => Reporting::DB::Address->new($conn),
        moc_project => Reporting::DB::MOCProject->new($conn),
        poc         => Reporting::DB::POC->new($conn),
        project     => Reporting::DB::POC->new($conn),
        role        => Reporting::DB::Role->new($conn),
        _conn => $conn
    }, $cls;
}

sub prepare
{
    my $self = shift;
    return $self->{_conn}->prepare(@_);
}

sub get_timestamp
{
    print("DB::db::get_timestamp\n") if $DEBUG;
    my ($self) = @_;

    my $stmt = $self->{_conn}->prepare("select now()");
    $stmt->execute();
    return $stmt->fetchrow_arrayref()->[0];    
}

sub get_service_id
{
    print("DB::db::get_service_id\n") if $DEBUG;
    my ($self, $name) = @_;

    return undef unless length($name) > 0;

    my $smt = $self->{_conn}->prepare("select service_id from service where service_name=?");
    $smt->execute($name);
    # die $smt->errstr . "\n" if length($smt->errstr) > 0;

    if ($smt->rows == 0)
    {
        my $ins = $self->{_conn}->prepare("insert into service (service_name) values (?)");
        $ins->execute($name);
        # die $ins->errstr . "\n" if length($ins->errstr) > 0;

        $smt->execute($name);
        # die $smt->errstr . "\n" if length($smt->errstr) > 0;
    }
    return $smt->fetchrow_arrayref()->[0];
}
sub get_item_id
    {
    print("DB::db::get_item_id\n") if $DEBUG;
    my $self=shift;
    my $project_id=shift;
    my $item_uid=shift;
    my $item_name=shift;
    my $item_type_id=shift;

    my $item_id=undef;
    my $get_item_id_sth=undef;

    if(defined $item_type_id )
        {
        # print "select item_id from item where domain_id=$region_id and project_id=$project_id and item_type_id=$item_type_id and item_uid=$item_uid \n";
        $get_item_id_sth=$self->{_conn}->prepare("select item_id from item where project_id=? and item_type_id=? and item_uid=?");
        $get_item_id_sth->execute($project_id,$item_type_id,$item_uid);
        if($get_item_id_sth->rows==0)
            {
            # print "insert into item (domain_id,project_id,item_type_id,item_uid,item_name) values ($region_id,$project_id,$item_type_id,$item_uid,$item_name) \n";
            my $ins=$self->{_conn}->prepare("insert into item (project_id,item_type_id,item_uid,item_name) values (?,?,?,?,?)");
            if(!defined($item_name)) { $item_name=''; }
            $ins->execute($project_id,$item_type_id,$item_uid,$item_name);
            }
        $get_item_id_sth->execute($project_id,$item_type_id,$item_uid);
        }
    else
        {
        # print "select item_id from item where domain_id=$region_id and project_id=$project_id and item_uid=$item_uid \n";
        $get_item_id_sth=$self->{_conn}->prepare("select item_id from item where project_id=? and item_uid=?");
        $get_item_id_sth->execute($project_id,$item_uid);
        }

    # die $get_item_id_sth->errstr . "\n" if(length($get_item_id_sth->errstr)>0);
    my $row_array_ref=$get_item_id_sth->fetchrow_arrayref();
    my $item_id=undef;
    if(defined($row_array_ref))
        {
        $item_id=$row_array_ref->[0];
        }
    return $item_id;
    }

sub get_item_type_id
{
    print("DB::db::get_item_type_id\n") if $DEBUG;
    my ($self, $item) = @_;

    my $get_item_type_id_sth=$self->{_conn}->prepare("select item_type_id from item_type where item_definition=?");
    $get_item_type_id_sth->execute($item);
    if($get_item_type_id_sth->rows==0)
    {
        # Note: These should probably be statically prepared in the same way as roles ~TS

        # my $ins=$self->{_conn}->prepare("insert into item_type (item_definition,item_desc) values (?,null)");
        # $ins->execute($item);
        # $get_item_type_id_sth->execute($item);
        die;
    }

    # die($get_item_type_id_sth->errstr, "\n") if(length($get_item_type_id_sth->errstr)>0);
    my $item_type_id=$get_item_type_id_sth->fetchrow_arrayref()->[0];

    return $item_type_id;
}

sub get_item_ts_id
    {
    print("DB::db::get_item_ts_id\n") if $DEBUG;
    my $self=shift;
    my $project_id=shift;
    my $item_type_id=shift;
    my $item_id=shift;
    my $start_ts=shift; 
    my $end_ts=shift;
    my $state=shift;
    my $size=shift;
    my $item_ts;

    my $get_item_ts_id_sth;
    if(defined($item_type_id))
        {
        $get_item_ts_id_sth=$self->{_conn}->prepare("select * from item_ts where project_id=? and item_type_id=? and item_id=? and start_ts=?");
        $get_item_ts_id_sth->execute($project_id,$item_type_id,$item_id,$start_ts);
        if( $get_item_ts_id_sth->rows==0 )
            {
            my $ins=$self->{_conn}->prepare("insert into item_ts (project_id,item_type_id,item_id,start_ts,end_ts,state,item_size) values (?,?,?,?,?,?,?,?)");
            $ins->execute($project_id,$item_type_id,$item_id,$start_ts,$end_ts,$state,$size);
            }
        }
    else
        {
        # this will be a gocha - but in this case we don't have the information to perform the insert (we don't know the item_type)
        # However, in the mapping of items to items at a given timestam, we need to look up both records in the item_ts table.
        $get_item_ts_id_sth=$self->{_conn}->prepare("select * from item_ts where project_id=? and item_id=? and start_ts=?");
        $get_item_ts_id_sth->execute($project_id,$item_id,$start_ts);
        }        
    return $item_ts;
}

# FROM: https://perldoc.perl.org/perlobj.html#AUTOLOAD
# Used as a shim layer to dispatch DBI methods to the underlying object
# Should be removed once direct calls to DBI are no longer used by GetInfo & Co
# Would have implemented as inheritance stack except DBI hides its internals
# our $AUTOLOAD;
# sub AUTOLOAD {
#     my ($self) = @_;
#     my $called = $AUTOLOAD =~ s/.*:://r;

#     #print(Dumper{$self->{conn}->$called});
#     return $self->{conn}->$called->(@_) ; # if $self->{conn}->$called;
#     #die "No method \"$called\" in Reporting::DB or DBI";
# }

# sub DESTROY { 
#     local($., $@, $!, $^E, $?);
#     my ($self,) = @_;

#     $self->{conn}->disconnect() if $self->{conn};
# }

1;
__END__;
