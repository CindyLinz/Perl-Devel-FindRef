BEGIN { $| = 1; print "1..1\n"; }

use Devel::FindRef;
use Scalar::Util qw(weaken);

my $y;
my @y = (2, \$y, [4, 5, \$y, \$y], {a => \$y});
weaken $y[2][2];

Devel::FindRef::track \$y;

print "ok 1\n";
