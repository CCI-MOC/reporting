
package Reporting::Creds;

use JSON;
use strict;

my $DEBUG = 0;

sub load_env_refs
{
    my $e = shift or return ();

    if (ref $e eq 'ARRAY') 
    {
        if ($DEBUG) 
        {
            print Dumper{@$e};
        }
        $e = [ map { load_env_refs($_) } @$e ];
    }
    elsif (ref $e eq 'HASH') 
    {
        if ($DEBUG)
        {
            print Dumper{%$e};
        }

        if (defined $e->{fromEnv})
        {
            return $ENV{$e->{fromEnv}};
        }
        else 
        {
            while (my ($key, $value) = each %{$e}) 
            {
                $e->{$key} = load_env_refs($value);
            }
        }
    }
    return $e;
}

sub load
{
    my $text=undef;

    if (defined $ENV{'CREDS_TEXT'})
    {
        $text = $ENV{'CREDS_TEXT'};
    }
    elsif (defined $ENV{'CREDS_FILE'})
    {
        my $file = $ENV{'CREDS_FILE'};
        open(my $fp, '<', $file) or die "Cannot open file: $file";
        {
            local $/;
            $text = <$fp>;
        }
        close($fp);
    }

    die "No Credential object or filename found!\n" unless defined($text);
    return load_env_refs(decode_json($text));
}

1;
__END__;
