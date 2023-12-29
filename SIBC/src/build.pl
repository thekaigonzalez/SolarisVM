# $Id: build.pl


`zig cc main.zig -g -o output/sasm-debug`;
`zig cc main.zig -o output/sasm -Ofast`;
