
package Reporting::Services::OpenStack::Catalog;

use strict;
use POSIX;

use Data::Dumper;


my $DEBUG = $ENV{DEBUG};
my $_ENDPOINT_PREFS = [
    'public', 
    'internal',
    'admin' 
];

sub new
{
	my ( $cls, $keystone ) = @_;
	my $self = bless { 
            catalog => { } 
        }, $cls;

    my ($catalog, $err) = $keystone->get_catalog();
    return (undef, $err) if $err;
    foreach my $entry (@{$catalog})
    {
        $self->{catalog}->{$entry->{id}} = $entry;
        $self->{catalog}->{$entry->{name}} = $entry;
    }

    return ($self, undef);
}

# sub get
# {
#     my ($self, $name) = @_;

#     foreach my $entry (@{$self->{catalog}})
#     {
#         if($entry->{name} eq $name)
#         {
#             foreach my $endpt (@{$entry->{endpoints}})
#             {
#                 if($endpt->{interface} eq 'public')
#                 {
#                     return $endpt->{url};
#                 }
#             }
#         }
#     }

#     return undef;
# }

# sub find_region
# {
#     my ($self, $name) = @_;

#     my $entry = $self->{catalog}->{$name};
#     foreach my $endpt (@{$entry->{endpoints}})
#     {
#         if($endpt->{interface} eq 'public' and $endpt->{region_id})
#         {
#             return $endpt->{region_id};
#         }
#     }

#     return undef;
# }


# Pretend that the elements in the catalog are functions that return
# the endpoint with highest (earliest) preference
# TODO: Handle multiple equivalant services 
#       eg. cinder(v1) vs cinderv2 vs cinderv3 vs cinderv3
our $AUTOLOAD;
sub AUTOLOAD {
    print("$AUTOLOAD\n") if $DEBUG;
    my ($self) = shift;
    my $called = $AUTOLOAD =~ s/.*:://r;

    my $entry = $self->{catalog}->{$called} or return undef;

    my $endpoints_map = {};
    for my $endpoint (@{$entry->{endpoints}})
    {
        $endpoints_map->{$endpoint->{interface}} = $endpoint;
    }
    for (my $i = 0; $i < (scalar @$_ENDPOINT_PREFS); $i++) {
        my $selected_endpoint = $endpoints_map->{@{$_ENDPOINT_PREFS}[$i]};
        return $selected_endpoint if $selected_endpoint;
    }
    return undef;
}

# Avoid Autoloading DESTROY
sub DESTROY { }

1;
__END__;
