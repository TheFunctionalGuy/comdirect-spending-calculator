## Usage

The input statements need to be exported from a [comdirect](https://www.comdirect.de/) user account and converted to UTF-8 by running `just convert <exported_statement.json>`.

Information about `just` can be found in the [GitHub repo](https://github.com/casey/just).

```
-h, --help               Display this help and exit
-i, --include <FILE>...  Optional filters which specify which values to take into account
-e, --exclude <FILE>...  Optional filters which specify which values NOT to take into account after applying the including filter
-v, --verbose            Show additional verbose output
<FILE>                   First statement
<FILE>                   Second statement
```

Both one or two statements as input are supported.

When only one statement is supplied all filters are only applied to this statement and the final result is the earnings/expenses for this statement.
When supplying two statements the filters will be applied to both statements and the results for the second statement will be subtracted from the result of the first statement.
The final result is the difference between both intermediate results.


## Installation

Installing `comdirect-spending-calculator` is very easy. You will need [a build of Zig](https://ziglang.org/download/) (`master` or `0.11.0`) to build `comdirect-spending-calculator`.

```bash
git clone https://github.com/TheFunctionalGuy/comdirect-spending-calculator
cd comdirect-spending-calculator
zig build install -Doptimize=ReleaseSafe --prefix-exe-dir ~/prefixes/zig-bins/
```

### Build Options

| Option      | Type   | Default Value | What it Does                                                              |
| ----------- | ------ | ------------- | ------------------------------------------------------------------------- |
| `-Duse_gpa` | `bool` | false         | Use a `GeneralPurposeAllocator` when set, which can be good for debugging |
