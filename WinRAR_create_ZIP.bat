if exist "%ProgramFiles(x86)%\WinRAR" (
  set zipRoot="%ProgramFiles(x86)%\WinRAR"
)

if exist "%ProgramFiles%\WinRAR" (
  set zipRoot="%ProgramFiles%\WinRAR"
) 

%zipRoot%\WinRAR.exe a -afzip "FS19_guidanceSteering_dev.zip" "*.xml" "*.lua" "*.i3d" "*.i3d.shapes" "*.dds" "*.wav" -r -xr!_modding  -xr!data -xr!_r -xr!tests -xr!".idea" -xr!run_unit_tests.lua
