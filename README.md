# zigdate
ziglang date library

A library of methods for manipulating dates in ziglang.

Developed with ziglang 0.3.0+d494a5f4

Tested on:

* Windows 10 x86\_64 (Build 17134)
* Fedora Core 28 x86\_64 (Linux 4.20.16)

## Goals

* Learn ziglang by porting an existing useful library from C.
* Store dates in a small structure so it can be inexpensively passed by value.
* Provide translation between Gregorian and a "date code", the number of
  days that have elapsed since the start of the Unix epoch (01-Jan-1970).
* Implementation inspired by, and adherent to the algorithms described in
  _Calendrical Calculations_ (Millenium Ed.) by Edward M. Reingold and
  Nachum Dershowitz.
* Performance. Be efficient with CPU cycles and RAM.
* Provide an interface for finding "Cardinal" dates (e.g., the fourth
  Wednesday of August).
* Provide a trivial mapping to Julian Dates, which are useful in astronomy.
* Platform independence. The same results must be provided on all supported 
  architectures and operating systems.

## Goals, but not started yet

* Deal with time points, time zones, locales, and civil time.
* Handling time resolution finer than one day.

## Non-goals

* Calendar systems other than Gregorian.
* Concern for historical accuracy. Although this library correctly applies Gregorian dates
  to the past, it merely maps the current implementation and alignment.

# Documentation

I've placed zig-style /// comments in front of all the public objects in the code, but
I have not figured out how to generate docs from this yet. 

Basically, you construct a `Date` type with one of three constructors:

1. FromYmd
1. FromCardinal
1. FromCode

Constructors that can fail return an error union. Therefore, call with `try` or `catch`,
depending upon whether you want to propagate the range error to your caller, or
supply a default date to use in case of error.

Because the Date type has a size of 4, it is easily passed by value.

Once you have a Date, access the parts with `.year()`, `.month()`, and `.day()`.

To perform arithmetic, obtain the date code with `.code()`.

Generally the result of the arithmetic operation(s) will be a new date code. Use `FromCode`
to get a usable Date.

Additional examples may be found in `src/example.zig` .

# Zig Quick start

Because it is new, here's the TL;DNR on installing the latest Zig compiler, downloading
and running this code.

### Download zig and install

From some path where you can store local binaries (e.g., `/usr/local/bin`), and logged in as 
a user with privileges to write there:

Set the ZIGVER to the [newest stable build](https://ziglang.org/download/):
```
export ZIGVER=linux-x86\_64-0.3.0+c76d51de
curl -O https://ziglang.org/builds/zig-${ZIGVER}.tar.xz
sha256sum zig-${ZIGVER}.tar.xz
# check against published sha256 sums, proceed only if exact match

tar -tJf zig-${ZIGVER}.tar.xz
ln -sf zig-${ZIGVER} zig
export PATH=$(pwd)/zig:$PATH
```

### Clone this project, test and build

From some path where you keep all your third-party source clones:
```
mkdir -p github.com/brhamon
cd $_
git clone https://github.com/brhamon/zigdate.git
cd zigdate
zig test src/gregorianDate_test.zig
zig build run
```

