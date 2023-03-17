mkdir -p 10bit_mcf_Broadwell

cd 10bit_mcf_Broadwell
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DMAIN12=OFF -DSTATIC_LINK_CRT=ON -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer -mavx -mavx2 -mfma -march=broadwell -mtune=broadwell" -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ -static"
make ${MAKEFLAGS}
