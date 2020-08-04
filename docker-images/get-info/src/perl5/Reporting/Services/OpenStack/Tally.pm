
package Reporting::Services::OpenStack::Tally;


# tally hours
# 1) find the first event
#    a) power-on -> $start_time = power-on timestamp, power_on=1
#    b) power-off - $start_time = $t1, $end_time = power-off timestamp; $amt= time diff ($start_time, $end_time); $start_time=undef, $end_time=undef; power_on=0;
#    c) exists status=active $start_time=$t1 power_on=1
#    d) exists status!=active power_on=0;
#
# 2) for each event
#    a) if power_on == 1
#       i) power_on -> issue a warning
#          $end_time=$last event; $amt=timediff($start_time,$end_time); $start_time=this->timestamp; $end_time=undef; power_on=0;
#       ii) power_off -> 
#          $end_time=$this event; $amt=timediff($start_time,$end_time); $start_time=undef; $end_time=undef; power_on=0;
#       iii) exists = active ->
#             $end_time=this event;
#       iv) exists != active -> issue a warning
#          $end_time=$last event; $amt=timediff($start_time,$end_time); $start_time=this->timestamp; $end_time=undef; power_on=0;
#    b) if power_on == 0
#       i) power_on -> 
#          $end_time=$this event; $amt=timediff($start_time,$end_time); $start_time=undef; $end_time=undef; power_on=0;
#       ii) power_off-> issue a warning
#          power_on=0;
#       iii) exists = active -> issue a warning (we missed the power on even - start from here)
#             $start_time=this event; power_on=1
#       iv) exists != active -> 
#           power_on=0;
#
#  This needs to be reworked
#  
#
sub tally_hours
{
    my ($events, $t1, $t2) = @_;

    my $start_time=undef;
    my $end_time=undef;
    my $power_on;
    my $total_time_on;
    my $time_on;
    
    my @ts = (sort keys %{$events});
    my $t = pop @ts;
    my $t2 = $events->{$t}->{end_ts};
    if($events->{$t}->{event_type} eq 'exists' and $events->{$t}->{status} eq 'active')
        {
        $start_time=$t1;
        $end_time=$t2;
        $power_on=1;
        }
    elsif($events->{$t}->{event_type} eq 'exists' and $events->{$t}->{status} ne 'active')
        {
        $start_time=undef;
        $end_time=undef;
        $power_on=0;
        }   
    elsif($events->{$t}->{event_type} eq 'power.on' and $events->{$t}->{status} eq 'active')
        {
        $start_time=$t; $end_time=undef;
        $power_on=1;
        }
    elsif($events->{$t}->{event_type} eq 'power.off' and $events->{$t}->{status} ne 'active')
        {
        $start_time=$t1;       $end_time=$t2;
        $time_on=timediff($start_time,$end_time);
        $total_time_on+=$time_on;
        # log this!!!
        $start_time=undef;     $end_time=undef;
        $power_on=0;
        }
    #print STDERR $events->{$t}->{event_type}." ".$events->{$t}->{status}."  ".$start_time."   ".$end_time."  ".$power_on."\n";
    foreach $t (@ts)
    {
        if($power_on==1)
        {
            if($events->{$t}->{event_type} eq 'exists' and $events->{$t}->{status} eq 'active')
            {
                $end_time=$t2;
                $power_on=1;
            }
            elsif($events->{$t}->{event_type} eq 'exists' and $events->{$t}->{status} ne 'active')
            {
                # warning (going from power_on state to inactive - missed the power off?
                $time_on=timediff($start_time,$end_time);
                $total_time_on=$time_on;
                # log this !!!
                $start_time=undef;
                $end_time=undef;
                $power_on=0;
            }
            elsif($events->{$t}->{event_type} eq 'power.on' and $events->{$t}->{status} eq 'active')
            {
                # warning powered on state and turning the power on again - missed the power off?
                $time_on=timediff($start_time,$end_time);
                $total_time_on=$time_on;
                # log this !!!
                $start_time=$t1;
                $power_on=1;
            }
            elsif($events->{$t}->{event_type} eq 'power.off' and $events->{$t}->{status} ne 'active')
            {
                $end_time=$t1;
                $time_on=timediff($start_time,$end_time);
                $total_time_on+=$time_on;
                # log this!!!
                $start_time=undef;     $end_time=undef;
                $power_on=0;
            }
        }
        elsif($power_on==0)
        {
            if($events->{$t}->{event_type} eq 'exists' and $events->{$t}->{status}='active')
            {
                # warn - missed the power on event
                $start_time=$t;
                $end_time=$t;
                $power_on=1;
            }
            elsif($events->{$t}->{event_type} eq 'exists' and $events->{$t}->{status}!='active')
            {
                $start_time=undef;
                $end_time=undef;
                $power_on=0;
            }
            elsif($events->{$t}->{event_type} eq 'power.on' and $events->{$t}->{status}='active')
            {
                $start_time=$t; $end_time=$t;
                $power_on=1;
            }
            elsif($events->{$t}->{event_type} eq 'power.off' and $events->{$t}->{status}!='active')
            {
                # warn 2 power is off, and a power off event occured.  missed the power on - nothing to tally.
                $start_time=undef;     $end_time=undef;
                $power_on=0;
            }
        }
        #print STDERR $events->{$t}->{event_type}." ".$events->{$t}->{status}."  ".$start_time."   ".$end_time."  ".$power_on."\n";
    }
    return $total_time_on
}

sub tally_hours2
{
    my ($events, $flav) = @_;

    my $t1=0;
    my $t2=0;

    my $start_time=undef;
    my $end_time=undef;
    my $power_on;
    my $total_time_on=0;
    my $total_amt=0.0;

    my @ts = (sort keys %{$events});
    my $t = pop @ts;
    $t1 = str2time($t) || 0;
    $t2 = str2time($events->{$t}->{end_ts}) || 0;

    if($t2 lt $t1) 
    {
        print STDERR "bad time range\n";
        return 0;  
    }

    if($events->{$t}->{event_type} =~ /exists/ and $events->{$t}->{state} eq 'active')
    {
        $start_time=$t1;
        $end_time=$t2;
        if($t2 - $t1 < 3600) { $end_time = $t1 + 3600; }
        $power_on=1;
    }
    elsif($events->{$t}->{event_type} =~ /exists/ and $events->{$t}->{state} ne 'active')
    {
        $start_time=undef;
        $end_time=undef;
        $power_on=0;
    }

    foreach my $t (@ts)
    {
        if($events->{$t}->{event_type} =~ /exists/ and $events->{$t}->{state} eq 'active')
        {
            if($end_time > $t2) 
            {
                # do nothing
                #
                #   (t1' t2')  (t1', t2'')     (endtime (t1'+1hour))
            }
            if($end_time < $t1)
            {
                #   (t1' t2')    (t1'+1hour)      (t1'', t2'')
                #   (t1'                t2')      (t1'', t2'')
                $total_time_on += ($end_time - $start_time);
                $start_time=$t1;
                $end_time=$t2;
                if($end_time-$start_time<3600) { $end_time=$start_time+3600; }
            }
            if($t1 <= $end_time && $end_time < $t2)
            {
                #   (t1'            $t2')
                #                  ($t1''        t2'')
                $end_time=$t2
            }
            $start_time=$t1;
            $end_time=$t2;
            if( $t2 - $t1 < 3600) { $end_time = $t1 + 3600; }
            $power_on=1;
        }
        elsif($events->{$t}->{event_type} =~ /exists/ and $events->{$t}->{state} ne 'active')
        {
            $total_time_on += ($end_time - $start_time);
            $start_time=undef;
            $end_time=undef;
            $power_on=0;
        }
    }
    $total_time_on += ($end_time - $start_time);
    return (ceil($total_time_on/3600.0), 0.0);
}

1;
__END__;
