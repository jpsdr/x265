/*****************************************************************************
 * Copyright (C) 2024 MulticoreWare, Inc
 *
 * Authors: Hari Limaye <hari.limaye@arm.com>
 *          Jonathan Wright <jonathan.wright@arm.com>
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

#include "dct-prim.h"
#include "neon-sve-bridge.h"
#include <arm_neon.h>


namespace
{
using namespace X265_NS;

// First four elements (duplicated) of rows 1, 3, 5 and 7 in g_t8 (8x8 DCT
// matrix.)
const int16_t t8_odd[4][8] =
{
    { 89,  75,  50,  18, 89,  75,  50,  18 },
    { 75, -18, -89, -50, 75, -18, -89, -50 },
    { 50, -89,  18,  75, 50, -89,  18,  75 },
    { 18, -50,  75, -89, 18, -50,  75, -89 },
};

const int16_t t16_eo_s16[16] =
{
    89,  75,  50,  18,  75, -18, -89, -50,
    50, -89,  18,  75,  18, -50,  75, -89
};

const int32_t t16_eo_s32[16] =
{
    89,  75,  50,  18,  75, -18, -89, -50,
    50, -89,  18,  75,  18, -50,  75, -89
};

template<int shift>
static inline void partialButterfly8_sve(const int16_t *src, int16_t *dst)
{
    const int line = 8;

    int16x8_t O[line / 2];
    int32x4_t EE[line / 2];
    int32x4_t EO[line / 2];

    for (int i = 0; i < line; i += 2)
    {
        int16x8_t s_lo = vcombine_s16(vld1_s16(src + i * line),
                                      vld1_s16(src + (i + 1) * line));
        int16x8_t s_hi = vcombine_s16(
            vrev64_s16(vld1_s16(src + i * line + 4)),
            vrev64_s16(vld1_s16(src + (i + 1) * line + 4)));

        int32x4_t E0 = vaddl_s16(vget_low_s16(s_lo), vget_low_s16(s_hi));
        int32x4_t E1 = vaddl_s16(vget_high_s16(s_lo), vget_high_s16(s_hi));

        O[i / 2] = vsubq_s16(s_lo, s_hi);

        int32x4_t t0 = vreinterpretq_s32_s64(
            vzip1q_s64(vreinterpretq_s64_s32(E0), vreinterpretq_s64_s32(E1)));
        int32x4_t t1 = vrev64q_s32(vreinterpretq_s32_s64(
            vzip2q_s64(vreinterpretq_s64_s32(E0), vreinterpretq_s64_s32(E1))));

        EE[i / 2] = vaddq_s32(t0, t1);
        EO[i / 2] = vsubq_s32(t0, t1);
    }

    int16_t *d = dst;

    int32x4_t c0 = vld1q_s32(t8_even[0]);
    int32x4_t c2 = vld1q_s32(t8_even[1]);
    int32x4_t c4 = vld1q_s32(t8_even[2]);
    int32x4_t c6 = vld1q_s32(t8_even[3]);
    int16x8_t c1 = vld1q_s16(t8_odd[0]);
    int16x8_t c3 = vld1q_s16(t8_odd[1]);
    int16x8_t c5 = vld1q_s16(t8_odd[2]);
    int16x8_t c7 = vld1q_s16(t8_odd[3]);

    for (int j = 0; j < line; j += 4)
    {
        // O
        int64x2_t t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c1);
        int64x2_t t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c1);
        int32x4_t t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res1 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 1 * line, res1);

        t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c3);
        t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c3);
        t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res3 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 3 * line, res3);

        t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c5);
        t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c5);
        t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res5 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 5 * line, res5);

        t01 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 0], c7);
        t23 = x265_sdotq_s16(vdupq_n_s64(0), O[j / 2 + 1], c7);
        t0123 = vcombine_s32(vmovn_s64(t01), vmovn_s64(t23));
        int16x4_t res7 = vrshrn_n_s32(t0123, shift);
        vst1_s16(d + 7 * line, res7);

        // EE and EO
        int32x4_t t0 = vpaddq_s32(EE[j / 2 + 0], EE[j / 2 + 1]);
        int32x4_t t1 = vmulq_s32(c0, t0);
        int16x4_t res0 = vrshrn_n_s32(t1, shift);
        vst1_s16(d + 0 * line, res0);

        int32x4_t t2 = vmulq_s32(c2, EO[j / 2 + 0]);
        int32x4_t t3 = vmulq_s32(c2, EO[j / 2 + 1]);
        int16x4_t res2 = vrshrn_n_s32(vpaddq_s32(t2, t3), shift);
        vst1_s16(d + 2 * line, res2);

        int32x4_t t4 = vmulq_s32(c4, EE[j / 2 + 0]);
        int32x4_t t5 = vmulq_s32(c4, EE[j / 2 + 1]);
        int16x4_t res4 = vrshrn_n_s32(vpaddq_s32(t4, t5), shift);
        vst1_s16(d + 4 * line, res4);

        int32x4_t t6 = vmulq_s32(c6, EO[j / 2 + 0]);
        int32x4_t t7 = vmulq_s32(c6, EO[j / 2 + 1]);
        int16x4_t res6 = vrshrn_n_s32(vpaddq_s32(t6, t7), shift);
        vst1_s16(d + 6 * line, res6);

        d += 4;
    }
}

static inline void pass1Butterfly16_sve(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    const int shift = 3 + X265_DEPTH - 8;
    const int line = 16;

    const int32x4_t c2 = vld1q_s32(t8_even[1]);
    const int32x4_t c6 = vld1q_s32(t8_even[3]);

    for (int i = 0; i < line; i += 4)
    {
        int16x8x2_t in0 = vld1q_s16_x2(src + (i + 0) * srcStride);
        int16x8x2_t in1 = vld1q_s16_x2(src + (i + 1) * srcStride);
        int16x8x2_t in2 = vld1q_s16_x2(src + (i + 2) * srcStride);
        int16x8x2_t in3 = vld1q_s16_x2(src + (i + 3) * srcStride);

        int16x8_t s0_lo = in0.val[0];
        int16x8_t s0_hi = rev16(in0.val[1]);
        int16x8_t s1_lo = in1.val[0];
        int16x8_t s1_hi = rev16(in1.val[1]);
        int16x8_t s2_lo = in2.val[0];
        int16x8_t s2_hi = rev16(in2.val[1]);
        int16x8_t s3_lo = in3.val[0];
        int16x8_t s3_hi = rev16(in3.val[1]);

        int32x4_t e00 = vaddl_s16(vget_low_s16(s0_lo), vget_low_s16(s0_hi));
        int32x4_t e01 = vaddl_s16(vget_high_s16(s0_lo), vget_high_s16(s0_hi));
        int32x4_t e10 = vaddl_s16(vget_low_s16(s1_lo), vget_low_s16(s1_hi));
        int32x4_t e11 = vaddl_s16(vget_high_s16(s1_lo), vget_high_s16(s1_hi));
        int32x4_t e20 = vaddl_s16(vget_low_s16(s2_lo), vget_low_s16(s2_hi));
        int32x4_t e21 = vaddl_s16(vget_high_s16(s2_lo), vget_high_s16(s2_hi));
        int32x4_t e30 = vaddl_s16(vget_low_s16(s3_lo), vget_low_s16(s3_hi));
        int32x4_t e31 = vaddl_s16(vget_high_s16(s3_lo), vget_high_s16(s3_hi));

        int16x8_t o0 = vsubq_s16(s0_lo, s0_hi);
        int16x8_t o1 = vsubq_s16(s1_lo, s1_hi);
        int16x8_t o2 = vsubq_s16(s2_lo, s2_hi);
        int16x8_t o3 = vsubq_s16(s3_lo, s3_hi);

        int32x4_t r01 = rev32(e01);
        int32x4_t r11 = rev32(e11);
        int32x4_t r21 = rev32(e21);
        int32x4_t r31 = rev32(e31);

        int32x4_t ee0 = vaddq_s32(e00, r01);
        int32x4_t ee1 = vaddq_s32(e10, r11);
        int32x4_t ee2 = vaddq_s32(e20, r21);
        int32x4_t ee3 = vaddq_s32(e30, r31);

        int16x8_t eo01 =
            vcombine_s16(vmovn_s32(vsubq_s32(e00, r01)), vmovn_s32(vsubq_s32(e10, r11)));
        int16x8_t eo23 =
            vcombine_s16(vmovn_s32(vsubq_s32(e20, r21)), vmovn_s32(vsubq_s32(e30, r31)));

        int32x4_t t0 = vcombine_s32(vget_low_s32(ee0), vget_low_s32(ee1));
        int32x4_t t1 = vrev64q_s32(vcombine_s32(vget_high_s32(ee0), vget_high_s32(ee1)));
        int32x4_t t2 = vcombine_s32(vget_low_s32(ee2), vget_low_s32(ee3));
        int32x4_t t3 = vrev64q_s32(vcombine_s32(vget_high_s32(ee2), vget_high_s32(ee3)));
        int32x4_t eee0 = vaddq_s32(t0, t1);
        int32x4_t eee1 = vaddq_s32(t2, t3);
        int32x4_t eeo0 = vsubq_s32(t0, t1);
        int32x4_t eeo1 = vsubq_s32(t2, t3);

        // Odd parts (k = 1,3,5,7,9,11,13,15)
        for (int k = 1; k < 16; k += 2)
        {
            const int16x8_t c = vld1q_s16(&g_t16[k][0]);

            int64x2_t tt0 = x265_sdotq_s16(vdupq_n_s64(0), c, o0);
            int64x2_t tt1 = x265_sdotq_s16(vdupq_n_s64(0), c, o1);
            int64x2_t tt2 = x265_sdotq_s16(vdupq_n_s64(0), c, o2);
            int64x2_t tt3 = x265_sdotq_s16(vdupq_n_s64(0), c, o3);
            int32x4_t t01 = vcombine_s32(vmovn_s64(tt0), vmovn_s64(tt1));
            int32x4_t t23 = vcombine_s32(vmovn_s64(tt2), vmovn_s64(tt3));

            int16x4_t res = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
            vst1_s16(dst + k * line, res);
        }

        // EO parts (k = 2,6,10,14)
        for (int k = 2; k < 16; k += 8)
        {
            const int16x8_t c01 = vld1q_s16(&t16_eo_s16[k - 2]);

            int64x2_t tt0 = x265_sdotq_lane_s16(vdupq_n_s64(0), eo01, c01, 0);
            int64x2_t tt1 = x265_sdotq_lane_s16(vdupq_n_s64(0), eo23, c01, 0);
            int32x4_t t01 = vcombine_s32(vmovn_s64(tt0), vmovn_s64(tt1));
            int16x4_t res2 = vrshrn_n_s32(t01, shift);

            tt0 = x265_sdotq_lane_s16(vdupq_n_s64(0), eo01, c01, 1);
            tt1 = x265_sdotq_lane_s16(vdupq_n_s64(0), eo23, c01, 1);
            t01 = vcombine_s32(vmovn_s64(tt0), vmovn_s64(tt1));
            int16x4_t res6 = vrshrn_n_s32(t01, shift);

            vst1_s16(dst + (k + 0) * line, res2);
            vst1_s16(dst + (k + 4) * line, res6);
        }

        // EE parts (k = 0,4,8,12)
        int32x4_t sum = vpaddq_s32(eee0, eee1);
        int16x4_t res0 = vmovn_s32(vrshlq_s32(sum, vdupq_n_s32(11 - X265_DEPTH)));
        vst1_s16(dst + 0 * line, res0);

        int32x4_t res4_lo = vmulq_s32(c2, eeo0);
        int32x4_t res4_hi = vmulq_s32(c2, eeo1);
        int16x4_t res4 = vrshrn_n_s32(vpaddq_s32(res4_lo, res4_hi), shift);
        vst1_s16(dst + 4 * line, res4);

        int32x4_t diff_lo = vsubq_s32(eee0, vrev64q_s32(eee0));
        int32x4_t diff_hi = vsubq_s32(eee1, vrev64q_s32(eee1));
        int32x4_t diff = vuzp1q_s32(diff_lo, diff_hi);
        int16x4_t res8 = vmovn_s32(vrshlq_s32(diff, vdupq_n_s32(11 - X265_DEPTH)));
        vst1_s16(dst + 8 * line, res8);

        int32x4_t res12_lo = vmulq_s32(c6, eeo0);
        int32x4_t res12_hi = vmulq_s32(c6, eeo1);
        int16x4_t res12 = vrshrn_n_s32(vpaddq_s32(res12_lo, res12_hi), shift);
        vst1_s16(dst + 12 * line, res12);

        dst += 4;
    }
}

static inline void pass2Butterfly16_sve(const int16_t *src, int16_t *dst)
{
    const int shift = 10;
    const int line = 16;

    const int32x4_t c2 = vld1q_s32(t8_even[1]);
    const int32x4_t c6 = vld1q_s32(t8_even[3]);

    for (int i = 0; i < line; i += 4)
    {
        int16x8x2_t in0 = vld1q_s16_x2(src + (i + 0) * line);
        int16x8x2_t in1 = vld1q_s16_x2(src + (i + 1) * line);
        int16x8x2_t in2 = vld1q_s16_x2(src + (i + 2) * line);
        int16x8x2_t in3 = vld1q_s16_x2(src + (i + 3) * line);

        int16x8_t s0_lo = in0.val[0];
        int16x8_t s0_hi = rev16(in0.val[1]);
        int16x8_t s1_lo = in1.val[0];
        int16x8_t s1_hi = rev16(in1.val[1]);
        int16x8_t s2_lo = in2.val[0];
        int16x8_t s2_hi = rev16(in2.val[1]);
        int16x8_t s3_lo = in3.val[0];
        int16x8_t s3_hi = rev16(in3.val[1]);

        int32x4_t e00 = vaddl_s16(vget_low_s16(s0_lo), vget_low_s16(s0_hi));
        int32x4_t e01 = vaddl_s16(vget_high_s16(s0_lo), vget_high_s16(s0_hi));
        int32x4_t e10 = vaddl_s16(vget_low_s16(s1_lo), vget_low_s16(s1_hi));
        int32x4_t e11 = vaddl_s16(vget_high_s16(s1_lo), vget_high_s16(s1_hi));
        int32x4_t e20 = vaddl_s16(vget_low_s16(s2_lo), vget_low_s16(s2_hi));
        int32x4_t e21 = vaddl_s16(vget_high_s16(s2_lo), vget_high_s16(s2_hi));
        int32x4_t e30 = vaddl_s16(vget_low_s16(s3_lo), vget_low_s16(s3_hi));
        int32x4_t e31 = vaddl_s16(vget_high_s16(s3_lo), vget_high_s16(s3_hi));

        int16x8_t o0 = vsubq_s16(s0_lo, s0_hi);
        int16x8_t o1 = vsubq_s16(s1_lo, s1_hi);
        int16x8_t o2 = vsubq_s16(s2_lo, s2_hi);
        int16x8_t o3 = vsubq_s16(s3_lo, s3_hi);

        int32x4_t r01 = rev32(e01);
        int32x4_t r11 = rev32(e11);
        int32x4_t r21 = rev32(e21);
        int32x4_t r31 = rev32(e31);

        int32x4_t ee0 = vaddq_s32(e00, r01);
        int32x4_t ee1 = vaddq_s32(e10, r11);
        int32x4_t ee2 = vaddq_s32(e20, r21);
        int32x4_t ee3 = vaddq_s32(e30, r31);

        int32x4_t eo0 = vsubq_s32(e00, r01);
        int32x4_t eo1 = vsubq_s32(e10, r11);
        int32x4_t eo2 = vsubq_s32(e20, r21);
        int32x4_t eo3 = vsubq_s32(e30, r31);

        int32x4_t t0 = vcombine_s32(vget_low_s32(ee0), vget_low_s32(ee1));
        int32x4_t t1 = vrev64q_s32(vcombine_s32(vget_high_s32(ee0), vget_high_s32(ee1)));
        int32x4_t t2 = vcombine_s32(vget_low_s32(ee2), vget_low_s32(ee3));
        int32x4_t t3 = vrev64q_s32(vcombine_s32(vget_high_s32(ee2), vget_high_s32(ee3)));
        int32x4_t eee0 = vaddq_s32(t0, t1);
        int32x4_t eee1 = vaddq_s32(t2, t3);
        int32x4_t eeo0 = vsubq_s32(t0, t1);
        int32x4_t eeo1 = vsubq_s32(t2, t3);

        // Odd parts (k = 1,3,5,7,9,11,13,15)
        for (int k = 1; k < 16; k += 2)
        {
            const int16x8_t c = vld1q_s16(&g_t16[k][0]);

            int64x2_t tt0 = x265_sdotq_s16(vdupq_n_s64(0), c, o0);
            int64x2_t tt1 = x265_sdotq_s16(vdupq_n_s64(0), c, o1);
            int64x2_t tt2 = x265_sdotq_s16(vdupq_n_s64(0), c, o2);
            int64x2_t tt3 = x265_sdotq_s16(vdupq_n_s64(0), c, o3);
            int32x4_t t01 = vcombine_s32(vmovn_s64(tt0), vmovn_s64(tt1));
            int32x4_t t23 = vcombine_s32(vmovn_s64(tt2), vmovn_s64(tt3));

            int16x4_t res = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
            vst1_s16(dst + k * line, res);
        }

        // EO parts (k = 2,6,10,14)
        for (int k = 2; k < 16; k += 4)
        {
            const int32x4_t c = vld1q_s32(&t16_eo_s32[k - 2]);

            int32x4_t tt0 = vmulq_s32(c, eo0);
            int32x4_t tt1 = vmulq_s32(c, eo1);
            int32x4_t tt2 = vmulq_s32(c, eo2);
            int32x4_t tt3 = vmulq_s32(c, eo3);
            int32x4_t tt = vpaddq_s32(vpaddq_s32(tt0, tt1), vpaddq_s32(tt2, tt3));

            int16x4_t res = vrshrn_n_s32(tt, shift);
            vst1_s16(dst + k * line, res);
        }

        // EE parts (k = 0,4,8,12)
        int32x4_t sum = vpaddq_s32(eee0, eee1);
        int16x4_t res0 = vrshrn_n_s32(sum, 4);
        vst1_s16(dst + 0 * line, res0);

        int32x4_t res4_lo = vmulq_s32(c2, eeo0);
        int32x4_t res4_hi = vmulq_s32(c2, eeo1);
        int16x4_t res4 = vrshrn_n_s32(vpaddq_s32(res4_lo, res4_hi), shift);
        vst1_s16(dst + 4 * line, res4);

        int32x4_t diff_lo = vsubq_s32(eee0, vrev64q_s32(eee0));
        int32x4_t diff_hi = vsubq_s32(eee1, vrev64q_s32(eee1));
        int32x4_t diff = vuzp1q_s32(diff_lo, diff_hi);
        int16x4_t res8 = vrshrn_n_s32(diff, 4);
        vst1_s16(dst + 8 * line, res8);

        int32x4_t res12_lo = vmulq_s32(c6, eeo0);
        int32x4_t res12_hi = vmulq_s32(c6, eeo1);
        int16x4_t res12 = vrshrn_n_s32(vpaddq_s32(res12_lo, res12_hi), shift);
        vst1_s16(dst + 12 * line, res12);

        dst += 4;
    }
}

static inline void pass1Butterfly32_sve(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    const int shift = 4 + X265_DEPTH - 8;
    const int line = 32;

    int16x8_t O[line][2];
    int16x8_t EO[line];
    int32x4_t EEO[line];
    int32x4_t EEEE[line / 2];
    int32x4_t EEEO[line / 2];

    for (int i = 0; i < line; i += 2)
    {
        int16x8x4_t in_lo = vld1q_s16_x4(src + (i + 0) * srcStride);
        in_lo.val[2] = rev16(in_lo.val[2]);
        in_lo.val[3] = rev16(in_lo.val[3]);

        int16x8x4_t in_hi = vld1q_s16_x4(src + (i + 1) * srcStride);
        in_hi.val[2] = rev16(in_hi.val[2]);
        in_hi.val[3] = rev16(in_hi.val[3]);

        int32x4_t E0[4];
        E0[0] = vaddl_s16(vget_low_s16(in_lo.val[0]),
                          vget_low_s16(in_lo.val[3]));
        E0[1] = vaddl_s16(vget_high_s16(in_lo.val[0]),
                          vget_high_s16(in_lo.val[3]));
        E0[2] = vaddl_s16(vget_low_s16(in_lo.val[1]),
                          vget_low_s16(in_lo.val[2]));
        E0[3] = vaddl_s16(vget_high_s16(in_lo.val[1]),
                          vget_high_s16(in_lo.val[2]));

        int32x4_t E1[4];
        E1[0] = vaddl_s16(vget_low_s16(in_hi.val[0]),
                          vget_low_s16(in_hi.val[3]));
        E1[1] = vaddl_s16(vget_high_s16(in_hi.val[0]),
                          vget_high_s16(in_hi.val[3]));
        E1[2] = vaddl_s16(vget_low_s16(in_hi.val[1]),
                          vget_low_s16(in_hi.val[2]));
        E1[3] = vaddl_s16(vget_high_s16(in_hi.val[1]),
                          vget_high_s16(in_hi.val[2]));

        O[i + 0][0] = vsubq_s16(in_lo.val[0], in_lo.val[3]);
        O[i + 0][1] = vsubq_s16(in_lo.val[1], in_lo.val[2]);

        O[i + 1][0] = vsubq_s16(in_hi.val[0], in_hi.val[3]);
        O[i + 1][1] = vsubq_s16(in_hi.val[1], in_hi.val[2]);

        int32x4_t EE0[2];
        E0[3] = rev32(E0[3]);
        E0[2] = rev32(E0[2]);
        EE0[0] = vaddq_s32(E0[0], E0[3]);
        EE0[1] = vaddq_s32(E0[1], E0[2]);
        EO[i + 0] = vcombine_s16(vmovn_s32(vsubq_s32(E0[0], E0[3])),
                                 vmovn_s32(vsubq_s32(E0[1], E0[2])));

        int32x4_t EE1[2];
        E1[3] = rev32(E1[3]);
        E1[2] = rev32(E1[2]);
        EE1[0] = vaddq_s32(E1[0], E1[3]);
        EE1[1] = vaddq_s32(E1[1], E1[2]);
        EO[i + 1] = vcombine_s16(vmovn_s32(vsubq_s32(E1[0], E1[3])),
                                 vmovn_s32(vsubq_s32(E1[1], E1[2])));

        int32x4_t EEE0;
        EE0[1] = rev32(EE0[1]);
        EEE0 = vaddq_s32(EE0[0], EE0[1]);
        EEO[i + 0] = vsubq_s32(EE0[0], EE0[1]);

        int32x4_t EEE1;
        EE1[1] = rev32(EE1[1]);
        EEE1 = vaddq_s32(EE1[0], EE1[1]);
        EEO[i + 1] = vsubq_s32(EE1[0], EE1[1]);

        int32x4_t t0 = vreinterpretq_s32_s64(
            vzip1q_s64(vreinterpretq_s64_s32(EEE0),
                       vreinterpretq_s64_s32(EEE1)));
        int32x4_t t1 = vrev64q_s32(vreinterpretq_s32_s64(
            vzip2q_s64(vreinterpretq_s64_s32(EEE0),
                       vreinterpretq_s64_s32(EEE1))));

        EEEE[i / 2] = vaddq_s32(t0, t1);
        EEEO[i / 2] = vsubq_s32(t0, t1);
    }

    for (int k = 1; k < 32; k += 2)
    {
        int16_t *d = dst + k * line;

        int16x8_t c0_c1 = vld1q_s16(&g_t32[k][0]);
        int16x8_t c2_c3 = vld1q_s16(&g_t32[k][8]);

        for (int i = 0; i < line; i += 4)
        {
            int64x2_t t0 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 0][0]);
            int64x2_t t1 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 1][0]);
            int64x2_t t2 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 2][0]);
            int64x2_t t3 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 3][0]);
            t0 = x265_sdotq_s16(t0, c2_c3, O[i + 0][1]);
            t1 = x265_sdotq_s16(t1, c2_c3, O[i + 1][1]);
            t2 = x265_sdotq_s16(t2, c2_c3, O[i + 2][1]);
            t3 = x265_sdotq_s16(t3, c2_c3, O[i + 3][1]);

            int32x4_t t01 = vcombine_s32(vmovn_s64(t0), vmovn_s64(t1));
            int32x4_t t23 = vcombine_s32(vmovn_s64(t2), vmovn_s64(t3));
            int16x4_t res = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    for (int k = 2; k < 32; k += 4)
    {
        int16_t *d = dst + k * line;

        int16x8_t c0 = vld1q_s16(&g_t32[k][0]);

        for (int i = 0; i < line; i += 4)
        {
            int64x2_t t0 = x265_sdotq_s16(vdupq_n_s64(0), c0, EO[i + 0]);
            int64x2_t t1 = x265_sdotq_s16(vdupq_n_s64(0), c0, EO[i + 1]);
            int64x2_t t2 = x265_sdotq_s16(vdupq_n_s64(0), c0, EO[i + 2]);
            int64x2_t t3 = x265_sdotq_s16(vdupq_n_s64(0), c0, EO[i + 3]);

            int32x4_t t01 = vcombine_s32(vmovn_s64(t0), vmovn_s64(t1));
            int32x4_t t23 = vcombine_s32(vmovn_s64(t2), vmovn_s64(t3));
            int16x4_t res = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    for (int k = 4; k < 32; k += 8)
    {
        int16_t *d = dst + k * line;

        int32x4_t c = x265_vld1sh_s32(&g_t32[k][0]);

        for (int i = 0; i < line; i += 4)
        {
            int32x4_t t0 = vmulq_s32(c, EEO[i + 0]);
            int32x4_t t1 = vmulq_s32(c, EEO[i + 1]);
            int32x4_t t2 = vmulq_s32(c, EEO[i + 2]);
            int32x4_t t3 = vmulq_s32(c, EEO[i + 3]);

            int32x4_t t = vpaddq_s32(vpaddq_s32(t0, t1), vpaddq_s32(t2, t3));
            int16x4_t res = vrshrn_n_s32(t, shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    int32x4_t c0 = vld1q_s32(t8_even[0]);
    int32x4_t c8 = vld1q_s32(t8_even[1]);
    int32x4_t c16 = vld1q_s32(t8_even[2]);
    int32x4_t c24 = vld1q_s32(t8_even[3]);

    for (int i = 0; i < line; i += 4)
    {
        int32x4_t t0 = vpaddq_s32(EEEE[i / 2 + 0], EEEE[i / 2 + 1]);
        int32x4_t t1 = vmulq_s32(c0, t0);
        int16x4_t res0 = vrshrn_n_s32(t1, shift);
        vst1_s16(dst + 0 * line, res0);

        int32x4_t t2 = vmulq_s32(c8, EEEO[i / 2 + 0]);
        int32x4_t t3 = vmulq_s32(c8, EEEO[i / 2 + 1]);
        int16x4_t res8 = vrshrn_n_s32(vpaddq_s32(t2, t3), shift);
        vst1_s16(dst + 8 * line, res8);

        int32x4_t t4 = vmulq_s32(c16, EEEE[i / 2 + 0]);
        int32x4_t t5 = vmulq_s32(c16, EEEE[i / 2 + 1]);
        int16x4_t res16 = vrshrn_n_s32(vpaddq_s32(t4, t5), shift);
        vst1_s16(dst + 16 * line, res16);

        int32x4_t t6 = vmulq_s32(c24, EEEO[i / 2 + 0]);
        int32x4_t t7 = vmulq_s32(c24, EEEO[i / 2 + 1]);
        int16x4_t res24 = vrshrn_n_s32(vpaddq_s32(t6, t7), shift);
        vst1_s16(dst + 24 * line, res24);

        dst += 4;
    }
}

static inline void pass2Butterfly32_sve(const int16_t *src, int16_t *dst)
{
    const int shift = 11;
    const int line = 32;

    int16x8_t O[line][2];
    int32x4_t EO[line][2];
    int32x4_t EEO[line];
    int32x4_t EEEE[line / 2];
    int32x4_t EEEO[line / 2];

    for (int i = 0; i < line; i += 2)
    {
        int16x8x4_t in_lo = vld1q_s16_x4(src + (i + 0) * line);
        in_lo.val[2] = rev16(in_lo.val[2]);
        in_lo.val[3] = rev16(in_lo.val[3]);

        int16x8x4_t in_hi = vld1q_s16_x4(src + (i + 1) * line);
        in_hi.val[2] = rev16(in_hi.val[2]);
        in_hi.val[3] = rev16(in_hi.val[3]);

        int32x4_t E0[4];
        E0[0] = vaddl_s16(vget_low_s16(in_lo.val[0]),
                          vget_low_s16(in_lo.val[3]));
        E0[1] = vaddl_s16(vget_high_s16(in_lo.val[0]),
                          vget_high_s16(in_lo.val[3]));
        E0[2] = vaddl_s16(vget_low_s16(in_lo.val[1]),
                          vget_low_s16(in_lo.val[2]));
        E0[3] = vaddl_s16(vget_high_s16(in_lo.val[1]),
                          vget_high_s16(in_lo.val[2]));

        int32x4_t E1[4];
        E1[0] = vaddl_s16(vget_low_s16(in_hi.val[0]),
                          vget_low_s16(in_hi.val[3]));
        E1[1] = vaddl_s16(vget_high_s16(in_hi.val[0]),
                          vget_high_s16(in_hi.val[3]));
        E1[2] = vaddl_s16(vget_low_s16(in_hi.val[1]),
                          vget_low_s16(in_hi.val[2]));
        E1[3] = vaddl_s16(vget_high_s16(in_hi.val[1]),
                          vget_high_s16(in_hi.val[2]));

        O[i + 0][0] = vsubq_s16(in_lo.val[0], in_lo.val[3]);
        O[i + 0][1] = vsubq_s16(in_lo.val[1], in_lo.val[2]);

        O[i + 1][0] = vsubq_s16(in_hi.val[0], in_hi.val[3]);
        O[i + 1][1] = vsubq_s16(in_hi.val[1], in_hi.val[2]);

        int32x4_t EE0[2];
        E0[3] = rev32(E0[3]);
        E0[2] = rev32(E0[2]);
        EE0[0] = vaddq_s32(E0[0], E0[3]);
        EE0[1] = vaddq_s32(E0[1], E0[2]);
        EO[i + 0][0] = vsubq_s32(E0[0], E0[3]);
        EO[i + 0][1] = vsubq_s32(E0[1], E0[2]);

        int32x4_t EE1[2];
        E1[3] = rev32(E1[3]);
        E1[2] = rev32(E1[2]);
        EE1[0] = vaddq_s32(E1[0], E1[3]);
        EE1[1] = vaddq_s32(E1[1], E1[2]);
        EO[i + 1][0] = vsubq_s32(E1[0], E1[3]);
        EO[i + 1][1] = vsubq_s32(E1[1], E1[2]);

        int32x4_t EEE0;
        EE0[1] = rev32(EE0[1]);
        EEE0 = vaddq_s32(EE0[0], EE0[1]);
        EEO[i + 0] = vsubq_s32(EE0[0], EE0[1]);

        int32x4_t EEE1;
        EE1[1] = rev32(EE1[1]);
        EEE1 = vaddq_s32(EE1[0], EE1[1]);
        EEO[i + 1] = vsubq_s32(EE1[0], EE1[1]);

        int32x4_t t0 = vreinterpretq_s32_s64(
            vzip1q_s64(vreinterpretq_s64_s32(EEE0),
                       vreinterpretq_s64_s32(EEE1)));
        int32x4_t t1 = vrev64q_s32(vreinterpretq_s32_s64(
            vzip2q_s64(vreinterpretq_s64_s32(EEE0),
                       vreinterpretq_s64_s32(EEE1))));

        EEEE[i / 2] = vaddq_s32(t0, t1);
        EEEO[i / 2] = vsubq_s32(t0, t1);
    }

    for (int k = 1; k < 32; k += 2)
    {
        int16_t *d = dst + k * line;

        int16x8_t c0_c1 = vld1q_s16(&g_t32[k][0]);
        int16x8_t c2_c3 = vld1q_s16(&g_t32[k][8]);

        for (int i = 0; i < line; i += 4)
        {
            int64x2_t t0 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 0][0]);
            int64x2_t t1 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 1][0]);
            int64x2_t t2 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 2][0]);
            int64x2_t t3 = x265_sdotq_s16(vdupq_n_s64(0), c0_c1, O[i + 3][0]);
            t0 = x265_sdotq_s16(t0, c2_c3, O[i + 0][1]);
            t1 = x265_sdotq_s16(t1, c2_c3, O[i + 1][1]);
            t2 = x265_sdotq_s16(t2, c2_c3, O[i + 2][1]);
            t3 = x265_sdotq_s16(t3, c2_c3, O[i + 3][1]);

            int32x4_t t01 = vcombine_s32(vmovn_s64(t0), vmovn_s64(t1));
            int32x4_t t23 = vcombine_s32(vmovn_s64(t2), vmovn_s64(t3));
            int16x4_t res = vrshrn_n_s32(vpaddq_s32(t01, t23), shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    for (int k = 2; k < 32; k += 4)
    {
        int16_t *d = dst + k * line;

        int32x4_t c0 = x265_vld1sh_s32(&g_t32[k][0]);
        int32x4_t c1 = x265_vld1sh_s32(&g_t32[k][4]);

        for (int i = 0; i < line; i += 4)
        {
            int32x4_t t[4];
            for (int j = 0; j < 4; ++j) {
                t[j] = vmulq_s32(c0, EO[i + j][0]);
                t[j] = vmlaq_s32(t[j], c1, EO[i + j][1]);
            }

            int32x4_t t0123 = vpaddq_s32(vpaddq_s32(t[0], t[1]),
                                         vpaddq_s32(t[2], t[3]));
            int16x4_t res = vrshrn_n_s32(t0123, shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    for (int k = 4; k < 32; k += 8)
    {
        int16_t *d = dst + k * line;

        int32x4_t c = x265_vld1sh_s32(&g_t32[k][0]);

        for (int i = 0; i < line; i += 4)
        {
            int32x4_t t0 = vmulq_s32(c, EEO[i + 0]);
            int32x4_t t1 = vmulq_s32(c, EEO[i + 1]);
            int32x4_t t2 = vmulq_s32(c, EEO[i + 2]);
            int32x4_t t3 = vmulq_s32(c, EEO[i + 3]);

            int32x4_t t = vpaddq_s32(vpaddq_s32(t0, t1), vpaddq_s32(t2, t3));
            int16x4_t res = vrshrn_n_s32(t, shift);
            vst1_s16(d, res);

            d += 4;
        }
    }

    int32x4_t c0 = vld1q_s32(t8_even[0]);
    int32x4_t c8 = vld1q_s32(t8_even[1]);
    int32x4_t c16 = vld1q_s32(t8_even[2]);
    int32x4_t c24 = vld1q_s32(t8_even[3]);

    for (int i = 0; i < line; i += 4)
    {
        int32x4_t t0 = vpaddq_s32(EEEE[i / 2 + 0], EEEE[i / 2 + 1]);
        int32x4_t t1 = vmulq_s32(c0, t0);
        int16x4_t res0 = vrshrn_n_s32(t1, shift);
        vst1_s16(dst + 0 * line, res0);

        int32x4_t t2 = vmulq_s32(c8, EEEO[i / 2 + 0]);
        int32x4_t t3 = vmulq_s32(c8, EEEO[i / 2 + 1]);
        int16x4_t res8 = vrshrn_n_s32(vpaddq_s32(t2, t3), shift);
        vst1_s16(dst + 8 * line, res8);

        int32x4_t t4 = vmulq_s32(c16, EEEE[i / 2 + 0]);
        int32x4_t t5 = vmulq_s32(c16, EEEE[i / 2 + 1]);
        int16x4_t res16 = vrshrn_n_s32(vpaddq_s32(t4, t5), shift);
        vst1_s16(dst + 16 * line, res16);

        int32x4_t t6 = vmulq_s32(c24, EEEO[i / 2 + 0]);
        int32x4_t t7 = vmulq_s32(c24, EEEO[i / 2 + 1]);
        int16x4_t res24 = vrshrn_n_s32(vpaddq_s32(t6, t7), shift);
        vst1_s16(dst + 24 * line, res24);

        dst += 4;
    }
}

}


namespace X265_NS
{
// x265 private namespace
void dct8_sve(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    const int shift_pass1 = 2 + X265_DEPTH - 8;
    const int shift_pass2 = 9;

    ALIGN_VAR_32(int16_t, coef[8 * 8]);
    ALIGN_VAR_32(int16_t, block[8 * 8]);

    for (int i = 0; i < 8; i++)
    {
        memcpy(&block[i * 8], &src[i * srcStride], 8 * sizeof(int16_t));
    }

    partialButterfly8_sve<shift_pass1>(block, coef);
    partialButterfly8_sve<shift_pass2>(coef, dst);
}

void dct16_sve(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    ALIGN_VAR_32(int16_t, coef[16 * 16]);

    pass1Butterfly16_sve(src, coef, srcStride);
    pass2Butterfly16_sve(coef, dst);
}

void dct32_sve(const int16_t *src, int16_t *dst, intptr_t srcStride)
{
    ALIGN_VAR_32(int16_t, coef[32 * 32]);

    pass1Butterfly32_sve(src, coef, srcStride);
    pass2Butterfly32_sve(coef, dst);
}

void setupDCTPrimitives_sve(EncoderPrimitives &p)
{
    p.cu[BLOCK_8x8].dct   = dct8_sve;
    p.cu[BLOCK_16x16].dct = dct16_sve;
    p.cu[BLOCK_32x32].dct = dct32_sve;
}

};
