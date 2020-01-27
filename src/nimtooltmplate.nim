# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import nimtooltmplatepkg/submodule
import cligen,os

proc main(file="", isflag=false, log={osErr}) =
  echo ""

when isMainModule:
  dispatch(main, help = {
             "file"  : "optional input (\"-\"|!tty=stdin)",
             "isflag": "is flag for switch",
             "log"   : ">stderr{osErr, summ}"})