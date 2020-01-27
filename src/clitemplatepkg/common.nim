import nimblepkg/version

type
  clitemplateError* = object of NimbleError

const
  clitemplateVersion* = "0.5.1"

  proxies* = [
      "nim",
      "nimble",
      "nimgrep",
      "nimpretty",
      "nimsuggest",
      "testament"
    ]

  mingwProxies* = [
    "gcc",
    "g++",
    "gdb",
    "ld"
  ]
