$exclude = @(".idea", ".github", ".gitignore", "zip.bat", "zip-builder.ps1", ".git")
$path = $(get-location).Path;
$destination = $path + "\FS19_guidanceSteering_dev.zip"
$files = Get-ChildItem -Path $path -Exclude $exclude

Compress-Archive -Path $files -DestinationPath $destination -CompressionLevel Fastest
