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
                 https://github.com/bazelbuild/bazelisk/releases/download/v1.5.0/bazelisk-windows-amd64.exe `
                 67149e87d51eb2b34d8b22ee0aa4ae63550919d3f2792f863eaabf9e78826a60
AddToPath C:\tools\bazel

# VS 2019 Build Tools
# Pinned to version 16.7 downloaded on 8/11/2020 via https://aka.ms/vs/16/release/vs_buildtools.exe
DownloadAndCheck $env:TEMP\vs_buildtools.exe `
                 https://download.visualstudio.microsoft.com/download/pr/e3850c73-59c6-4c05-9db6-a47a74b67daf/dcb113a854b2cb2141755b6a35c4b9aac6f109081bee45649ec2fcc594b0d7a6/vs_BuildTools.exe `
                 dcb113a854b2cb2141755b6a35c4b9aac6f109081bee45649ec2fcc594b0d7a6
# See: https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019#c-build-tools
# The "Microsoft.VisualStudio.Workload.MSBuildTools" and it's components are added
# by the installer and cannot be supressed.
echo @"
{
  "version": "1.0",
  "components": [
    "Microsoft.VisualStudio.Workload.VCTools",
    "Microsoft.VisualStudio.Component.Windows10SDK.18362",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
  ]
}
"@ > $env:TEMP\vs_buildtools_config
RunAndCheckError "cmd.exe" @("/s", "/c", "$env:TEMP\vs_buildtools.exe --addProductLang en-US --quiet --wait --norestart --nocache --config $env:TEMP\vs_buildtools_config")
AddToPath (Resolve-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\x64").Path

# CMake to ensure a 64-bit build of the tool (VS BuildTools ships a 32-bit build)
DownloadAndCheck $env:TEMP\cmake.msi `
                 https://github.com/Kitware/CMake/releases/download/v3.18.0/cmake-3.18.0-win64-x64.msi `
                 1597eef91b39fe4b34bab506158e34aa3a89490c519c97ac75a7c5d45885e345
RunAndCheckError "msiexec.exe" @("/i", "$env:TEMP\cmake.msi", "/quiet", "/norestart") $true
AddToPath $env:ProgramFiles\CMake\bin

# Ninja to ensure a 64-bit build of the tool (VS BuildTools ships a 32-bit build)
mkdir -Force C:\tools\ninja
DownloadAndCheck $env:TEMP\ninja.zip `
                 https://github.com/ninja-build/ninja/releases/download/v1.10.0/ninja-win.zip `
                 919fd158c16bf135e8a850bb4046ec1ce28a7439ee08b977cd0b7f6b3463d178
Expand-Archive -Path $env:TEMP\ninja.zip -DestinationPath C:\tools\ninja
AddToPath C:\tools\ninja

# LLVM to ensure a 64-bit build of the tool (VS BuildTools ships a 32-bit build)
DownloadAndCheck $env:TEMP\LLVM-win64.exe `
                 https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/LLVM-10.0.0-win64.exe `
                 893f8a12506f8ad29ca464d868fb432fdadd782786a10655b86575fc7fc1a562
RunAndCheckError $env:TEMP\LLVM-win64.exe @("/S") $true
AddToPath $env:ProgramFiles\LLVM\bin

# NASM (preferred by some OSS projects over MS ml.exe, closer to gnu/intel syntax)
$nasmVersion = "2.15.03"
DownloadAndCheck $env:TEMP\nasm-win64.zip `
                 https://www.nasm.us/pub/nasm/releasebuilds/$nasmVersion/win64/nasm-$nasmVersion-win64.zip `
                 e598d1a9c98345f8436750f42d1f7c5d75ba739919eef37cd9ae8406e6a38802
Expand-Archive -Path $env:TEMP\nasm-win64.zip -DestinationPath C:\tools\
AddToPath C:\tools\nasm-$nasmVersion

# Python3 (do not install via msys2 or the MS store's flavors, this version follows Win32 semantics)
DownloadAndCheck $env:TEMP\python3-installer.exe `
                 https://www.python.org/ftp/python/3.8.5/python-3.8.5-amd64.exe `
                 cd427c7b17337d7c13761ca20877d2d8be661bd30415ddc17072a31a65a91b64
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

# 7z only to unpack msys2
DownloadAndCheck $env:TEMP\7z-installer.exe `
                 https://www.7-zip.org/a/7z1900-x64.exe `
                 0f5d4dbbe5e55b7aa31b91e5925ed901fdf46a367491d81381846f05ad54c45e
$quo = '"'
RunAndCheckError "$env:TEMP\7z-installer.exe" @("/S", "/D=$quo$env:TEMP\7z$quo")

# msys2 with additional required packages
DownloadAndCheck $env:TEMP\msys2.tar.xz `
                 http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20200720.tar.xz `
                 24f0a7a3f499d9309bb55bcde5d34a08e752922c3bee9de3a33d2c40896a1496
RunAndCheckError "$env:TEMP\7z\7z.exe" @("x", "$env:TEMP\msys2.tar.xz", "-o$env:TEMP\msys2.tar", "-y")
RunAndCheckError "$env:TEMP\7z\7z.exe" @("x", "$env:TEMP\msys2.tar", "-oC:\tools", "-y")
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
