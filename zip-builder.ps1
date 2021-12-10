$include = @("*.xml", "*.lua", "*.i3d", "*.i3d.shapes", "*.dds", "*.ogg")
$zipfilename = "FS22_guidanceSteering_dev.zip"

if (test-path "$env:ProgramFiles\7-Zip\7z.exe") {
    set-alias 7z "$env:ProgramFiles\7-Zip\7z.exe"
    7z a -tzip $zipfilename $include -r -xr!".idea" -xr!"data"
} elseif (test-path "$env:ProgramFiles\WinRAR\WinRAR.exe") {
    set-alias winrar "$env:ProgramFiles\WinRAR\WinRAR.exe"
    winrar a -afzip $zipfilename $include -r -x".idea" -x"data"
} else {
    throw "7-Zip or WinRAR is needed!"
}