import parseopt, strutils, os

import nimblepkg/[cli, options, config]
import nimblepkg/common as nimble_common
import analytics

import common

type
  CliParams* = ref object
    commands*: seq[string]
    onlyInstalled*: bool
    clitemplateDir*: string
    firstInstall*: bool
    nimbleOptions*: Options
    analytics*: AsyncAnalytics
    pendingReports*: int ## Count of pending telemetry reports.


let doc = """
clitemplate: The Nim toolchain installer.

Choose a job. Choose a mortgage. Choose life. Choose Nim.

Usage:
  clitemplate <version/path/channel>

Example:
  clitemplate 0.16.0
    Installs (if necessary) and selects version 0.16.0 of Nim.
  clitemplate stable
    Installs (if necessary) Nim from the stable channel (latest stable release)
    and then selects it.
  clitemplate #head
    Installs (if necessary) and selects the latest current commit of Nim.
    Warning: Your shell may need quotes around `#head`: clitemplate "#head".
  clitemplate ~/projects/nim
    Selects the specified Nim installation.
  clitemplate update stable
    Updates the version installed on the stable release channel.
  clitemplate versions [--installed]
    Lists the available versions of Nim that clitemplate has access to.

Channels:
  stable
    Describes the latest stable release of Nim.
  devel
    Describes the latest development (or nightly) release of Nim taken from
    the devel branch.

Commands:
  update    <version/channel>    Installs the latest release of the specified
                                 version or channel.
  show                           Displays the selected version and channel.
  update    self                 Updates clitemplate itself.
  versions  [--installed]        Lists available versions of Nim, passing
                                 `--installed` only displays versions that
                                 are installed locally (no network requests).

Options:
  -h --help             Show this output.
  -y --yes              Agree to every question.
  --version             Show version.
  --verbose             Show low (and higher) priority output.
  --debug               Show debug (and higher) priority output.
  --noColor             Don't colorise output.

  --clitemplateDir:<dir>  Specify the directory where toolchains should be
                        installed. Default: ~/.clitemplate.
  --nimbleDir:<dir>     Specify the Nimble directory where binaries will be
                        placed. Default: ~/.nimble.
  --firstInstall        Used by install script.
"""

proc command*(params: CliParams): string =
  return params.commands[0]

proc getDownloadDir*(params: CliParams): string =
  return params.clitemplateDir / "downloads"

proc getInstallDir*(params: CliParams): string =
  return params.clitemplateDir / "toolchains"

proc getChannelsDir*(params: CliParams): string =
  return params.clitemplateDir / "channels"

proc getBinDir*(params: CliParams): string =
  return params.nimbleOptions.getBinDir()

proc getCurrentFile*(params: CliParams): string =
  ## Returns the path to the file which specifies the currently selected
  ## installation. The contents of this file is a path to the selected Nim
  ## directory.
  return params.clitemplateDir / "current"

proc getCurrentChannelFile*(params: CliParams): string =
  return params.clitemplateDir / "current-channel"

proc getAnalyticsFile*(params: CliParams): string =
  return params.clitemplateDir / "analytics"

proc getMingwPath*(params: CliParams): string =
  return params.getInstallDir() / "mingw32"

proc getMingwBin*(params: CliParams): string =
  return getMingwPath(params) / "bin"

proc getBinArchiveFormat*(): string =
  when defined(windows):
    return ".zip"
  else:
    return ".tar.xz"

proc getDownloadPath*(params: CliParams, downloadUrl: string): string =
  let (_, name, ext) = downloadUrl.splitFile()
  return params.getDownloadDir() / name & ext

proc writeHelp() =
  echo(doc)
  quit(QuitFailure)

proc writeVersion() =
  echo("clitemplate v$1 ($2 $3) [$4/$5]" %
       [clitemplateVersion, CompileDate, CompileTime, hostOS, hostCPU])
  quit(QuitSuccess)

proc writeNimbleBinDir(params: CliParams) =
  # Special option for scripts that install clitemplate.
  echo(params.getBinDir())
  quit(QuitSuccess)

proc newCliParams*(proxyExeMode: bool): CliParams =
  new result
  result.commands = @[]
  result.clitemplateDir = getHomeDir() / ".clitemplate"
  # Init nimble params.
  try:
    result.nimbleOptions = initOptions()
    if not proxyExeMode:
      result.nimbleOptions.config = parseConfig()
  except NimbleQuit:
    discard

proc parseCliParams*(params: var CliParams, proxyExeMode = false) =
  params = newCliParams(proxyExeMode)

  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      params.commands.add(key)
    of cmdLongOption, cmdShortOption:
      let normalised = key.normalize()
      # Don't want the proxyExe to return clitemplate's help/version.
      case normalised
      of "help", "h":
        if not proxyExeMode: writeHelp()
      of "version", "v":
        if not proxyExeMode: writeVersion()
      of "getnimblebin":
        # Used by installer scripts to know where the clitemplate executable
        # should be copied.
        if not proxyExeMode: writeNimbleBinDir(params)
      of "verbose": setVerbosity(LowPriority)
      of "debug": setVerbosity(DebugPriority)
      of "nocolor": setShowColor(false)
      of "clitemplatedir": params.clitemplateDir = val.absolutePath()
      of "nimbledir": params.nimbleOptions.nimbleDir = val.absolutePath()
      of "firstinstall": params.firstInstall = true
      of "y", "yes": params.nimbleOptions.forcePrompts = forcePromptYes
      of "installed": params.onlyInstalled = true
      else:
        if not proxyExeMode:
          raise newException(clitemplateError, "Unknown flag: --" & key)
    of cmdEnd: assert(false)

  if params.commands.len == 0 and not proxyExeMode:
    writeHelp()
