REM g95 use opengl library

g95.exe -mrtd -fno-underscoring %1.f90 -o %1 -Wl,%windir%/system32/opengl32.dll,%windir%/system32/glu32.dll,fglut32.dll