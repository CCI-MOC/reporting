
package Reporting::GetInfo;

use YAML::XS;
use Parse::CSV;
use Data::Dumper;
use Time::Local;
use Date::Parse;

use Reporting::Creds;
use Reporting::CSV;
use Reporting::DB;

use POSIX;
use strict;

my $DEBUG = 0;

sub get_region_id
{
    my ($conn, $region) = @_;

    my $sth = $conn->prepare("select domain_id from domain where domain_name=?");
    $sth->execute($region);
    if($sth->rows==0)
    {
        my $sth2=$conn->prepare("insert into domain (domain_name,domain_uid) values (?,null)");
        $sth2->execute($region);
    }
    $sth->execute($region);
    if(length($sth->errstr)>0)
    {
        print $sth->errstr."\n";
        exit();
    }
    my $region_id=$sth->fetchrow_arrayref()->[0];

    return $region_id;
}

sub get_item_type_id
{
    my ($conn, $item_desc) = @_;

    my $get_item_type_id_sth=$conn->prepare("select item_type_id from item_type where item_definition=?");
    $get_item_type_id_sth->execute($item_desc);
    if($get_item_type_id_sth->rows==0)
    {
        my $ins=$conn->prepare("insert into item_type (item_definition,item_desc) values (?,null)");
        $ins->execute($item_desc);
        $get_item_type_id_sth->execute($item_desc);
    }
    $get_item_type_id_sth->execute($item_desc);

    if(length($get_item_type_id_sth->errstr)>0)
    {
        print $get_item_type_id_sth->errstr."\n";
        exit();
    }
    my $item_type_id=$get_item_type_id_sth->fetchrow_arrayref()->[0];

    return $item_type_id;
}

sub get_poc_id
{
    my $conn=shift;      # req
    my $region_id=shift; # req
    my $uid=shift;       # opt - required to add a user
    my $name=shift;      # opt - required to add a user
    my $email=shift;     # opt - required to add a user

    my $poc_id=undef;

    my $get_poc_sth=$conn->prepare("select poc_id from poc where domain_id=? and user_uid=?");
    $get_poc_sth->execute($region_id,$uid);
    if($get_poc_sth->rows==0 and length($uid)>0 and length($name)>0)
        {
        my $ins=$conn->prepare("insert into poc (domain_id,user_uid, username, email) values (?,?,?,?)");
        $ins->execute($region_id,$uid,$name,$email);
        if(length($ins->errstr)>0)
            {
            print $ins->errstr."\n";
            exit();
            }
        $get_poc_sth->execute($region_id,$uid);
        }
    $poc_id=$get_poc_sth->fetchrow_arrayref()->[0];
    return $poc_id;
    }

sub get_project_id
    {
    my $conn=shift;
    my $region_id=shift;
    my $uid=shift;
    my $name=shift;
    my $project_id;

    my $sth=$conn->prepare("select project_id from project where domain_id=? and project_uid=?");
    $sth->execute($region_id,$uid);
    if($sth->rows==0 and length($name)>0)
        {
        my $ins=$conn->prepare("insert into project (domain_id, project_uid, project_name) values (?,?,?)");
        $ins->execute($region_id,$uid,$name);
        
        if(length($sth->errstr)>0)
            {
            print $sth->errstr."\n";
            exit();
            }
        $sth->execute($region_id,$uid);
        if(length($sth->errstr)>0) 
            {
            print $sth->errstr."\n";
            exit();
            }
        }
    $project_id=$sth->fetchrow_arrayref()->[0];
    return $project_id;
    }

sub get_item_id
    {
    my $conn=shift;
    my $region_id=shift;
    my $project_id=shift;
    my $item_uid=shift;
    my $item_name=shift;
    my $item_type_id=shift;

    my $item_id=undef;
    my $get_item_id_sth=undef;

    if(defined $item_type_id )
        {
        print "select item_id from item where domain_id=$region_id and project_id=$project_id and item_type_id=$item_type_id and item_uid=$item_uid \n";
        $get_item_id_sth=$conn->prepare("select item_id from item where domain_id=? and project_id=? and item_type_id=? and item_uid=?");
        $get_item_id_sth->execute($region_id,$project_id,$item_type_id,$item_uid);
        if($get_item_id_sth->rows==0)
            {
            print "insert into item (domain_id,project_id,item_type_id,item_uid,item_name) values ($region_id,$project_id,$item_type_id,$item_uid,$item_name) \n";
            my $ins=$conn->prepare("insert into item (domain_id,project_id,item_type_id,item_uid,item_name) values (?,?,?,?,?)");
            if(!defined($item_name)) { $item_name=''; }
            $ins->execute($region_id,$project_id,$item_type_id,$item_uid,$item_name);
            }
        $get_item_id_sth->execute($region_id,$project_id,$item_type_id,$item_uid);
        }
    else
        {
        print "select item_id from item where domain_id=$region_id and project_id=$project_id and item_uid=$item_uid \n";
        $get_item_id_sth=$conn->prepare("select item_id from item where domain_id=? and project_id=? and item_uid=?");
        $get_item_id_sth->execute($region_id,$project_id,$item_uid);
        }

    if(length($get_item_id_sth->errstr)>0)
        {
        print $get_item_id_sth->errstr."\n";
        exit();
        }
    my $row_array_ref=$get_item_id_sth->fetchrow_arrayref();
    my $item_id=undef;
    if(defined($row_array_ref))
        {
        $item_id=$row_array_ref->[0];
        }
    return $item_id;
    }

sub get_item_ts_id
    {
    my $conn=shift;
    my $region_id=shift;
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
        $get_item_ts_id_sth=$conn->prepare("select * from item_ts where domain_id=? and project_id=? and item_type_id=? and item_id=? and start_ts=?");
        $get_item_ts_id_sth->execute($region_id,$project_id,$item_type_id,$item_id,$start_ts);
        if( $get_item_ts_id_sth->rows==0 )
            {
            my $ins=$conn->prepare("insert into item_ts (domain_id,project_id,item_type_id,item_id,start_ts,end_ts,state,item_size) values (?,?,?,?,?,?,?,?)");
            $ins->execute($region_id,$project_id,$item_type_id,$item_id,$start_ts,$end_ts,$state,$size);
            }
        }
    else
        {
        # this will be a gocha - but in this case we don't have the information to perform the insert (we don't know the item_type)
        # However, in the mapping of items to items at a given timestam, we need to look up both records in the item_ts table.
        $get_item_ts_id_sth=$conn->prepare("select * from item_ts where domain_id=? and project_id=? and item_id=? and start_ts=?");
        $get_item_ts_id_sth->execute($region_id,$project_id,$item_id,$start_ts);
        }        
    return $item_ts;
    }

sub store_users
    {
    my $db=shift;
    my $users=shift;
    my $region=shift;
    my $region_id=shift;
    my $timestamp=shift;

    foreach my $u (keys %{$users})
        {
        my $poc_id=get_poc_id($db,$region_id,$u,$users->{$u}->{name},$users->{$u}->{email});
        if(!defined($poc_id)) 
            {
            print "Warning: unable to add user $u, $users->{$u}->{name}, $users->{$u}->{email} to region: $region \n";
            }
        }        
    }

sub main
{
    my $os_info = {};
    my $creds   = Reporting::Creds::load();
    my $db      = Reporting::DB->connect($creds->{'database'}) or die;

    if (!($creds->{database})) 
    {
        die "ERROR: Missing Database Credentials\n";
    }
    elsif (ref $creds->{database} != 'HASH')
    {
        die "ERROR: Credentials not an object:\n$creds->{database}\n";
    }

    if (!($creds->{services}))
    {
        die "ERROR: Missing Services\n";
    }
    elsif (ref $creds->{services} != 'ARRAY')
    {
        die "ERROR: Services not an array:\n$creds->{services}\n";
    }

    my @loaded_services;
    foreach my $service (@{$creds->{services}})
    {
        push @loaded_services, Reporting::Services::create($service);
    } 
    foreach my $service (@loaded_services)
    {
        $service->store($db);
    }

    $db->close();

    return 0;
}

1;
__END__;
