
# Pre: Assumes that db calls die upon failure

package Reporting::DB;

use strict;

use Data::Dumper;
use DBI;
use vars qw/ @ISA /;

@ISA = qw/ DBI /;
my $DEBUG = $ENV{DEBUG};


package Reporting::DB::db;
use vars qw/ @ISA /;
@ISA = qw/ DBI::db /;

sub get_timestamp
{
    print("DB::db::get_timestamp\n") if $DEBUG;
    my ($self) = @_;

    my $stmt = $self->SUPER::prepare("select now()");
    $stmt->execute();
    return $stmt->fetchrow_arrayref()->[0];    
}

sub get_service_id
{
    print("DB::db::get_service_id\n") if $DEBUG;
    my ($self, $name) = @_;

    return undef unless length($name) > 0;

    my $smt = $self->SUPER::prepare("select service_id from service where service_name=?");
    $smt->execute($name);
    # die $smt->errstr . "\n" if length($smt->errstr) > 0;

    if ($smt->rows == 0)
    {
        my $ins = $self->SUPER::prepare("insert into service (service_name) values (?)");
        $ins->execute($name);
        # die $ins->errstr . "\n" if length($ins->errstr) > 0;

        $smt->execute($name);
        # die $smt->errstr . "\n" if length($smt->errstr) > 0;
    }
    return $smt->fetchrow_arrayref()->[0];
}

sub get_poc_id
{
    print("DB::db::get_poc_id\n") if $DEBUG;
    my $self=shift;     # req
    my $uid=shift;      # required
    my $name=shift;     # opt - required to add a user
    my $email=shift;    # opt - required to add a user

    my $poc_id=undef;
    my $get_poc_sth = $self->SUPER::prepare("select poc_id from poc where user_uid=?");
    $get_poc_sth->execute($uid);
    if($get_poc_sth->rows==0 and length($uid)>0 and length($name)>0)
        {
        my $ins=$self->SUPER::prepare("insert into poc (user_uid, username, email) values (?,?,?)");
        $ins->execute($uid,$name,$email);
        # die $ins->errstr . "\n" if(length($ins->errstr)>0);
        $get_poc_sth->execute($uid);
        }
    $poc_id=$get_poc_sth->fetchrow_arrayref()->[0];
    return $poc_id;
    }

sub get_moc_project_id
{
    print("DB::db::get_moc_project_id\n") if $DEBUG;
    my $self = shift;
    my $name = shift;

    return undef unless length($name) > 0;

    my $moc_project_id;
    my $sth = $self->SUPER::prepare("select moc_project_id from moc_project where project_name=?");
    $sth->execute($name);
    # die $sth->errstr."\n" if length($sth->errstr) > 0;
    if($sth->rows == 0) {
        my $ins = $self->SUPER::prepare("insert into moc_project (project_name) values (?)");
        $ins->execute($name);
        # die $ins->errstr."\n" if length($sth->errstr) > 0;

        $sth->execute($name);
        # die $sth->errstr."\n" if length($sth->errstr) > 0;
    }
    $moc_project_id = $sth->fetchrow_arrayref()->[0];
    return $moc_project_id
}

sub get_project_id
{
    print("DB::db::get_project_id\n") if $DEBUG;
    my $self=shift;
    my $uuid=shift;
    my $name=shift;
    my $service_id=shift;

    print(" $service_id->$uuid ($name)\n") if $DEBUG;
    return undef unless length($uuid) > 0;

    my $sth=$self->SUPER::prepare("select project_id from project where project_uuid=?");
    $sth->execute($uuid);
    if($sth->rows==0)
    {
        print("WARN: not creating project; no name\n") if length($name) == 0;
        print("WARN: not creating project '$name'; missing service") if length($service_id) == 0;
        return undef unless length($name) > 0 and length($service_id) > 0;

        my $moc_project_id = $self->get_moc_project_id($name);
        my $ins = $self->SUPER::prepare("insert into project (project_uuid, moc_project_id, service_id) values (?,?,?)");
        $ins->execute($uuid, $moc_project_id, $service_id);
        # die $sth->errstr."\n" if(length($sth->errstr)>0);

        $sth->execute($uuid);
        # die $sth->errstr."\n" if(length($sth->errstr)>0);
    }
    return $sth->fetchrow_arrayref()->[0];
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
        $get_item_id_sth=$self->SUPER::prepare("select item_id from item where project_id=? and item_type_id=? and item_uid=?");
        $get_item_id_sth->execute($project_id,$item_type_id,$item_uid);
        if($get_item_id_sth->rows==0)
            {
            # print "insert into item (domain_id,project_id,item_type_id,item_uid,item_name) values ($region_id,$project_id,$item_type_id,$item_uid,$item_name) \n";
            my $ins=$self->SUPER::prepare("insert into item (project_id,item_type_id,item_uid,item_name) values (?,?,?,?,?)");
            if(!defined($item_name)) { $item_name=''; }
            $ins->execute($project_id,$item_type_id,$item_uid,$item_name);
            }
        $get_item_id_sth->execute($project_id,$item_type_id,$item_uid);
        }
    else
        {
        # print "select item_id from item where domain_id=$region_id and project_id=$project_id and item_uid=$item_uid \n";
        $get_item_id_sth=$self->SUPER::prepare("select item_id from item where project_id=? and item_uid=?");
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

    my $get_item_type_id_sth=$self->SUPER::prepare("select item_type_id from item_type where item_definition=?");
    $get_item_type_id_sth->execute($item);
    if($get_item_type_id_sth->rows==0)
    {
        # Note: These should probably be statically prepared in the same way as roles ~TS

        # my $ins=$self->SUPER::prepare("insert into item_type (item_definition,item_desc) values (?,null)");
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
        $get_item_ts_id_sth=$self->SUPER::prepare("select * from item_ts where project_id=? and item_type_id=? and item_id=? and start_ts=?");
        $get_item_ts_id_sth->execute($project_id,$item_type_id,$item_id,$start_ts);
        if( $get_item_ts_id_sth->rows==0 )
            {
            my $ins=$self->SUPER::prepare("insert into item_ts (project_id,item_type_id,item_id,start_ts,end_ts,state,item_size) values (?,?,?,?,?,?,?,?)");
            $ins->execute($project_id,$item_type_id,$item_id,$start_ts,$end_ts,$state,$size);
            }
        }
    else
        {
        # this will be a gocha - but in this case we don't have the information to perform the insert (we don't know the item_type)
        # However, in the mapping of items to items at a given timestam, we need to look up both records in the item_ts table.
        $get_item_ts_id_sth=$self->SUPER::prepare("select * from item_ts where project_id=? and item_id=? and start_ts=?");
        $get_item_ts_id_sth->execute($project_id,$item_id,$start_ts);
        }        
    return $item_ts;
}

package Reporting::DB::st;
use vars qw/ @ISA /;
@ISA = qw/ DBI::st /;

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
