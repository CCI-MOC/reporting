
package Reporting::Services::CSV;

sub get_metrics_data
{
    my ($proj, $fname, $start_ts, $end_ts) = @_;

    my $data_set=open_csv($fname);
    # timestamp,resource_id,resource_type,cpu_usage_rate_average,capture_interval,capture_interval_name 
    while(my $line=$data_set->fetch())
    {
        my $ts  = $line->{'timestamp'};

        my $t   = str2time($ts);
        my $st  = str2time($start_ts);
        my $et  = str2time($end_ts);
        my $i2p = build_instace_to_proj_index($proj);

        if($st <= $t and $t <= $et)
        {

            if($line->{'capture_interval_name'} eq 'Hourly' and $line->{'resource_type'} eq 'VmOrTemplate')
            {
                # print "$ts --> $proj_id  [ $msg->{instance_id} ]\n";
                my $uuid=$line->{resource_id};

                my $proj_id = $i2p->{$uuid};  # becuase there is no project id in the metrics table
                $proj->{$proj_id}->{'VM'}->{$uuid}->{event_cnt}=1;

                #add in the instance id to the hash right before the $ts
                if($line->{'cpu_usage_rage_average'}>0) 
                {
                    $proj->{$proj_id}->{'VM'}->{$uuid}->{events}->{$ts}->{_id}=1;
                }
                #print "$msg->{instance_id}, $msg->{cpu}, $msg->{mem} \n";
                #print "-------\n"
            }
        }
    }
    return $proj;
}

sub get_mq_data
{
    my $proj=shift;
    my $fname=shift;
    my $start_ts=shift;
    my $end_ts=shift;
    
    my $data_set=open_csv($fname);
    # id,ems_id,event_type,timestamp,full_data
    while(my $line=$data_set->fetch())
    {
        my $ts = $line->{'timestamp'};

        my $t=str2time($ts);
        my $st=str2time($start_ts);
        my $et=str2time($end_ts);

        if($st <= $t and $t <= $et)
        {
            
            if($line->{'event_type'} =~ /compute.instance.exists/)
            {
                my $proj_id = $line->{'ems_id'};
                my $msg=process_vm_msg($line->{'full_data'});
                # print "$ts --> $proj_id  [ $msg->{instance_id} ]\n";
                my $uuid=$msg->{instance_id};
                $proj->{$proj_id}->{'VM'}->{$uuid}->{event_cnt}=1;
            

                #add in the instance id to the hash right before the $ts
                $proj->{$proj_id}->{'VM'}->{$uuid}->{events}->{$ts}->{instance_id}=$msg->{instance_id};
                $proj->{$proj_id}->{'VM'}->{$uuid}->{events}->{$ts}->{cpu}=$msg->{cpu};
                $proj->{$proj_id}->{'VM'}->{$uuid}->{events}->{$ts}->{mem}=$msg->{mem};
                $proj->{$proj_id}->{'VM'}->{$uuid}->{events}->{$ts}->{root_gb}=$msg->{root_gb};
                $proj->{$proj_id}->{'VM'}->{$uuid}->{events}->{$ts}->{state}=$msg->{state};
                #print "$msg->{instance_id}, $msg->{cpu}, $msg->{mem} \n";
                #print "-------\n"
            }
            if($line->{'event_type'} =~ /volume/)
            {
                my $proj_id = $line->{'ems_id'};
                my $ts = $line->{'timestamp'};
                #print "found a $line->{'event_type'} \n";
            }
        }
    }
    return $proj;
}
