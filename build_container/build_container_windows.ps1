$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

function DownloadAndCheck
{
    param([string]$to, [string]$url, [string]$sha256)

    echo "Downloading $url to $to..."
    (New-Object System.Net.WebClient).DownloadFile($url, $to)
    $actual = (Get-FileHash -Path $to -Algorithm SHA256).Hash
    if ($actual -ne $sha256) {
        echo "Download of $url to $to is invalid, expected sha256: $sha256, but got: $actual";
        exit 1
    }
    echo "done."
}

function AddToPath
{
    param([string] $directory)

    $oldPath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
    $newPath = "$oldPath;$directory"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
    # Add to local path so subsequent commands have access to the executables they need
    $env:PATH += ";$directory"
    echo "Added $directory to PATH"
}

function RunAndCheckError
{
    param([string] $exe, [string[]] $argList, [Parameter(Mandatory=$false)] $isInstaller = $false)

    echo "Running '$exe $argList'..."
    if ($isInstaller) {
        echo "(running as Windows software installer)"
        Start-Process $exe -ArgumentList "$argList" -Wait -NoNewWindow
    } else {
        &$exe $argList
        if ($LASTEXITCODE -ne 0) {
            echo "$exe $argList exited with code $LASTEXITCODE"
            exit $LASTEXITCODE
        }
    }
    echo "done."
}

# Ensures paths rooted at /c/ can be found by programs running via msys2 shell
RunAndCheckError "cmd.exe" @("/s", "/c", "mklink /D C:\c C:\")

# Enable localhost DNS name resolution
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Encoding ASCII -Value "
127.0.0.1 localhost
::1       localhost
"

mkdir -Force C:\tools

# Bazelisk
mkdir -Force C:\tools\bazel
DownloadAndCheck C:\tools\bazel\bazel.exe `
                 https://github.com/bazelbuild/bazelisk/releases/download/v1.3.0/bazelisk-windows-amd64.exe `
                 31fa9fcf250fe64aa3c5c83b69d76e1e9571b316a58bb5c714084495623e38b0
AddToPath C:\tools\bazel

# VS 2019 Build Tools
# Pinned to version downloaded on 6/3/2020 via https://aka.ms/vs/16/release/vs_buildtools.exe
DownloadAndCheck $env:TEMP\vs_buildtools.exe `
                 https://download.visualstudio.microsoft.com/download/pr/17a0244e-301e-4801-a919-f630bc21177d/9821a63671d5768de1920147a2637f0e079c3b1804266c1383f61bb95e2cc18b/vs_BuildTools.exe `
                 9821a63671d5768de1920147a2637f0e079c3b1804266c1383f61bb95e2cc18b
echo @"
{
  "version": "1.0",
  "components": [
    "Microsoft.VisualStudio.Component.VC.CoreBuildTools",
    "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
    "Microsoft.VisualStudio.Component.Windows10SDK",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
    "Microsoft.VisualStudio.Component.Windows10SDK.18362"
  ]
}
"@ > $env:TEMP\vs_buildtools_config
RunAndCheckError "cmd.exe" @("/s", "/c", "$env:TEMP\vs_buildtools.exe --addProductLang en-US --quiet --wait --norestart --nocache --config $env:TEMP\vs_buildtools_config")
AddToPath (Resolve-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\x64").Path

# CMake (to ensure a 64-bit build of the tool, VS BuildTools ships a 32-bit build)
DownloadAndCheck $env:TEMP\cmake.msi `
                 https://github.com/Kitware/CMake/releases/download/v3.17.2/cmake-3.17.2-win64-x64.msi `
                 06e999be9e50f9d33945aeae698b9b83678c3f98cedb3139a84e19636d2f6433
RunAndCheckError "msiexec.exe" @("/i", "$env:TEMP\cmake.msi", "/quiet", "/norestart") $true
AddToPath $env:ProgramFiles\CMake\bin

# Ninja
mkdir -Force C:\tools\ninja
DownloadAndCheck $env:TEMP\ninja.zip `
                 https://github.com/ninja-build/ninja/releases/download/v1.10.0/ninja-win.zip `
                 919fd158c16bf135e8a850bb4046ec1ce28a7439ee08b977cd0b7f6b3463d178
Expand-Archive -Path $env:TEMP\ninja.zip -DestinationPath C:\tools\ninja
AddToPath C:\tools\ninja

# Python3 (do not install via msys2, that version behaves like posix)
DownloadAndCheck $env:TEMP\python3-installer.exe `
                 https://www.python.org/ftp/python/3.8.2/python-3.8.2-amd64.exe `
                 8e400e3f32cdcb746e62e0db4d3ae4cba1f927141ebc4d0d5a4006b0daee8921
# python installer needs to be run as an installer with Start-Process
RunAndCheckError "$env:TEMP\python3-installer.exe" @("/quiet", "InstallAllUsers=1", "Include_launcher=0", "InstallLauncherAllUsers=0") $true
AddToPath $env:ProgramFiles\Python38
AddToPath $env:ProgramFiles\Python38\Scripts
# Add symlinks for canonical executables expected in a Python environment
RunAndCheckError "cmd.exe" @("/c", "mklink", "$env:ProgramFiles\Python38\python3.exe", "$env:ProgramFiles\Python38\python.exe")
RunAndCheckError "cmd.exe" @("/c", "mklink", "$env:ProgramFiles\Python38\python3.8.exe", "$env:ProgramFiles\Python38\python.exe")
# Upgrade pip
RunAndCheckError "python.exe" @("-m", "pip", "install", "--upgrade", "pip")
# Install wheel so rules_python rules will run
RunAndCheckError "pip.exe" @("install", "wheel")

# 7z
DownloadAndCheck $env:TEMP\7z.msi `
                 https://www.7-zip.org/a/7z1900-x64.msi `
                 a7803233eedb6a4b59b3024ccf9292a6fffb94507dc998aa67c5b745d197a5dc
# msiexec needs to be run as an installer with Start-Process
RunAndCheckError "msiexec.exe" @("/i", "$env:TEMP\7z.msi", "/passive", "/norestart") $true
AddToPath $env:ProgramFiles\7-Zip

# msys2 and required packages
DownloadAndCheck $env:TEMP\msys2.tar.xz `
                 http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20190524.tar.xz `
                 168e156fa9f00d90a8445676c023c63be6e82f71487f4e2688ab5cb13b345383
RunAndCheckError "7z.exe" @("x", "$env:TEMP\msys2.tar.xz", "-o$env:TEMP\msys2.tar", "-y")
RunAndCheckError "7z.exe" @("x", "$env:TEMP\msys2.tar", "-oC:\tools", "-y")
AddToPath C:\tools\msys64\usr\bin
RunAndCheckError "bash.exe" @("-c", "pacman-key --init")
RunAndCheckError "bash.exe" @("-c", "pacman-key --populate msys2")
# Force update of package db
RunAndCheckError "pacman.exe" @("-Syy", "--noconfirm")
# TODO(sunjayBhatia, wrowe): pacman core package update causes building with latest
# Docker to hang between completion of this script and before discarding intermediate
# build container (that is reported as exited). Skipping the existing package updates
# for now until we have a resolution.
# Docker version running in AZP at last check: 19.03.5
# Update core packages (msys2, pacman, bash, etc.)
# RunAndCheckError "pacman.exe" @("-Suu", "--noconfirm")
# Update remaining packages (and package db refresh in case previous step requires it)
# RunAndCheckError "pacman.exe" @("-Syu", "--noconfirm")
RunAndCheckError "pacman.exe" @("-S", "--noconfirm", "--needed", "diffutils", "patch", "unzip", "zip")
RunAndCheckError "pacman.exe" @("-Scc", "--noconfirm")

# Git
DownloadAndCheck $env:TEMP\git-setup.exe `
                 https://github.com/git-for-windows/git/releases/download/v2.26.2.windows.1/Git-2.26.2-64-bit.exe `
                 cdf76510979dace4d3f5368e2f55d4289c405e249399e7ed09049765489da6e8
RunAndCheckError "$env:TEMP\git-setup.exe" @("/SILENT") $true
AddToPath $env:ProgramFiles\Git\bin

echo "Cleaning up temporary files..."
rm -Recurse -Force $env:TEMP\*
echo "done."

echo "Finished software installation."
