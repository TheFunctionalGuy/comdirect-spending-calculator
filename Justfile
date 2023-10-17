_default:
    @just --list

convert FILE:
    iconv -f LATIN9 -t UTF8 {{FILE}} -o {{without_extension(FILE)}}_utf8.{{extension(FILE)}}
