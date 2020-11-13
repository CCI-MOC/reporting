
# Pre: Assumes that db calls die upon failure

package Reporting::DB;

use strict;
use POSIX;
use v5.30;

use Data::Dumper;


my $DEBUG = $ENV{DEBUG};

sub _store_users
{
    print("Dump::_store_users\n") if $DEBUG;
    my ($self, $obj, $service_id) = @_;

    while ( my ($os_uuid, $u) = (each %$obj) )
    {
        print("UUID $os_uuid: ", Dumper{%$u}) if $DEBUG;
        my $poc_id = $self->{poc}->lookup(
            service_ids => { $service_id => $os_uuid },
            email => $u->{email},
        );
        unless ($poc_id)
        {
            $poc_id = $self->{poc}->create(
                service_ids => { $service_id => $os_uuid }, 
                email => $u->{email},
                username => $u->{name}
            );
        }
        die "Err: Unable to add user: \"$os_uuid\" ($obj->{$u}->{name} <$obj->{$u}->{email}>)\n" unless $poc_id;

        $self->{useruuid2poc} = {} unless ref $self->{useruuid2poc};
        $self->{useruuid2poc}->{$os_uuid} = $poc_id;
    }
}

sub _store_projects
{
    print("Dump::_store_projects\n") if $DEBUG;
    my ($self, $obj, $service_id) = @_;

    my $get_item_id_sth = $self->prepare("select item_id from item where project_id=? and item_type_id=? and item_uid=?");
	while ( my ($uuid, $project) = (each %$obj))
    {
        my $project_id = $self->{project}->lookup(project_uuid => $uuid);
        $project_id = $self->{project}->create(
                project_uuid    => $uuid,
                service_id      => $service_id,
                project_name    => $project->{name}, 
        ) unless $project_id;

        foreach my $v (keys %{$project->{'Vol'}})
        {
            print "    item(Vol): $v\n";
            my $item_type_id    = $self->get_item_type_id("Vol");
            my $item_id         = $self->get_item_id($project_id,$v,$project->{'Vol'}->{$v}->{name},$item_type_id);
            my $item_ts_id      = $self->get_item_ts_id($project_id,$item_type_id,$item_id, $self->{timestamp},undef,'  ',$project->{'Vol'}->{$v}->{size});
            print "    item_type_id: $item_type_id\n"; 
        }
        foreach my $i (keys %{$project->{'VM'}})
        {
            print "    item(VM): $i\n";
            foreach my $e (keys %{$project->{'VM'}->{$i}->{'events'}})
            {
                my $evt             = $project->{'VM'}->{$i}->{'events'}->{$e};
                my $item_desc       = 'VM('.$evt->{'vcpus'}.','.$evt->{'mem'}.','.$evt->{'disk_gb'}.')';
                my $item_type_id    = $self->get_item_type_id($item_desc);
                my $item_id         = $self->get_item_id($project_id,$item_type_id,$i,$project->{'VM'}->{$i}->{name});
                my $item_ts_id      = $self->get_item_ts_id($project_id,$item_type_id,$item_id,$e,$evt->{'end_ts'},$evt->{'state'},undef);
                #add the item_ts if needed
                #$get_item_ts_id_sth->execute($region_id,$project_id,$item_type_id,$item_id,$e);
                #if($get_item_ts_id_sth->rows==0)
                #    {
                #    my $ins=$self->prepare("insert into item_ts (domain_id,project_id,item_type_id,item_id,start_ts,end_ts,state) values (?,?,?,?,?,?,?)");
                #    $ins->execute($region_id,$project_id,$item_type_id,$item_id,$e,$evt->{'end_ts'},$evt->{'state'});
                #    }
            }
        }
    }
}

sub _store_user_moc_project_mappings
{
    print("Dump::_store_user_moc_project_mappings\n") if $DEBUG;
    my ($self, $obj, $service_id) = @_;

    return; 
    my $smt = $self->prepare("select project_id from poc2moc_project");
    my $ins = $self->prepare("insert into poc2moc_project (poc_id, moc_project_id, poc_poc_id, role_id, username) values (?,?,?,?,?)");
    foreach my $user_id (keys %{$obj->{poc2moc_project}})
    {
        foreach my $project_id (keys %{$obj->{poc2moc_project}->{$user_id}})
        {
            # TODO: $ins select a poc_poc_id 
            # Note: Is this field even necessary? ~TS
            # TODO: $ins select a role
            # Note: Role data not yet being loaded from OpenShift ~TS
        }
    }
}

sub _store_user_project_mappings
{
    print("Dump::_store_user_project_mappings\n") if $DEBUG;
    my ($self, $obj, $service_id) = @_;

    my $get_project2poc = $self->prepare("select project_id, poc_id from poc2project where project_id=? and poc_id=?");
    my $ins             = $self->prepare("insert into poc2project (project_id, poc_id, role_id, username, service_uuid) values (?, ?, ?, ?, ?)");
    while (my ($user_uuid, $user) = (each %{$obj->{users}}))
    {
        my $poc_id = $obj->{useruuid2poc}->{$user_uuid} if $obj->{useruuid2poc}->{$user_uuid};
        $poc_id = $self->{poc}->lookup($user_uuid) unless (defined($poc_id));
        die "ERROR: Missing poc_id from user_uuid: $user_uuid\n" unless defined $poc_id;
        print "-- $user_uuid => $poc_id\n" if $DEBUG;

        foreach my $mapping (@{$obj->{users2projects}->{$user_uuid}})
        {
            my $project_id = $self->{project}->lookup($mapping->{project_uuid});
            die "Missing project with id in user=>project mapping '$user_uuid => $mapping->{project_uuid}'\n" unless $project_id;

            $get_project2poc->execute($project_id, $poc_id);
            if($get_project2poc->rows==0)
            {
                my $role_name = $mapping->{role};
                $role_name = 'member' unless $role_name;
                
                my $role_id = $self->{roles}->lookup($role_name, 'project');
                die "ERROR: Missing role_id\n" unless defined $role_id;

                $ins->execute($project_id, $poc_id, $role_id, $user->{name}, $user_uuid);
                # print "ERROR: $ins->errstr\n" if(length($ins->errstr)>0);
            }
        }
    } 
}

sub _store_floating_ips
{
    print("Dump::_store_floating_ips\n") if $DEBUG;
    my ($self, $obj, $service_id) = @_;

    while ( my ($fip_id, $fip) = (each %{$obj->{floating_ips}}) )
    {
        my $project_id = $self->{project}->lookup(uuid => $fip->{project_uuid});
        die "Could not load project info for '$fip->{project_uuid}'\n" unless $project_id;
        my $fip_id = $self->get_floating_ip_id($project_id, $fip->{floating_ip_address}, $fip_id);
        die "Could not load floating_ip for '$fip->{floating_ip_address}'\n" unless $fip_id;
    }
}

sub _store_item_mappings
{
    print("Dump::_store_item_mappings\n") if $DEBUG;
    my ($self, $obj, $service_id) = @_;

    # TODO: Broken
    # die "Broken";
    my $item_uuid = undef;
    my $project_id = undef;
    foreach my $i2i (keys %$obj)
    {
        my $item_id1 = $self->get_item_id($project_id, $item_uuid);
        my $item_id2 = $self->get_item_id($project_id, $item_uuid);
        my $start_ts1 = undef;
        my $start_ts2 = undef;
        my $end_ts1 = $self->get_end_time($project_id, $item_id1, $start_ts1 );
        my $end_ts2 = $self->get_end_time($project_id, $item_id2, $start_ts2 );
        my $ins=$self->prepare("insert into item_ts2item_ts (domain_id,project_id,item_id1,start_ts1,end_ts1,item_id2,start_ts2,end_ts2) values (?,?,?,?,?,?,?,?)");
        #print "domain_id=$region_id, proejct_id=$project_id, fip_type_id=$fip_type_id,  itme_uuid=$fip_id, item_name=$name\n";
        $ins->execute($project_id,$item_id1,$start_ts1,$end_ts1,$item_id2,$start_ts2,$end_ts2);
    }
}

sub dump
{
    print("DB::dump\n") if $DEBUG;
    my $debug_prefix = $DEBUG ? "-- " : "";
	my ($self, $store, $service_id) = @_;
    #my $get_poc_sth=$self->prepare("select poc_id from poc where domain_id=? and user_uid=?");

    print("${debug_prefix}timestamp = $self->{timestamp}\n");

    # _store_users($os_info, $self, $service_id, $self->{timestamp});
    # _store_projects($os_info, $self, $service_id, $self->{timestamp});
    # _store_user_project_mappings($os_info, $self, $service_id, $self->{timestamp});
    # _store_user_moc_project_mappings($os_info, $self, $service_id, $self->{timestamp});
    # _store_floating_ips($os_info, $self, $service_id, $self->{timestamp});

    # Note: moved item_ts mapping into a proper function despite being commented out ~TS
    # store_item_ts_mappings(@_);


    my @steps = (
        [ 'users',              sub { return $self->_store_users(@_); } ],
        [ 'projects',           sub { return $self->_store_projects(@_); } ],
        [ 'users2projects',     sub { return $self->_store_user_project_mappings(@_); } ],
        [ 'users2moc_projects', sub { return $self->_store_user_moc_project_mappings(@_); } ],
        [ 'floating_ips',       sub { return $self->_store_floating_ips(@_); } ],
        [ 'items',              sub { return $self->_store_item_mappings(@_); } ]
        # Note: moved item_ts mapping into a proper function despite being commented out ~TS
        # [ 'item_ts2item_ts',  sub { store_item_ts_mappings(@_); } ]
    );

    foreach my $tupl (@steps)
    {
        my ($source, $step) = @$tupl;
        if ($store->{$source})
        {
            $step->($store->{$source}, $service_id);
        }
        # elsif ($DEBUG)
        # {
        #     print("-- WARN: Data Source '$source' not loaded\n");
        # }
    }

}

1;
__END__
