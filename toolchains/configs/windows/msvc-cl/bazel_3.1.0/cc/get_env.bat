@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\VCVARSALL.BAT" amd64  -vcvars_ver=14.25.28610 > NUL 
echo PATH=%PATH%,INCLUDE=%INCLUDE%,LIB=%LIB%,WINDOWSSDKDIR=%WINDOWSSDKDIR% 
