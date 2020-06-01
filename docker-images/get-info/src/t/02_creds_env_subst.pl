
use Data::Dumper;
use Test::More tests => 4;
use strict;
use warnings;

require 'creds.pl';

sub putv {
  my $dumper = Data::Dumper->new(\@_);
  $dumper->Indent(0);
  $dumper->Terse(1);
  return $dumper->Dump;
}

sub test_same {
  my ($v, $name) = @_;
  if (our $DEBUG) {
    print "Testing value should not change: \n" 
        . putv($v) . "\n";
  }
  is_deeply(load_env_refs($v), $v, $name);
}

sub test_replace {
  my ($ini, $fin, $name) = @_;
  if (our $DEBUG) {
    print "Testing value change: \n";
  }
  is_deeply(load_env_refs($ini), $fin, $name);
}

{
  our %ENV;
  our $DEBUG = 0;

  $ENV{REF1} = 'a';
  $ENV{REF2} = 'b';

  my $example_1 = {
    keyA => 'valueA',
    keyB => 'valueB'
  };
  test_same($example_1, 'No Refs');

  my $example_2 = {
    keyA => {
      'fromEnv' => 'REF1',
    },
    keyB => {
      'fromEnv' => 'REF2',
    },
  };
  my $example_2_out = {
    keyA => $ENV{REF1},
    keyB => $ENV{REF2},
  };
  test_replace($example_2, $example_2_out, 'Top-Level Reference');

  my $example_3 = {
    serviceA => {
      creds => {
        key => { 'fromEnv' => 'REF1' },
      },
    },
    serviceB => {
      data => { 'fromEnv' => 'REF2' },
    }
  };
  my $example_3_out = {
    serviceA => {
      creds => {
        key => $ENV{REF1},
      },
    },
    serviceB => {
      data => $ENV{REF2},
    }
  };
  test_replace($example_3, $example_3_out, 'Nested Reference');

  my $example_4 = {
    serviceA => {
      creds => 'const'
    },
    array => [
      {
        type => 'exampleNested',
        creds => { 'fromEnv' => 'REF1' }
      }
    ]
  };
  my $example_4_out = {
    serviceA => {
      creds => 'const'
    },
    array => [
      {
        type => 'exampleNested',
        creds => $ENV{REF1}
      }
    ]
  };
  test_replace($example_4, $example_4_out, 'Reference in Array');

}
