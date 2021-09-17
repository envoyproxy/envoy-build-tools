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

    $oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
    $newPath = "$directory;$oldPath"
    # Add to local path so subsequent commands have access to the executables they need
    $env:PATH = "$directory;$env:PATH"
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, [System.EnvironmentVariableTarget]::Machine)
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

function DisableService
{
    param([string] $serviceName)

    echo "Disabling service '$serviceName'"
    Set-Service -Name $serviceName -StartupType Disabled
    Stop-Service -Force -Name $serviceName
}

DisableService DiagTrack
DisableService LanmanWorkstation
DisableService MSDTC
DisableService SysMain
DisableService usosvc
DisableService WinRM

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
                 https://github.com/bazelbuild/bazelisk/releases/download/v1.7.5/bazelisk-windows-amd64.exe `
                 3370b9064a5bee879b675a77359ca14b3d2c5fa06364ae16b9ab2ff1773c9d0f
AddToPath C:\tools\bazel

# VS 2019 Build Tools
# Pinned to version 16.9.4 downloaded on 4/14/2021 via https://aka.ms/vs/16/release/vs_buildtools.exe
DownloadAndCheck $env:TEMP\vs_buildtools.exe `
                 https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/67584dbce4956291c76a5deabbadc15c9ad6a50d6a5f4458765b6bd3a924aead/vs_BuildTools.exe `
                 67584dbce4956291c76a5deabbadc15c9ad6a50d6a5f4458765b6bd3a924aead
# See: https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019#c-build-tools
# Other dependent/required components including the "Microsoft.VisualStudio.Workload.MSBuildTools"
# are added by the installer, do not need to be listed below, and cannot be supressed.
echo @"
{
  "version": "1.0",
  "components": [
    "Microsoft.VisualStudio.Workload.VCTools",
    "Microsoft.VisualStudio.Component.Windows10SDK.19041",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
  ]
}
"@ > $env:TEMP\vs_buildtools_config
RunAndCheckError "cmd.exe" @("/s", "/c", "$env:TEMP\vs_buildtools.exe --addProductLang en-US --quiet --wait --norestart --nocache --config $env:TEMP\vs_buildtools_config")
$msvcBasePath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC"
$msvcFullPath = Join-Path -Path $msvcBasePath -ChildPath "Tools\MSVC\*\bin\Hostx64\x64" -Resolve
AddToPath $msvcFullPath
[System.Environment]::SetEnvironmentVariable('BAZEL_VC', $msvcBasePath)

# MS SDK - Debug Tools
# Pinned to SDK version 2004 release 12/16/2020 link from https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk/
DownloadAndCheck $env:TEMP\winsdksetup.exe `
                 https://download.microsoft.com/download/4/d/2/4d2b7011-606a-467e-99b4-99550bf24ffc/windowssdk/winsdksetup.exe `
		 42d2774274d1135fc598c180c2acbf2321eb4192f59e511e6ac7772870bf6de1
RunAndCheckError "cmd.exe" @("/s", "/c", "$env:TEMP\winsdksetup.exe /features OptionId.WindowsDesktopDebuggers /quiet /norestart")
AddToPath "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64"

# CMake to ensure a 64-bit build of the tool (VS BuildTools ships a 32-bit build)
DownloadAndCheck $env:TEMP\cmake.msi `
                 https://github.com/Kitware/CMake/releases/download/v3.20.1/cmake-3.20.1-windows-x86_64.msi `
                 a2eb2811aada9f4830281aa407231b9295dcac4b18bdbefc35d9dd71775110e8
RunAndCheckError "msiexec.exe" @("/i", "$env:TEMP\cmake.msi", "/quiet", "/norestart") $true
AddToPath $env:ProgramFiles\CMake\bin

# Ninja to ensure a 64-bit build of the tool (VS BuildTools ships a 32-bit build)
mkdir -Force C:\tools\ninja
DownloadAndCheck $env:TEMP\ninja.zip `
                 https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip `
                 bbde850d247d2737c5764c927d1071cbb1f1957dcabda4a130fa8547c12c695f
Expand-Archive -Path $env:TEMP\ninja.zip -DestinationPath C:\tools\ninja
AddToPath C:\tools\ninja

# LLVM to ensure a 64-bit build of the tool (VS BuildTools ships a 32-bit build)
DownloadAndCheck $env:TEMP\LLVM-win64.exe `
                 https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/LLVM-12.0.1-win64.exe `
                 fcbabc9a170208bb344f7bba8366cca57ff103d72a316781bbb77d634b9e9433
RunAndCheckError $env:TEMP\LLVM-win64.exe @("/S") $true
AddToPath $env:ProgramFiles\LLVM\bin

# NASM (preferred by some OSS projects over MS ml.exe, closer to gnu/intel syntax)
$nasmVersion = "2.15.05"
DownloadAndCheck $env:TEMP\nasm-win64.zip `
                 https://www.nasm.us/pub/nasm/releasebuilds/$nasmVersion/win64/nasm-$nasmVersion-win64.zip `
                 f5c93c146f52b4f1664fa3ce6579f961a910e869ab0dae431bd871bdd2584ef2
Expand-Archive -Path $env:TEMP\nasm-win64.zip -DestinationPath C:\tools\
AddToPath C:\tools\nasm-$nasmVersion

# Python3 (do not install via msys2 or the MS store's flavors, this version follows Win32 semantics)
DownloadAndCheck $env:TEMP\python3-installer.exe `
                 https://www.python.org/ftp/python/3.9.4/python-3.9.4-amd64.exe `
                 58e6bb9d08fd250c1defb7a7a7247993b4ea349518ba877abb6364de85029e04
# python installer needs to be run as an installer with Start-Process
RunAndCheckError "$env:TEMP\python3-installer.exe" @("/quiet", "InstallAllUsers=1", "Include_launcher=0", "InstallLauncherAllUsers=0") $true
AddToPath $env:ProgramFiles\Python39
AddToPath $env:ProgramFiles\Python39\Scripts
# Add symlinks for canonical executables expected in a Python environment
RunAndCheckError "cmd.exe" @("/c", "mklink", "$env:ProgramFiles\Python39\python3.exe", "$env:ProgramFiles\Python39\python.exe")
RunAndCheckError "cmd.exe" @("/c", "mklink", "$env:ProgramFiles\Python39\python3.9.exe", "$env:ProgramFiles\Python39\python.exe")
# Upgrade pip
RunAndCheckError "python.exe" @("-m", "pip", "install", "--upgrade", "pip")
# Install wheel so rules_python rules will run
RunAndCheckError "pip.exe" @("install", "wheel")
RunAndCheckError "pip.exe" @("install", "virtualenv")

# 7z only to unpack msys2
DownloadAndCheck $env:TEMP\7z-installer.exe `
                 https://www.7-zip.org/a/7z1900-x64.exe `
                 0f5d4dbbe5e55b7aa31b91e5925ed901fdf46a367491d81381846f05ad54c45e
$quo = '"'
RunAndCheckError "$env:TEMP\7z-installer.exe" @("/S", "/D=$quo$env:TEMP\7z$quo")

# msys2 with additional required packages
DownloadAndCheck $env:TEMP\msys2.tar.xz `
                 https://github.com/msys2/msys2-installer/releases/download/2021-02-28/msys2-base-x86_64-20210228.tar.xz `
                 3f2ceb097a081789d9d497e0d3df8d99c16a1591b9984b0469440cd5bfa65092
RunAndCheckError "$env:TEMP\7z\7z.exe" @("x", "$env:TEMP\msys2.tar.xz", "-o$env:TEMP\msys2.tar", "-y")
RunAndCheckError "$env:TEMP\7z\7z.exe" @("x", "$env:TEMP\msys2.tar", "-oC:\tools", "-y")
AddToPath C:\tools\msys64\usr\bin
# To ensure msys2 link.exe (GNU link) does not conflict with link.exe from VC Build Tools
mv -Force C:\tools\msys64\usr\bin\link.exe C:\tools\msys64\usr\bin\gnu-link.exe
RunAndCheckError "C:\tools\msys64\usr\bin\bash.exe" @("-c", "pacman-key --init")
RunAndCheckError "C:\tools\msys64\usr\bin\bash.exe" @("-c", "pacman-key --populate msys2")
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
RunAndCheckError "pacman.exe" @("-S", "--noconfirm", "--needed", "git", "subversion", "diffutils", "patch", "unzip", "zip")
RunAndCheckError "pacman.exe" @("-Scc", "--noconfirm")

echo "Cleaning up unnecessary files..."
rm -Recurse -Force -ErrorAction SilentlyContinue $env:TEMP\*
# This action makes all installed components not upgradable, non-removable.
# To update Visual Studio and other installed Windows components, regenerate
# the docker image from scratch.
rm -Recurse -Force -ErrorAction SilentlyContinue "$env:ProgramData\Package Cache\*"
rm -Recurse -Force -ErrorAction SilentlyContinue "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer"
# Remove x86 tools and libraries we cannot use.
# GCP silently fails to execute 32-bit binaries and we do not expect to target x86 32 bit builds
rm -Recurse -Force -ErrorAction SilentlyContinue (ls -recurse "C:\Program Files*" -ErrorAction SilentlyContinue | where-object { $_.PSIsContainer -and $_.Name.EndsWith("x86") })
# Remove documentation we do not expect users to use
rm -Recurse -Force -ErrorAction SilentlyContinue "$env:ProgramFiles\CMake\doc"
rm -Recurse -Force -ErrorAction SilentlyContinue "$env:ProgramFiles\CMake\man"
echo "done."

echo "Finished software installation."
