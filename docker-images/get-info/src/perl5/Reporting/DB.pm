
package Reporting::DB;
=head2 Reporting::DB

Layer for managing Database requests from the driver program (GetInfo.pm, etc)

=over
=cut

use strict;
use POSIX;
use v5.32;

use Data::Dumper;
use DBI;

use Reporting::DB::Address;
use Reporting::DB::Dump;
use Reporting::DB::MOCProject;
use Reporting::DB::POC;
use Reporting::DB::Project;
use Reporting::DB::Role;

=item $Reporting::DB::DEBUG

Enables debugging for the module when truthy. Looks at the $DEBUG environment 
variable.

=cut
my $DEBUG = $ENV{DEBUG};

=item Reporting::DB->connect(\%params)

Opens a connection using the database configuration provided in \%params and
builds the queries used to access the datbase. Returns an obect with the 
following fields:

=begin perl

{
    address     => \$Reporting::DB::Address,
    moc_prject  => \$Reporting::DB::MOCProject,
    poc         => \$Reporting::DB::POC,
    project     => \$Reporting::DB::Project,
    role        => \$Reporting::DB::Role,
}

=end perl

=cut
sub connect 
{
    print("DB::connect\n") if $DEBUG > 1;

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
    my $self = bless {
        _conn => $conn,
    }, $cls;

    $self->{timestamp}   = $self->_get_timestamp();

    $self->{address}     = Reporting::DB::Address->new($conn);
    $self->{moc_project} = Reporting::DB::MOCProject->new($conn);
    $self->{poc}         = Reporting::DB::POC->new($conn, $self->{address});
    $self->{project}     = Reporting::DB::Project->new($conn, $self->{moc_project});
    $self->{role}        = Reporting::DB::Role->new($conn);

    return $self;
}

=item \$DB->prepare(...)

Alias to \$DBI::conn->prepare(...)

=cut
sub prepare
{
    my $self = shift;
    return $self->{_conn}->prepare(@_);
}

=item \$DB->_get_timestamp()

Returns a string with the current time as known by the database

=cut
sub _get_timestamp
{
    print("DB::db::_get_timestamp\n") if $DEBUG;
    my ($self) = @_;

    my $stmt = $self->{_conn}->prepare("select now()");
    $stmt->execute();
    return $stmt->fetchrow_arrayref()->[0];    
}

=item \$DB->get_service_id( $name )

Looks up the id for the given service name. If it is not present in the 
database, a new entry is created and the id of the new entry is returned.

=cut
# TODO: Create DB::Service.pm and move to `lookup`
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


=item \DB->get_floating_ip_id(...) 

TBD (To be documented)

=cut
sub get_floating_ip_id
{
    print("DB::get_item_id\n") if $DEBUG;
    my ($self, $project_uuid, $name, $uuid) = @_;
    
    my $type_id = $self->get_item_type_id('floating_ip');
    return $self->get_item_id($project_uuid, $uuid, $name, $type_id);
}

=item \DB->get_item_id(...) 

TBD (To be documented)

=cut
# TODO: Document function behavior
# Note: I inherited this funciton from Rob and have yet to reverse engineer it ~TS
# TODO: Create DB::ItemId.pm and move to `lookup`
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
            my $ins=$self->{_conn}->prepare("insert into item (project_id,item_type_id,item_uid,item_name) values (?,?,?,?)");
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
    my $row_array_ref=$get_item_id_sth->fetchrow_arrayref();

    # die $get_item_id_sth->errstr . "\n" if(length($get_item_id_sth->errstr)>0);
    if(defined($row_array_ref))
        {
        $item_id=$row_array_ref->[0];
        }
    return $item_id;
    }

=item \$DB->get_item_type_id(...)

TBD (To be documented)

=cut
# TODO: Document function behavior
# Note: I inherited this funciton from Rob and have yet to reverse engineer it ~TS
# TODO: Create DB::ItemId.pm and move to `lookup`
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

=item \$DB->get_item_ts_id(...)

TBD (To be documented)

=cut
# TODO: Document function behavior
# Note: I inherited this funciton from Rob and have yet to reverse engineer it ~TS
# TODO: Create DB::ItemId.pm and move to `lookup`
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

=item DB->disconnect()

Removes the subdrivers and disconnects from the database

=cut
sub disconnect
{
    my $self = shift;
    delete $self->{address};
    delete $self->{moc_project};
    delete $self->{poc};
    delete $self->{project};
    delete $self->{role};
    $self->{_conn}->disconnect();
}

=back
=cut

1;
__END__;
