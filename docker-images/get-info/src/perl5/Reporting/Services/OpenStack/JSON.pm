
package Reporting::Services::OpenStack::JSON;


my $DEBUG = $ENV{DEBUG};

sub process_oslo_json
{
    my $json_string = shift;
    $json_string    = $& if ($json_string =~ /^'(.*)'$/);
    
    my $eq          =  from_json($json_string);
    if ($DEBUG)
    {
        print Dumper($eq);
        print "_context_domain = /{$eq->{_context_domain}}\n";
    }

    #find the project_id
    my $project_id  =  $eq->{_context_project_id}
                    || $eq->{payload}->{tenant_id}
                    || $eq->{payload}->{project_id};

    my $user_id     =  $eq->{_context_user_id}
                    || $eq->{payload}->{user_id};

    return {
        timestamp   => $eq->{timestamp},
        project_id  => $project_id,
        instance_id => $eq->{payload}->{instance_id},
        user_id     => $user_id,
        cpu         => $eq->{payload}->{vcpus},
        mem         => $eq->{payload}->{memory_mb},
        root_gb     => $eq->{payload}->{root_gb},
        state       => $eq->{payload}->{state},
        flavor      => $eq->{payload}->{instance_type},
    };
}

sub process_vm_msg
{
    my $msg     =  shift;
    $msg        =~ /\-\-\-/;
    $msg        =~ $';

    my $yaml    =  YAML::XS::Load($msg);
    print Dumper{$yaml} if ($DEBUG);

    if (exists $yaml->{':content'} and exists $yaml->{':content'}->{'oslo.message'})
    {
        return process_oslo_json($yaml->{':content'}->{'oslo.message'});
    }
    elsif (exists $yaml->{':content'} and exists $yaml->{':content'}->{'payload'})
    {
        return {
            timestamp   => $yaml->{timestamp},
            project_id  => $yaml->{payload}->{project_id},
            project_id  => $yaml->{':content'}->{payload}->{tenant_id},
            instance_id => $yaml->{':content'}->{payload}->{instance_id},
            user_id     => $yaml->{':content'}->{payload}->{user_id},
            cpu         => $yaml->{':content'}->{payload}->{vcpus},
            mem         => $yaml->{':content'}->{payload}->{memory_mb},
            root_gb     => $yaml->{':content'}->{payload}->{root_gb},
            state       => $yaml->{':content'}->{payload}->{state},
        }
    }
    die "VM Message could not be processed:\n$msg\n";
}
