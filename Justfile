_default:
    @just --list

# Convert statement from LATIN9 encoding to UTF8 encoding
convert FILE:
    iconv -f LATIN9 -t UTF8 {{FILE}} -o {{without_extension(FILE)}}_utf8.{{extension(FILE)}}

_build_release:
    zig build release-artifacts

_pack_release:
    cd  zig-out/release/comdirect-spending-calculator-x86_64-windows && zip ../comdirect-spending-calculator-x86_64-windows.zip comdirect-spending-calculator.exe
    tar czvf zig-out/release/comdirect-spending-calculator-x86_64-linux.tar.gz --directory zig-out/release/comdirect-spending-calculator-x86_64-linux .

# Create and pack release artifacts
release:
    just _build_release
    just _pack_release
