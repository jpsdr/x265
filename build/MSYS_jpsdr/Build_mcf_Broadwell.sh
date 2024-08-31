mkdir -p 8bit_mcf_Broadwell 10bit_mcf_Broadwell 12bit_mcf_Broadwell

cd 12bit_mcf_Broadwell
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_LIBVMAF=ON -DENABLE_SCC_EXT=ON -DENABLE_MULTIVIEW=ON -DENABLE_ALPHA=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer -mavx -mavx2 -mfma -march=broadwell -mtune=broadwell"
make ${MAKEFLAGS}
cp libx265.a ../8bit_mcf_Broadwell/libx265_main12.a

cd ../10bit_mcf_Broadwell
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_LIBVMAF=ON -DENABLE_SCC_EXT=ON -DENABLE_MULTIVIEW=ON -DENABLE_ALPHA=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=OFF -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer -mavx -mavx2 -mfma -march=broadwell -mtune=broadwell"
make ${MAKEFLAGS}
cp libx265.a ../8bit_mcf_Broadwell/libx265_main10.a

cd ../8bit_mcf_Broadwell
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_LIBVMAF=ON -DENABLE_SCC_EXT=ON -DENABLE_MULTIVIEW=ON -DENABLE_ALPHA=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=OFF -DENABLE_HDR10_PLUS=OFF -DEXPORT_C_API=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DMAIN12=OFF -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer -mavx -mavx2 -mfma -march=broadwell -mtune=broadwell" -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ -static -lmcfgthread"
make ${MAKEFLAGS}

# rename the 8bit library, then combine all three into libx265.a using GNU ar
mv libx265.a libx265_main.a

ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
