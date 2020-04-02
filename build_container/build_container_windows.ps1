$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

function DownloadAndCheck
{
    param([string]$to, [string]$url, [string]$sha256)

    (New-Object System.Net.WebClient).DownloadFile($url, $to)

    $actual = (Get-FileHash -Path $to -Algorithm SHA256).Hash;
    if ($actual -ne $sha256) {
        echo "Downloading $url to $to is invalid, expected sha256: $sha256, but got: $actual";
        exit 1
    }
}

function AddToPath
{
    param([string] $directory)

    $oldPath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
    $newPath = "$oldPath;$directory"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
    # Add to local path so subsequent commands have access to the executables they need
    $env:PATH += ";$directory"
}

mkdir -Force C:\tools

# Bazelisk
mkdir -Force C:\tools\bazel
DownloadAndCheck C:\tools\bazel\bazel.exe `
                 https://github.com/bazelbuild/bazelisk/releases/download/v1.3.0/bazelisk-windows-amd64.exe `
                 31fa9fcf250fe64aa3c5c83b69d76e1e9571b316a58bb5c714084495623e38b0
AddToPath C:\tools\bazel

# VS Build Tools
DownloadAndCheck $env:TEMP\vs_buildtools.exe `
                 https://aka.ms/vs/16/release/vs_buildtools.exe `
                 4383a2e9eac72248bd56a25aed63051efb37393a7af3db4726868699c7cd99e4
echo @"
{
  "version": "1.0",
  "components": [
    "Microsoft.VisualStudio.Component.VC.CoreBuildTools",
    "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
    "Microsoft.VisualStudio.Component.Windows10SDK",
    "Microsoft.VisualStudio.Component.TestTools.BuildTools",
    "Microsoft.VisualStudio.Component.VC.ASAN",
    "Microsoft.VisualStudio.Component.VC.CMake.Project",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
    "Microsoft.VisualStudio.Component.Windows10SDK.18362"
  ]
}
"@ > $env:TEMP\vs_buildtools_config
cmd.exe /s /c "$env:TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache --config $env:TEMP\vs_buildtools_config"
if ($LASTEXITCODE -ne 0) {
  echo "VS Build Tools install failed with $LASTEXITCODE"
  exit $LASTEXITCODE
}
rm -Force $env:TEMP\vs_buildtools*
AddToPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.25.28610\bin\Hostx64\x64"
AddToPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
AddToPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"

# 7z
DownloadAndCheck $env:TEMP\7z.msi `
                 https://www.7-zip.org/a/7z1900-x64.msi `
                 a7803233eedb6a4b59b3024ccf9292a6fffb94507dc998aa67c5b745d197a5dc
Start-Process msiexec.exe -ArgumentList "/i $env:TEMP\7z.msi /passive /norestart" -Wait -NoNewWindow
rm -Force $env:TEMP\7z.msi
AddToPath $env:ProgramFiles\7-Zip

# msys2 and required packages
DownloadAndCheck $env:TEMP\msys2.tar.xz `
                 http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20190524.tar.xz `
                 168e156fa9f00d90a8445676c023c63be6e82f71487f4e2688ab5cb13b345383
Start-Process 7z.exe -ArgumentList "x $env:TEMP\msys2.tar.xz -o$env:TEMP\msys2.tar -y" -Wait -NoNewWindow
Start-Process 7z.exe -ArgumentList "x $env:TEMP\msys2.tar -oC:\tools -y" -Wait -NoNewWindow
rm -Recurse -Force $env:TEMP\msys2.tar*
AddToPath C:\tools\msys64\usr\bin
# Don't use Start-Process as it waits for all of bash's child processes to exit
bash.exe -c 'pacman-key --init'
if ($LASTEXITCODE -ne 0) {
    echo "bash.exe exited with $LASTEXITCODE"
    exit $LASTEXITCODE
}
bash.exe -c 'pacman-key --populate msys2'
if ($LASTEXITCODE -ne 0) {
    echo "bash.exe exited with $LASTEXITCODE"
    exit $LASTEXITCODE
}
Start-Process pacman.exe -ArgumentList "-Syyuu --noconfirm" -Wait -NoNewWindow
Start-Process pacman.exe -ArgumentList "-Syuu --noconfirm" -Wait -NoNewWindow
Start-Process pacman.exe -ArgumentList "-S --noconfirm --needed compression diffutils git patch" -Wait -NoNewWindow
Start-Process pacman.exe -ArgumentList "-Scc --noconfirm" -Wait -NoNewWindow

# Python3 (do not install via msys2, that version behaves like posix)
DownloadAndCheck $env:TEMP\python3-installer.exe `
                 https://www.python.org/ftp/python/3.8.2/python-3.8.2-amd64.exe `
                 8e400e3f32cdcb746e62e0db4d3ae4cba1f927141ebc4d0d5a4006b0daee8921
Start-Process $env:TEMP\python3-installer.exe -ArgumentList "/quiet InstallAllUsers=1 Include_launcher=0 InstallLauncherAllUsers=0" -Wait -NoNewWindow
rm -Force $env:TEMP\python3-installer.exe
AddToPath $env:ProgramFiles\Python38

# Clear out $env:TEMP to save space
rm -Recurse -Force $env:TEMP\*
