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

1. `FromYmd`
1. `FromCardinal`
1. `FromCode`

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

In a web browser, find the version and sha256 sum of the [newest stable build](https://ziglang.org/download/). Assign the desired os/arch/version/commit to the environment variable `ZIGVER`, and the system directory where you want to install it (e.g., `/opt` or `/usr/local`) to PREFIX.

For example:
```
export ZIGVER=linux-x86_64-0.3.0+7dd1e0fc
export PREFIX=/opt
```

Now as a regular user account (but which has `sudo` privileges), execute the following commands:
```
curl -O https://ziglang.org/builds/zig-${ZIGVER}.tar.xz
sha256sum zig-${ZIGVER}.tar.xz
# check against published sha256 sums, proceed only if exact match

tar -xJf zig-${ZIGVER}.tar.xz
sudo mv zig-${ZIGVER} $PREFIX
sudo chown -R root:root $PREFIX/zig-${ZIGVER}
sudo chmod -R o-w $PREFIX/zig-${ZIGVER}
sudo bash -c "rm -f $PREFIX/zig || echo ignored"
sudo ln -s $PREFIX/zig-${ZIGVER} $PREFIX/zig

export PATH=$PREFIX/zig:$PATH
zig version
```

The output of the `zig version` command should match what you expect. You will probably want normal users to set the `PATH` as shown in their `.bashrc` files.

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

