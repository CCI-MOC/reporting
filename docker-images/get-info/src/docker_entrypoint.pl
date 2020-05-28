
BEGIN {
  use File::Basename;
  use lib dirname($0) . "/app";
  require 'get_info.pl';
}

my $ec = main();
exit $ec;
