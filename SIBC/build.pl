# $Id: build.pl

use File::stat;
use File::Which;

`zig build-exe SIBTests.zig --name codegen-tests`;
