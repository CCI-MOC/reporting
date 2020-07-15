
# Pre: Assumes that db calls die upon failure

package Reporting::Services::OpenStack::Dump;

use strict;
use POSIX;

use base qw/ Exporter /;
our @EXPORT = qw/ dump_to_db /;


my $DEBUG = $ENV{DEBUG};


sub store_users
{
    print("Dump::store_users\n") if $DEBUG;
	my ($users, $db, $service_id, $timestamp) = @_;

    foreach my $u (keys %{$users})
    {
        my $poc_id = $db->get_poc_id($u,$users->{$u}->{name},$users->{$u}->{email});
        if(!defined($poc_id) and $DEBUG)
        {
            print "Warning: unable to add user ID#:$u ($users->{$u}->{name} <$users->{$u}->{email}>)\n";
        }
    }
}

sub store_projects
{
    print("Dump::store_projects\n") if $DEBUG;
	my ($projects, $db, $service_id, $timestamp) = @_;

	foreach my $p (keys %{$projects})
    {
        my $project_id = $db->get_project_id($p, $projects->{$p}->{name}, $service_id);
        print "project_id: $project_id\n";
        if ($project_id)
        {
            my $get_item_id_sth=$db->prepare("select item_id from item where project_id=? and item_type_id=? and item_uid=?");
            foreach my $v (keys %{$projects->{$p}->{'Vol'}})
            {
                print "    item(Vol): $v\n";
                my $item_type_id    = $db->get_item_type_id("Vol");
                my $item_id         = $db->get_item_id($project_id,$v,$projects->{$p}->{'Vol'}->{$v}->{name},$item_type_id);
                my $item_ts_id      = $db->get_item_ts_id($project_id,$item_type_id,$item_id, $timestamp,undef,'  ',$projects->{$p}->{'Vol'}->{$v}->{size});
                print "    item_type_id: $item_type_id\n"; 
            }
            foreach my $i (keys %{$projects->{$p}->{'VM'}})
            {
                print "    item(VM): $i\n";
                foreach my $e (keys %{$projects->{$p}->{'VM'}->{$i}->{'events'}})
                {
                    my $evt=$projects->{$p}->{'VM'}->{$i}->{'events'}->{$e};
                    my $item_desc='VM('.$evt->{'vcpus'}.','.$evt->{'mem'}.','.$evt->{'disk_gb'}.')';

                    my $item_type_id    = $db->get_item_type_id($item_desc);
                    my $item_id         = $db->get_item_id($project_id,$item_type_id,$i,$projects->{$p}->{'VM'}->{$i}->{name});
                    my $item_ts_id      = $db->get_item_ts_id($project_id,$item_type_id,$item_id,$e,$evt->{'end_ts'},$evt->{'state'},undef);
                    #add the item_ts if needed
                    #$get_item_ts_id_sth->execute($region_id,$project_id,$item_type_id,$item_id,$e);
                    #if($get_item_ts_id_sth->rows==0)
                    #    {
                    #    my $ins=$db->prepare("insert into item_ts (domain_id,project_id,item_type_id,item_id,start_ts,end_ts,state) values (?,?,?,?,?,?,?)");
                    #    $ins->execute($region_id,$project_id,$item_type_id,$item_id,$e,$evt->{'end_ts'},$evt->{'state'});
                    #    }
                }
            }
        }
    }
}

sub store_user_moc_project_mappings
{
    print("Dump::store_user_moc_project_mappings\n") if $DEBUG;
    my ($mapping, $db, $service_id, $timestamp) = @_;

    return; 
    my $smt = $db->prepare("select project_id from poc2moc_project");
    my $ins = $db->prepare("insert into poc2moc_project (poc_id, moc_project_id, poc_poc_id, role_id, username) values (?,?,?,?,?)");
    foreach my $user_id (keys %$mapping)
    {
        foreach my $project_id (keys %{$mapping->{$user_id}})
        {
            # TODO: $ins select a poc_poc_id 
            # Note: Is this field even necessary? ~TS
            # TODO: $ins select a role
            # Note: Role data not yet being loaded from OpenShift ~TS
        }
    }
}

sub store_user_project_mappings
{
    print("Dump::store_item_mappings\n") if $DEBUG;
    my ($mapping, $db, $service_id, $timestamp) = @_;

    my $get_project_id=$db->prepare("select project_id from project where project_uid=?");
    my $get_project2poc=$db->prepare("select project_id,poc_id from poc2project where project_id=? and poc_id=?");
    foreach my $user (keys %$mapping)
    {
        my $poc_id=$db->get_poc_id($user);
        #print "POC_ID: $poc_id\n";
        if( !defined($poc_id) )
        {
            print "WARNING: cannot find userid from uuid: $user --> $poc_id\n";
        }
        else
        {
            foreach my $proj (keys %{$mapping->{$user}})
            {
                $get_project_id->execute($proj);
                if($get_project_id->rows==0)
                {
                    print "WARNING cannot find project id from uuid:$proj\n";
                }
                else
                {
                    my $project_id=$get_project_id->fetchrow_arrayref()->[0];
                    $get_project2poc->execute($project_id,$poc_id);
                    if($get_project2poc->rows==0)
                    {
                        my $ins=$db->prepare("insert into project2poc (project_id,poc_id) values (?,?)");
                        $ins->execute($project_id,$poc_id);
                        # print "ERROR: $ins->errstr\n" if(length($ins->errstr)>0);
                    }
                }
            }
        } 
    }
}

sub store_floating_ips
{
    print("Dump::store_floating_ips\n") if $DEBUG;
    my ($floating_ips, $db, $service_id, $timestamp) = @_;

    my $get_floating_ip_type_id=$db->prepare("select item_type_id from item_type where item_definition='floating_ip'");
    $get_floating_ip_type_id->execute();
    # die $get_floating_ip_type_id->errstr . "\n" if length($get_floating_ip_type_id->errstr) > 0;
    if($get_floating_ip_type_id->rows==0)
    {
        my $ins=$db->prepare("insert into item_type (item_definition, item_desc) values ('floating_ip','floating_ip')");
        $ins->execute();
        # die $ins->errstr . "\n" if length($ins->errstr) > 0;
        
        $get_floating_ip_type_id->execute();
        # die $get_floating_ip_type_id->errstr . "\n" if length($get_floating_ip_type_id->errstr) > 0;
    }
    my $floating_ip_type_id=$get_floating_ip_type_id->fetchrow_arrayref()->[0];

    my $get_floating_ip_id=$db->prepare("select item_id from item where project_id=(select project_id from project where project_uuid=?) and item_type_id=? and item_uuid=?"); 
    foreach my $fip (keys %$floating_ips)
    {
        $get_floating_ip_id->execute($floating_ips->{$fip}->{'project_id'},$floating_ip_type_id,$fip);
        if($get_floating_ip_id->rows==0)
        {
            #look up project id from domain/project_id
            my $get_project_id->execute($floating_ips->{$fip}->{'project_id'});
            if($get_project_id->rows==0)
            {
                #add proejct id maybe flag as an WARNING for now.
                print "WARNING: unable to find project id from '$floating_ips->{$fip}->{project_id} - $floating_ips->{$fip}->{status}, $floating_ips->{$fip}->{floating_ip_address} -> $floating_ips->{$fip}->{fixed_ip_address} $floating_ips->{$fip}->{port_id}\n";
            }
            else
            {
                my $project_id=$get_project_id->fetchrow_arrayref()->[0]; 
                my $state=$floating_ips->{$fip}->{'project_id'};
                my $name=$floating_ips->{$fip}->{floating_ip_address}.' -> '.$floating_ips->{$fip}->{fixed_ip_address};
                my $ins=$db->prepare("insert into item (domain_id,project_id,item_type_id,item_uid,item_name) values (?,?,?,?,?)");
                #print "domain_id=$region_id, proejct_id=$project_id, fip_type_id=$floating_ip_type_id,  itme_uuid=$fip, item_name=$name\n";
                $ins->execute($project_id,$floating_ip_type_id,$fip,$name);
            }
        }
        else
        {
            #print "INFO: '$os_data->{floating_ips}->{$fip}->{project_id} - $os_data->{floating_ips}->{$fip}->{status}, $os_data->{floating_ips}->{$fip}->{floating_ip_address} -> $os_data->{floating_ips}->{$fip}->{fixed_ip_address} $os_data->{floating_ips}->{$fip}->{port_id}\n";
        }
        $get_floating_ip_id->execute($floating_ips->{$fip}->{'project_id'},$floating_ip_type_id,$fip);
        # die $get_floating_ip_type_id->errstr . "\n" if(length($get_floating_ip_type_id->errstr)>0);
    }
}

sub store_item_mappings
{
    print("Dump::store_item_mappings\n") if $DEBUG;
    my ($items, $db, $service_id, $timestamp) = @_;

    # TODO: Broken
    die "Broken";
    my $item_uuid = undef;
    my $project_id = undef;
    foreach my $i2i (keys %$items)
    {
        my $item_id1 = $db->get_item_id($project_id, $item_uuid);
        my $item_id2 = $db->get_item_id($project_id, $item_uuid);
        my $start_ts1 = undef;
        my $start_ts2 = undef;
        my $end_ts1 = $db->get_end_time($project_id, $item_id1, $start_ts1 );
        my $end_ts2 = $db->get_end_time($project_id, $item_id2, $start_ts2 );
        my $ins=$db->prepare("insert into item_ts2item_ts (domain_id,project_id,item_id1,start_ts1,end_ts1,item_id2,start_ts2,end_ts2) values (?,?,?,?,?,?,?,?)");
        #print "domain_id=$region_id, proejct_id=$project_id, fip_type_id=$floating_ip_type_id,  itme_uuid=$fip, item_name=$name\n";
        $ins->execute($project_id,$item_id1,$start_ts1,$end_ts1,$item_id2,$start_ts2,$end_ts2);
    }
}

sub dump_to_db
{
    print("Dump::dump_to_db\n") if $DEBUG;
    my $debug_prefix = $DEBUG ? "--" : "";
	my ($os_info, $db, $service_id, $timestamp) = @_;
    #my $get_poc_sth=$db->prepare("select poc_id from poc where domain_id=? and user_uid=?");

    print("$debug_prefix timestamp = $timestamp\n");

    my %steps = (
        users =>                sub { store_users(@_); },
        # projects =>             sub { store_projects(@_); },
        users2projects =>       sub { store_user_project_mappings(@_); },
        users2moc_projects =>   sub { store_user_moc_project_mappings(@_); },
        floating_ips =>         sub { store_floating_ips(@_); }#,
        # Note: moved item_ts mapping into a proper function despite being commented out ~TS
        # item_ts2item_ts =>  sub { store_item_ts_mappings(@_); }
    );

    while (my ($source, $step) = (each %steps))
    {
        if ($os_info->{$source})
        {
            $step->($os_info->{$source}, $db, $service_id, $timestamp);
        }
        elsif ($DEBUG)
        {
            print("-- WARN: Data Source '$source' not loaded\n");
        }
    }

}

1;
__END__
