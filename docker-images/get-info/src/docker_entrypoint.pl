
use strict;

use File::Basename;
use lib dirname($0) . "/perl5";

use Reporting::GetInfo;

exit Reporting::GetInfo::main();
