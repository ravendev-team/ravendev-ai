@echo    Make FGlut32.dll from source with MinGW gcc
@echo    Created M. Yas'ko http://www.uni-koblenz.de/~yasko/g95gl
@set MinGW=c:\MinGW\
@set PATH=%MinGW%bin
@set LIBRARY_PATH=%MinGW%lib;%windir%\system32
@set OPT=-mrtd -march=pentium3 -msse
@if exist %MinGW%bin\gcc.exe goto OK
@echo MinGW in %MinGW% is not exists! Stop!
@goto END
:OK
@for %%f in (*.c) do %MinGW%bin\gcc.exe -c %%f -o %%f.o %OPT% -O3 -pipe -DTARGET_HOST_WIN32=1 -DFREEGLUT_EXPORTS=1 -ffast-math -funroll-all-loops -finline-functions -finline-limit=128 -fno-bounds-check
@ren freeglut_state.c.o 1.o
@ren freeglut_window.c.o 2.o
@ren freeglut_font_data.c.o 3.o
@ren freeglut_display.c.o 4.o
@ren freeglut_overlay.c.o 5.o
@ren freeglut_gamemode.c.o 6.o
@ren freeglut_joystick.c.o 7.o
@ren freeglut_font.c.o 8.o
@ren freeglut_glutfont_definitions.c.o 9.o
@ren freeglut_teapot.c.o 10.o
@ren freeglut_init.c.o 11.o
@ren freeglut_main.c.o 12.o
@ren freeglut_menu.c.o 13.o
@ren freeglut_stroke_roman.c.o 14.o
@ren freeglut_misc.c.o 15.o
@ren freeglut_structure.c.o 16.o
@ren freeglut_ext.c.o 17.o
@ren freeglut_stroke_mono_roman.c.o 18.o
@ren freeglut_videoresize.c.o 19.o
@ren freeglut_callbacks.c.o 20.o
@ren freeglut_cursor.c.o 21.o
@ren freeglut_geometry.c.o 22.o
@%MinGW%bin\ld.exe --dll -Lc:/MinGW/lib -L. c:/mingw/lib/dllcrt2.o 1.o 2.o 3.o 4.o 5.o 6.o 7.o 8.o 9.o 10.o 11.o 12.o 13.o 14.o 15.o 16.o 17.o 18.o 19.o 20.o 21.o 22.o -lopengl32 -lglu32 -lgdi32 -lwinmm -lmingw32 -lmoldname -lmingwex -lmsvcrt -luser32 -lkernel32 -ladvapi32 -lshell32 --enable-auto-import --enable-stdcall-fixup -s -x --gc-sections --out-implib=FGlut32.lib --output-def=FGlut32.def -O3 -o FGlut32.dll
@del *.o
:END