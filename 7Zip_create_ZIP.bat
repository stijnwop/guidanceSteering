if exist "%ProgramFiles(x86)%\7-Zip" (
  set zipRoot="%ProgramFiles(x86)%\7-Zip"
)

if exist "%ProgramFiles%\7-Zip" (
  set zipRoot="%ProgramFiles%\7-Zip"
) 

%zipRoot%\7z.exe a -tzip "FS19_guidanceSteering_dev.zip" "*.xml" "*.lua" "*.i3d" "*.i3d.shapes" "*.dds" "*.wav" -r -xr!_modding  -xr!data -xr!_r -xr!tests -xr!".idea" -xr!run_unit_tests.lua
