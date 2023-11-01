_default:
    @just --list

# Convert statement from LATIN9 encoding to UTF8 encoding
convert FILE:
    iconv -f LATIN9 -t UTF8 {{FILE}} -o {{without_extension(FILE)}}_utf8.{{extension(FILE)}}

_build_release:
    zig build release-artifacts

_pack_release:
    zip zig-out/release/comdirect-spending-calculator-x86_64-windows.zip zig-out/release/comdirect-spending-calculator.exe
    tar czf zig-out/release/comdirect-spending-calculator-x86_64-linux.tar.gz zig-out/release/comdirect-spending-calculator

# Create and pack release artifacts
release:
    just _build_release
    just _pack_release
