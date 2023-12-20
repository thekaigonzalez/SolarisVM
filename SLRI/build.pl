# $Id: build.pl

use File::Which;

my $zig = which("zig");

if (! $zig) {
  die "zig not found";
}

`$zig build-exe test.zig`;
`$zig build-exe main.zig --name solrun -O ReleaseFast`;
`$zig build-exe main.zig --name solrun-tiny -O ReleaseSmall`;
