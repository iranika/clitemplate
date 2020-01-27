# Package

version       = "0.0.1"
author        = "iranika"
description   = "The better practice CLI tool for nim"
license       = "MIT"

srcDir = "src"
binDir = "bin"
bin = @["clitemplate"]

skipExt = @["nim"]

# Dependencies

requires "nim >= 1.0.4", "nimble#5bb795a", "nimarchive >= 0.3.4"
requires "libcurl >= 1.0.0"
requires "analytics >= 0.2.0"
requires "osinfo >= 0.3.0"

task test, "Run the clitemplate tester!":
  withDir "tests":
    exec "nim c -r tester"
