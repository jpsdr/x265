mkdir -p 8bit_Win32_AVX2 10bit_Win32_AVX2 12bit_Win32_AVX2

cd 12bit_Win32_AVX2
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer -mavx -mavx2 -mfma"
make ${MAKEFLAGS}
cp libx265.a ../8bit_Win32_AVX2/libx265_main12.a

cd ../10bit_Win32_AVX2
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=OFF -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer -mavx -mavx2 -mfma"
make ${MAKEFLAGS}
cp libx265.a ../8bit_Win32_AVX2/libx265_main10.a

cd ../8bit_Win32_AVX2
/G/CMakex64/bin/cmake -G "MSYS Makefiles" ../../../source -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DHIGH_BIT_DEPTH=OFF -DENABLE_HDR10_PLUS=OFF -DEXPORT_C_API=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DMAIN12=OFF -DSTATIC_LINK_CRT=ON -DENABLE_LTO=ON -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DCMAKE_CXX_FLAGS_RELEASE="-fversion-loops-for-strides -funswitch-loops -fsplit-loops -ffinite-math-only -ftree-vectorize -fivopts -ftree-loop-ivcanon -ftree-loop-if-convert -floop-parallelize-all -floop-nest-optimize -fgcse-las -fgcse-sm -fmodulo-sched-allow-regmoves -fmodulo-sched -fipa-pta -Ofast -ffast-math -fomit-frame-pointer -mavx -mavx2 -mfma"
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
