# zigdate
ziglang date library

A library of methods for manipulating dates in ziglang.

Developed with ziglang 0.3.0+d494a5f4
Tested (as of this moment) on Windows 10 x86\_64 (Build 17134).

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