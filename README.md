## Usage

### Overview
```
-h, --help               Display this help and exit
-i, --include <FILE>...  Optional filters which specify which values to take into account
-e, --exclude <FILE>...  Optional filters which specify which values NOT to take into account after applying the including filter
-v, --verbose            Show additional verbose output
<FILE>                   First statement
<FILE>                   Second statement
```

The program expects [statements](#statements) as positional inputs and [filters](#filters) as inputs via flags.
Statements are processed entry by entry and filtered respectively by the given including/excluding filters.
Results are all values of a statement summed up after they have passed both filter types.

Both one or two statements as input are supported.


#### One Statement Mode

When only one statement is supplied all filters are only applied to this statement and the final result is the _earnings/expenses_ for this statement.


#### Two Statement Mode

When supplying two statements the filters will be applied to both statements and the results for the second statement will be subtracted from the result of the first statement.
The final result is the _difference_ between both intermediate results.


### Statements

The input statements need to be exported from a [comdirect](https://www.comdirect.de/) user account and converted to UTF-8 by running `just convert <exported_statement.json>`.

Information about `just` can be found in the [GitHub repo](https://github.com/casey/just).


### Filters

Filters follow a line-based format.

Each line specifies either:
- A comment when the line starts with `//` followed by arbitrary text
- Another filter file when the line starts with `@` followed by a path relative to the current filter file
- A string which is matched against the entry description via `mem.startsWith`


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
