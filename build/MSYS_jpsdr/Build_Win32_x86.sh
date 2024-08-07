mkdir -p 8bit_Win32_x86 8bit_Win32_x86_noasm

cd 8bit_Win32_x86
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_MULTIVIEW=ON -DENABLE_ALPHA=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=OFF -DENABLE_HDR10_PLUS=OFF -DEXPORT_C_API=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DMAIN12=OFF -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer"
make ${MAKEFLAGS}

cd ../8bit_Win32_x86_noasm
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_MULTIVIEW=ON -DENABLE_ALPHA=ON -DENABLE_ASSEMBLY=OFF -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=OFF -DENABLE_HDR10_PLUS=OFF -DEXPORT_C_API=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DMAIN12=OFF -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer"
make ${MAKEFLAGS}
