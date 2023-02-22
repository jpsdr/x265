@mkdir 12bit
@mkdir 10bit
@mkdir 8bit

@cd 12bit
G:\CMakex64\bin\cmake -G "Visual Studio 16" -A x64 ../../../source -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DSTATIC_LINK_CRT=OFF -DCMAKE_CXX_FLAGS_RELEASE="/sdl- /Oi /Ot /Oy /GT /GL /GF /GS- /Gy /Qpar /arch:AVX2"

@cd ..\10bit
G:\CMakex64\bin\cmake -G "Visual Studio 16" -A x64 ../../../source -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=OFF -DSTATIC_LINK_CRT=OFF -DCMAKE_CXX_FLAGS_RELEASE="/sdl- /Oi /Ot /Oy /GT /GL /GF /GS- /Gy /Qpar /arch:AVX2"

@cd ..\8bit
G:\CMakex64\bin\cmake -G "Visual Studio 16" -A x64 ../../../source -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=OFF -DENABLE_HDR10_PLUS=OFF -DEXPORT_C_API=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DMAIN12=OFF -DSTATIC_LINK_CRT=OFF -DCMAKE_CXX_FLAGS_RELEASE="/sdl- /Oi /Ot /Oy /GT /GL /GF /GS- /Gy /Qpar /arch:AVX2" -DEXTRA_LIB="../10bit/Release/x265-static;../12bit/Release/x265-static" -DLINKED_10BIT=ON -DLINKED_12BIT=ON

pause
