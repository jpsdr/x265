/*****************************************************************************
 * Copyright (C) 2022-2023 MulticoreWare, Inc
 *
 * Authors: David Chen <david.chen@myais.com.cn>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at license @ x265.com.
 *****************************************************************************/

#include "asm-sve.S"
#include "pixel-util-common.S"

.arch armv8-a+sve2

#ifdef __APPLE__
.section __RODATA,__rodata
#else
.section .rodata
#endif

.align 4

.text

function PFX(getResidual16_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_getResidual16
    lsl             x4, x3, #1
.rept 8
    ld1             {v0.16b}, [x0], x3
    ld1             {v1.16b}, [x1], x3
    ld1             {v2.16b}, [x0], x3
    ld1             {v3.16b}, [x1], x3
    usubl           v4.8h, v0.8b, v1.8b
    usubl2          v5.8h, v0.16b, v1.16b
    usubl           v6.8h, v2.8b, v3.8b
    usubl2          v7.8h, v2.16b, v3.16b
    st1             {v4.8h-v5.8h}, [x2], x4
    st1             {v6.8h-v7.8h}, [x2], x4
.endr
    ret
.vl_gt_16_getResidual16:
    ptrue           p0.h, vl16
.rept 16
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z2.h}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    sub             z4.h, z0.h, z2.h
    st1h            {z4.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
endfunc

function PFX(getResidual32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_getResidual32
    lsl             x4, x3, #1
    mov             w12, #4
.Loop_residual_32:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v1.16b}, [x0], x3
    ld1             {v2.16b-v3.16b}, [x1], x3
    ld1             {v4.16b-v5.16b}, [x0], x3
    ld1             {v6.16b-v7.16b}, [x1], x3
    usubl           v16.8h, v0.8b, v2.8b
    usubl2          v17.8h, v0.16b, v2.16b
    usubl           v18.8h, v1.8b, v3.8b
    usubl2          v19.8h, v1.16b, v3.16b
    usubl           v20.8h, v4.8b, v6.8b
    usubl2          v21.8h, v4.16b, v6.16b
    usubl           v22.8h, v5.8b, v7.8b
    usubl2          v23.8h, v5.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x2], x4
    st1             {v20.8h-v23.8h}, [x2], x4
.endr
    cbnz            w12, .Loop_residual_32
    ret
.vl_gt_16_getResidual32:
    cmp             x9, #48
    bgt             .vl_gt_48_getResidual32
    ptrue           p0.b, vl32
.rept 32
    ld1b            {z0.b}, p0/z, [x0]
    ld1b            {z2.b}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    usublb          z4.h, z0.b, z2.b
    usublt          z5.h, z0.b, z2.b
    st2h            {z4.h, z5.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
.vl_gt_48_getResidual32:
    ptrue           p0.h, vl32
.rept 32
    ld1b            {z0.h}, p0/z, [x0]
    ld1b            {z4.h}, p0/z, [x1]
    add             x0, x0, x3
    add             x1, x1, x3
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x2]
    add             x2, x2, x3, lsl #1
.endr
    ret
endfunc

function PFX(pixel_sub_ps_32x32_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_32x32
    lsl             x1, x1, #1
    mov             w12, #4
.Loop_sub_ps_32_sve2:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v1.16b}, [x2], x4
    ld1             {v2.16b-v3.16b}, [x3], x5
    ld1             {v4.16b-v5.16b}, [x2], x4
    ld1             {v6.16b-v7.16b}, [x3], x5
    usubl           v16.8h, v0.8b, v2.8b
    usubl2          v17.8h, v0.16b, v2.16b
    usubl           v18.8h, v1.8b, v3.8b
    usubl2          v19.8h, v1.16b, v3.16b
    usubl           v20.8h, v4.8b, v6.8b
    usubl2          v21.8h, v4.16b, v6.16b
    usubl           v22.8h, v5.8b, v7.8b
    usubl2          v23.8h, v5.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x0], x1
    st1             {v20.8h-v23.8h}, [x0], x1
.endr
    cbnz            w12, .Loop_sub_ps_32_sve2
    ret
.vl_gt_16_pixel_sub_ps_32x32:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sub_ps_32x32
    ptrue           p0.b, vl32
    mov             w12, #8
.vl_gt_16_loop_sub_ps_32_sve2:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z2.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z2.b
    usublt          z17.h, z0.b, z2.b
    st2h            {z16.h, z17.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    cbnz            w12, .vl_gt_16_loop_sub_ps_32_sve2
    ret
.vl_gt_48_pixel_sub_ps_32x32:
    ptrue           p0.h, vl32
    mov             w12, #8
.vl_gt_48_loop_sub_ps_32_sve2:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z4.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    cbnz            w12, .vl_gt_48_loop_sub_ps_32_sve2
    ret
endfunc

function PFX(pixel_sub_ps_64x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_64x64
    lsl             x1, x1, #1
    sub             x1, x1, #64
    mov             w12, #16
.Loop_sub_ps_64_sve2:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v3.16b}, [x2], x4
    ld1             {v4.16b-v7.16b}, [x3], x5
    usubl           v16.8h, v0.8b, v4.8b
    usubl2          v17.8h, v0.16b, v4.16b
    usubl           v18.8h, v1.8b, v5.8b
    usubl2          v19.8h, v1.16b, v5.16b
    usubl           v20.8h, v2.8b, v6.8b
    usubl2          v21.8h, v2.16b, v6.16b
    usubl           v22.8h, v3.8b, v7.8b
    usubl2          v23.8h, v3.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x0], #64
    st1             {v20.8h-v23.8h}, [x0], x1
.endr
    cbnz            w12, .Loop_sub_ps_64_sve2
    ret
.vl_gt_16_pixel_sub_ps_64x64:
    rdvl            x9, #1
    cmp             x9, #32
    bgt             .vl_gt_48_pixel_sub_ps_64x64
    ptrue           p0.b, vl32
    mov             w12, #16
.vl_gt_16_loop_sub_ps_64_sve2:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z1.b}, p0/z, [x2, #1, mul vl]
    ld1b            {z4.b}, p0/z, [x3]
    ld1b            {z5.b}, p0/z, [x3, #1, mul vl]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z4.b
    usublt          z17.h, z0.b, z4.b
    usublb          z18.h, z1.b, z5.b
    usublt          z19.h, z1.b, z5.b
    st2h            {z16.h, z17.h}, p0, [x0]
    st2h            {z18.h, z19.h}, p0, [x0, #2, mul vl]
    add             x0, x0, x1, lsl #1
.endr
    cbnz            w12, .vl_gt_16_loop_sub_ps_64_sve2
    ret
.vl_gt_48_pixel_sub_ps_64x64:
    cmp             x9, #112
    bgt             .vl_gt_112_pixel_sub_ps_64x64
    ptrue           p0.b, vl64
    mov             w12, #16
.vl_gt_48_loop_sub_ps_64_sve2:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z4.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z4.b
    usublt          z17.h, z0.b, z4.b
    st2h            {z16.h, z17.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    cbnz            w12, .vl_gt_48_loop_sub_ps_64_sve2
    ret
.vl_gt_112_pixel_sub_ps_64x64:
    ptrue           p0.h, vl64
    mov             w12, #16
.vl_gt_112_loop_sub_ps_64_sve2:
    sub             w12, w12, #1
.rept 4
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z8.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z16.h, z0.h, z8.h
    st1h            {z16.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    cbnz            w12, .vl_gt_112_loop_sub_ps_64_sve2
    ret
endfunc

function PFX(pixel_sub_ps_32x64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_pixel_sub_ps_32x64
    lsl             x1, x1, #1
    mov             w12, #8
.Loop_sub_ps_32x64_sve2:
    sub             w12, w12, #1
.rept 4
    ld1             {v0.16b-v1.16b}, [x2], x4
    ld1             {v2.16b-v3.16b}, [x3], x5
    ld1             {v4.16b-v5.16b}, [x2], x4
    ld1             {v6.16b-v7.16b}, [x3], x5
    usubl           v16.8h, v0.8b, v2.8b
    usubl2          v17.8h, v0.16b, v2.16b
    usubl           v18.8h, v1.8b, v3.8b
    usubl2          v19.8h, v1.16b, v3.16b
    usubl           v20.8h, v4.8b, v6.8b
    usubl2          v21.8h, v4.16b, v6.16b
    usubl           v22.8h, v5.8b, v7.8b
    usubl2          v23.8h, v5.16b, v7.16b
    st1             {v16.8h-v19.8h}, [x0], x1
    st1             {v20.8h-v23.8h}, [x0], x1
.endr
    cbnz            w12, .Loop_sub_ps_32x64_sve2
    ret
.vl_gt_16_pixel_sub_ps_32x64:
    cmp             x9, #48
    bgt             .vl_gt_48_pixel_sub_ps_32x64
    ptrue           p0.b, vl32
    mov             w12, #8
.vl_gt_16_loop_sub_ps_32x64_sve2:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.b}, p0/z, [x2]
    ld1b            {z2.b}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    usublb          z16.h, z0.b, z2.b
    usublt          z17.h, z0.b, z2.b
    st2h            {z16.h, z17.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    cbnz            w12, .vl_gt_16_loop_sub_ps_32x64_sve2
    ret
.vl_gt_48_pixel_sub_ps_32x64:
    ptrue           p0.h, vl32
    mov             w12, #8
.vl_gt_48_loop_sub_ps_32x64_sve2:
    sub             w12, w12, #1
.rept 8
    ld1b            {z0.h}, p0/z, [x2]
    ld1b            {z4.h}, p0/z, [x3]
    add             x2, x2, x4
    add             x3, x3, x5
    sub             z8.h, z0.h, z4.h
    st1h            {z8.h}, p0, [x0]
    add             x0, x0, x1, lsl #1
.endr
    cbnz            w12, .vl_gt_48_loop_sub_ps_32x64_sve2
    ret
endfunc

// void scale1D_128to64(pixel *dst, const pixel *src)
function PFX(scale1D_128to64_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_scale1D_128to64
    ptrue           p0.b, vl16
.rept 2
    ld2b            {z0.b, z1.b}, p0/z, [x1]
    ld2b            {z2.b, z3.b}, p0/z, [x1, #2, mul vl]
    ld2b            {z4.b, z5.b}, p0/z, [x1, #4, mul vl]
    ld2b            {z6.b, z7.b}, p0/z, [x1, #6, mul vl]
    add             x1, x1, #128
    urhadd          z0.b, p0/m, z0.b, z1.b
    urhadd          z2.b, p0/m, z2.b, z3.b
    urhadd          z4.b, p0/m, z4.b, z5.b
    urhadd          z6.b, p0/m, z6.b, z7.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z2.b}, p0, [x0, #1, mul vl]
    st1b            {z4.b}, p0, [x0, #2, mul vl]
    st1b            {z6.b}, p0, [x0, #3, mul vl]
    add             x0, x0, #64
.endr
    ret
.vl_gt_16_scale1D_128to64:
    cmp             x9, #48
    bgt             .vl_gt_48_scale1D_128to64
    ptrue           p0.b, vl32
.rept 2
    ld2b            {z0.b, z1.b}, p0/z, [x1]
    ld2b            {z2.b, z3.b}, p0/z, [x1, #2, mul vl]
    add             x1, x1, #128
    urhadd          z0.b, p0/m, z0.b, z1.b
    urhadd          z2.b, p0/m, z2.b, z3.b
    st1b            {z0.b}, p0, [x0]
    st1b            {z2.b}, p0, [x0, #1, mul vl]
    add             x0, x0, #64
.endr
    ret
.vl_gt_48_scale1D_128to64:
    ptrue           p0.b, vl64
.rept 2
    ld2b            {z0.b, z1.b}, p0/z, [x1]
    add             x1, x1, #128
    urhadd          z0.b, p0/m, z0.b, z1.b
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, #64
.endr
    ret
endfunc

// void dequant_normal_c(const int16_t* quantCoef, int16_t* coef, int num, int scale, int shift)
function PFX(dequant_normal_sve2)
//  X265_CHECK(num >= 4 * 4, "dequant num %d too small\n", num);
//  X265_CHECK(num <= 32 * 32, "dequant num %d too large\n", num);
//  X265_CHECK((num % 16) == 0, "dequant num %d not multiple of 16\n", num);
#if HIGH_BIT_DEPTH
    cmp             w3, #32768
    blt             .dqn_skip
    lsr             w3, w3, #(BIT_DEPTH - 8)
    sub             w4, w4, #(BIT_DEPTH - 8)
.dqn_skip:
#endif
    neg             w4, w4
    mov             z0.h, w3
    mov             z1.s, w4
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_dequant_normal_sve2
.dqn_loop1_sve2:
    ld1             {v2.8h, v3.8h}, [x0], #32
    smull           v16.4s, v2.4h, v0.4h
    smull2          v17.4s, v2.8h, v0.8h
    smull           v18.4s, v3.4h, v0.4h
    smull2          v19.4s, v3.8h, v0.8h

    srshl           v16.4s, v16.4s, v1.4s
    srshl           v17.4s, v17.4s, v1.4s
    srshl           v18.4s, v18.4s, v1.4s
    srshl           v19.4s, v19.4s, v1.4s

    sqxtn           v2.4h, v16.4s
    sqxtn2          v2.8h, v17.4s
    sqxtn           v3.4h, v18.4s
    sqxtn2          v3.8h, v19.4s

    sub             w2, w2, #16
    st1             {v2.8h, v3.8h}, [x1], #32
    cbnz            w2, .dqn_loop1_sve2
    ret
.vl_gt_16_dequant_normal_sve2:
    ptrue           p0.h, vl16
.gt_16_dqn_loop1_sve2:
    ld1h            {z2.h}, p0/z, [x0]
    add             x0, x0, #32
    smullb          z16.s, z2.h, z0.h
    smullt          z17.s, z2.h, z0.h

    srshl           z16.s, p0/m, z16.s, z1.s
    srshl           z17.s, p0/m, z17.s, z1.s

    sqxtnb          z2.h, z16.s
    sqxtnt          z2.h, z17.s

    sub             w2, w2, #16
    st1h            {z2.h}, p0, [x1]
    add             x1, x1, #32
    cbnz            w2, .gt_16_dqn_loop1_sve2
    ret

endfunc

// void ssim_4x4x2_core(const pixel* pix1, intptr_t stride1, const pixel* pix2, intptr_t stride2, int sums[2][4])
function PFX(ssim_4x4x2_core_sve2)
    ptrue           p0.b, vl16
    movi            v30.2d, #0
    movi            v31.2d, #0

    ld1b            {z0.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z1.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z2.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z3.h}, p0/z, [x0]
    add             x0, x0, x1

    ld1b            {z4.h}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z5.h}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z6.h}, p0/z, [x2]
    add             x2, x2, x3
    ld1b            {z7.h}, p0/z, [x2]
    add             x2, x2, x3

    mul             z16.h, z0.h, z0.h
    mul             z17.h, z1.h, z1.h
    mul             z18.h, z2.h, z2.h
    uaddlp          v30.4s, v16.8h

    mul             z19.h, z3.h, z3.h
    mul             z20.h, z4.h, z4.h
    mul             z21.h, z5.h, z5.h
    uadalp          v30.4s, v17.8h

    mul             z22.h, z6.h, z6.h
    mul             z23.h, z7.h, z7.h
    mul             z24.h, z0.h, z4.h
    uadalp          v30.4s, v18.8h

    mul             z25.h, z1.h, z5.h
    mul             z26.h, z2.h, z6.h
    mul             z27.h, z3.h, z7.h
    uadalp          v30.4s, v19.8h

    add             z28.h, z0.h, z1.h
    add             z29.h, z4.h, z5.h
    uadalp          v30.4s, v20.8h
    uaddlp          v31.4s, v24.8h

    add             z28.h, z28.h, z2.h
    add             z29.h, z29.h, z6.h
    uadalp          v30.4s, v21.8h
    uadalp          v31.4s, v25.8h

    add             z28.h, z28.h, z3.h
    add             z29.h, z29.h, z7.h
    uadalp          v30.4s, v22.8h
    uadalp          v31.4s, v26.8h

    // Better use NEON instructions here
    uaddlp          v28.4s, v28.8h
    uaddlp          v29.4s, v29.8h
    uadalp          v30.4s, v23.8h
    uadalp          v31.4s, v27.8h

    addp            v28.4s, v28.4s, v28.4s
    addp            v29.4s, v29.4s, v29.4s
    addp            v30.4s, v30.4s, v30.4s
    addp            v31.4s, v31.4s, v31.4s

    st4             {v28.2s, v29.2s, v30.2s, v31.2s}, [x4]
    ret
endfunc

// void ssimDist_c(const pixel* fenc, uint32_t fStride, const pixel* recon, intptr_t rstride, uint64_t *ssBlock, int shift, uint64_t *ac_k)
.macro ssimDist_start_sve2
    mov             z0.d, #0
    mov             z1.d, #0
.endm

.macro ssimDist_1_sve2  z0 z1 z2 z3
    sub             z16.s, \z0\().s, \z2\().s
    sub             z17.s, \z1\().s, \z3\().s
    mul             z18.s, \z0\().s, \z0\().s
    mul             z19.s, \z1\().s, \z1\().s
    mul             z20.s, z16.s, z16.s
    mul             z21.s, z17.s, z17.s
    add             z0.s, z0.s, z18.s
    add             z0.s, z0.s, z19.s
    add             z1.s, z1.s, z20.s
    add             z1.s, z1.s, z21.s
.endm

.macro ssimDist_end_sve2
    uaddv           d0, p0, z0.s
    uaddv           d1, p0, z1.s
    str             d0, [x6]
    str             d1, [x4]
.endm

function PFX(ssimDist4_sve2)
    ssimDist_start
    ptrue           p0.s, vl4
.rept 4
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z5.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z2.s, z4.s, z5.s
    mul             z3.s, z4.s, z4.s
    mul             z2.s, z2.s, z2.s
    add             z0.s, z0.s, z3.s
    add             z1.s, z1.s, z2.s
.endr
    ssimDist_end
    ret
endfunc

function PFX(ssimDist8_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist8
    ssimDist_start
    ptrue           p0.s, vl4
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    ld1b            {z6.s}, p0/z, [x2]
    ld1b            {z7.s}, p0/z, [x2, #1, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z4, z5, z6, z7
.endr
    ssimDist_end
    ret
.vl_gt_16_ssimDist8:
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z6.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z20.s, z4.s, z6.s
    mul             z16.s, z4.s, z4.s
    mul             z18.s, z20.s, z20.s
    add             z0.s, z0.s, z16.s
    add             z1.s, z1.s, z18.s
.endr
    ssimDist_end_sve2
    ret
endfunc

function PFX(ssimDist16_sve2)
    mov             w12, #16
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist16
    ssimDist_start
    ptrue           p0.s, vl4
.Loop_ssimDist16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    ld1b            {z8.s}, p0/z, [x2]
    ld1b            {z9.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z10.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z11.s}, p0/z, [x2, #3, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z4, z5, z8, z9
    ssimDist_1_sve2 z6, z7, z10, z11
    cbnz            w12, .Loop_ssimDist16_sve2
    ssimDist_end
    ret
.vl_gt_16_ssimDist16:
    cmp             x9, #48
    bgt             .vl_gt_48_ssimDist16
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_ssimDist16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    ld1b            {z8.s}, p0/z, [x2]
    ld1b            {z9.s}, p0/z, [x2, #1, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z4, z5, z8, z9
    cbnz            w12, .vl_gt_16_loop_ssimDist16_sve2
    ssimDist_end_sve2
    ret
.vl_gt_48_ssimDist16:
    ssimDist_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_ssimDist16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z8.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z20.s, z4.s, z8.s
    mul             z16.s, z4.s, z4.s
    mul             z18.s, z20.s, z20.s
    add             z0.s, z0.s, z16.s
    add             z1.s, z1.s, z18.s
    cbnz            w12, .vl_gt_48_loop_ssimDist16_sve2
    ssimDist_end_sve2
    ret
endfunc

function PFX(ssimDist32_sve2)
    mov             w12, #32
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist32
    ssimDist_start
    ptrue           p0.s, vl4
.Loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #7, mul vl]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    ld1b            {z11.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z12.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z13.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z14.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z15.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z30.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z31.s}, p0/z, [x2, #7, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z2, z3, z10, z11
    ssimDist_1_sve2 z4, z5, z12, z13
    ssimDist_1_sve2 z6, z7, z14, z15
    ssimDist_1_sve2 z8, z9, z30, z31
    cbnz            w12, .Loop_ssimDist32_sve2
    ssimDist_end
    ret
.vl_gt_16_ssimDist32:
    cmp             x9, #48
    bgt             .vl_gt_48_ssimDist32
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    ld1b            {z11.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z12.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z13.s}, p0/z, [x2, #3, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z2, z3, z10, z11
    ssimDist_1_sve2 z4, z5, z12, z13
    cbnz            w12, .vl_gt_16_loop_ssimDist32_sve2
    ssimDist_end_sve2
    ret
.vl_gt_48_ssimDist32:
    cmp             x9, #112
    bgt             .vl_gt_112_ssimDist32
    ssimDist_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    ld1b            {z11.s}, p0/z, [x2, #1, mul vl]
    add             x2, x2, x3
    ssimDist_1_sve2 z2, z3, z10, z11
    cbnz            w12, .vl_gt_48_loop_ssimDist32_sve2
    ssimDist_end_sve2
    ret
.vl_gt_112_ssimDist32:
    ssimDist_start_sve2
    ptrue           p0.s, vl32
.vl_gt_112_loop_ssimDist32_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z10.s}, p0/z, [x2]
    add             x2, x2, x3
    sub             z20.s, z2.s, z10.s
    mul             z16.s, z2.s, z2.s
    mul             z18.s, z20.s, z20.s
    add             z0.s, z0.s, z16.s
    add             z1.s, z1.s, z18.s
    cbnz            w12, .vl_gt_112_loop_ssimDist32_sve2
    ssimDist_end_sve2
    ret
endfunc

function PFX(ssimDist64_sve2)
    mov             w12, #64
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_ssimDist64
    ssimDist_start
    ptrue           p0.s, vl4
.Loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #7, mul vl]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z27.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z28.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z29.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z30.s}, p0/z, [x2, #7, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    ssimDist_1_sve2 z6, z7, z27, z28
    ssimDist_1_sve2 z8, z9, z29, z30
    mov             x4, x0
    mov             x5, x2
    add             x4, x4, #32
    add             x5, x5, #32
    ld1b            {z2.s}, p0/z, [x4]
    ld1b            {z3.s}, p0/z, [x4, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x4, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x4, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x4, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x4, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x4, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x4, #7, mul vl]
    ld1b            {z23.s}, p0/z, [x5]
    ld1b            {z24.s}, p0/z, [x5, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x5, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x5, #3, mul vl]
    ld1b            {z27.s}, p0/z, [x5, #4, mul vl]
    ld1b            {z28.s}, p0/z, [x5, #5, mul vl]
    ld1b            {z29.s}, p0/z, [x5, #6, mul vl]
    ld1b            {z30.s}, p0/z, [x5, #7, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    ssimDist_1_sve2 z6, z7, z27, z28
    ssimDist_1_sve2 z8, z9, z29, z30
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .Loop_ssimDist64_sve2
    ssimDist_end
    ret
.vl_gt_16_ssimDist64:
    cmp             x9, #48
    bgt             .vl_gt_48_ssimDist64
    ssimDist_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #7, mul vl]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z27.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z28.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z29.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z30.s}, p0/z, [x2, #7, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    ssimDist_1_sve2 z6, z7, z27, z28
    ssimDist_1_sve2 z8, z9, z29, z30
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .vl_gt_16_loop_ssimDist64_sve2
    ssimDist_end_sve2
    ret
.vl_gt_48_ssimDist64:
    cmp             x9, #112
    bgt             .vl_gt_112_ssimDist64
    ssimDist_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z4.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z5.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z25.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z26.s}, p0/z, [x2, #3, mul vl]
    ssimDist_1_sve2 z2, z3, z23, z24
    ssimDist_1_sve2 z4, z5, z25, z26
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .vl_gt_48_loop_ssimDist64_sve2
    ssimDist_end_sve2
    ret
.vl_gt_112_ssimDist64:
    ssimDist_start_sve2
    ptrue           p0.s, vl32
    mov             x5, #32
.vl_gt_112_loop_ssimDist64_sve2:
    sub             w12, w12, #1
    ld1b            {z2.s}, p0/z, [x0]
    ld1b            {z3.s}, p0/z, [x0, x5]
    ld1b            {z23.s}, p0/z, [x2]
    ld1b            {z24.s}, p0/z, [x2, x5]
    ssimDist_1_sve2 z2, z3, z23, z24
    add             x0, x0, x1
    add             x2, x2, x3
    cbnz            w12, .vl_gt_112_loop_ssimDist64_sve2
    ssimDist_end_sve2
    ret
endfunc

// void normFact_c(const pixel* src, uint32_t blockSize, int shift, uint64_t *z_k)
.macro normFact_start_sve2
    mov             z0.d, #0
.endm

.macro normFact_1_sve2  z0, z1
    mul             z16.s, \z0\().s, \z0\().s
    mul             z17.s, \z1\().s, \z1\().s
    add             z0.s, z0.s, z16.s
    add             z0.s, z0.s, z17.s
.endm

.macro normFact_end_sve2
    uaddv           d0, p0, z0.s
    str             d0, [x3]
.endm

function PFX(normFact8_sve2)
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_normFact8
    normFact_start
    ptrue           p0.s, vl4
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
.endr
    normFact_end
    ret
.vl_gt_16_normFact8:
    normFact_start_sve2
    ptrue           p0.s, vl8
.rept 8
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    mul             z16.s, z4.s, z4.s
    add             z0.s, z0.s, z16.s
.endr
    normFact_end_sve2
    ret
endfunc

function PFX(normFact16_sve2)
    mov             w12, #16
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_normFact16
    normFact_start
    ptrue           p0.s, vl4
.Loop_normFact16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    cbnz            w12, .Loop_normFact16_sve2
    normFact_end
    ret
.vl_gt_16_normFact16:
    cmp             x9, #48
    bgt             .vl_gt_48_normFact16
    normFact_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_normFact16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    cbnz            w12, .vl_gt_16_loop_normFact16_sve2
    normFact_end_sve2
    ret
.vl_gt_48_normFact16:
    normFact_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_normFact16_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    mul             z16.s, z4.s, z4.s
    add             z0.s, z0.s, z16.s
    cbnz            w12, .vl_gt_48_loop_normFact16_sve2
    normFact_end_sve2
    ret
endfunc

function PFX(normFact32_sve2)
    mov             w12, #32
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_normFact32
    normFact_start
    ptrue           p0.s, vl4
.Loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x0, #7, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    cbnz            w12, .Loop_normFact32_sve2
    normFact_end
    ret
.vl_gt_16_normFact32:
    cmp             x9, #48
    bgt             .vl_gt_48_normFact32
    normFact_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    cbnz            w12, .vl_gt_16_loop_normFact32_sve2
    normFact_end_sve2
    ret
.vl_gt_48_normFact32:
    cmp             x9, #112
    bgt             .vl_gt_112_normFact32
    normFact_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    add             x0, x0, x1
    normFact_1_sve2 z4, z5
    cbnz            w12, .vl_gt_48_loop_normFact32_sve2
    normFact_end_sve2
    ret
.vl_gt_112_normFact32:
    normFact_start_sve2
    ptrue           p0.s, vl32
.vl_gt_112_loop_normFact32_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    add             x0, x0, x1
    mul             z16.s, z4.s, z4.s
    add             z0.s, z0.s, z16.s
    cbnz            w12, .vl_gt_112_loop_normFact32_sve2
    normFact_end_sve2
    ret
endfunc

function PFX(normFact64_sve2)
    mov             w12, #64
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_normFact64
    normFact_start
    ptrue           p0.s, vl4
.Loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x0, #7, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    mov             x2, x0
    add             x2, x2, #32
    ld1b            {z4.s}, p0/z, [x2]
    ld1b            {z5.s}, p0/z, [x2, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x2, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x2, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x2, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x2, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x2, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x2, #7, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    add             x0, x0, x1
    cbnz            w12, .Loop_normFact64_sve2
    normFact_end
    ret
.vl_gt_16_normFact64:
    cmp             x9, #48
    bgt             .vl_gt_48_normFact64
    normFact_start_sve2
    ptrue           p0.s, vl8
.vl_gt_16_loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    ld1b            {z8.s}, p0/z, [x0, #4, mul vl]
    ld1b            {z9.s}, p0/z, [x0, #5, mul vl]
    ld1b            {z10.s}, p0/z, [x0, #6, mul vl]
    ld1b            {z11.s}, p0/z, [x0, #7, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    normFact_1_sve2 z8, z9
    normFact_1_sve2 z10, z11
    add             x0, x0, x1
    cbnz            w12, .vl_gt_16_loop_normFact64_sve2
    normFact_end_sve2
    ret
.vl_gt_48_normFact64:
    cmp             x9, #112
    bgt             .vl_gt_112_normFact64
    normFact_start_sve2
    ptrue           p0.s, vl16
.vl_gt_48_loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, #1, mul vl]
    ld1b            {z6.s}, p0/z, [x0, #2, mul vl]
    ld1b            {z7.s}, p0/z, [x0, #3, mul vl]
    normFact_1_sve2 z4, z5
    normFact_1_sve2 z6, z7
    add             x0, x0, x1
    cbnz            w12, .vl_gt_48_loop_normFact64_sve2
    normFact_end_sve2
    ret
.vl_gt_112_normFact64:
    normFact_start_sve2
    ptrue           p0.s, vl32
    mov             x4, #32
.vl_gt_112_loop_normFact64_sve2:
    sub             w12, w12, #1
    ld1b            {z4.s}, p0/z, [x0]
    ld1b            {z5.s}, p0/z, [x0, x4]
    normFact_1_sve2 z4, z5
    add             x0, x0, x1
    cbnz            w12, .vl_gt_112_loop_normFact64_sve2
    normFact_end_sve2
    ret
endfunc
