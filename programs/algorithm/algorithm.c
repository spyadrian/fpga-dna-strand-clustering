#include "algorithm.h"

#include <stdint.h>
#include <string.h>


// --- FUNCTION ---

int32_t wagner_fischer(char *s1, int32_t len1, char *s2, int32_t len2) {

    int32_t Mx, mx, dia, top, left;
    int32_t i, j, m, M;
    int16_t buf[4096];
    char *p1;

    if (len1 < len2)
        return wagner_fischer(s2, len2, s1, len1);
    if (len2 == 0)
        return len1;
    if (len2 == 1)
        return len1 - (memchr(s1, s2[0], len1) != NULL);
    if (len2 == 2) {
        p1 = memchr(s1, s2[0], len1 - 1);
        if (p1) {
            i = len1 + s1 - p1 - 1;
            return len1 - (memchr(p1 + 1, s2[1], i) != NULL) - 1;
        } else {
            return len1 - (memchr(s1 + 1, s2[1], len1 - 1) != NULL);
        }
    }

    Mx = (len2 - 1) / 2;
    mx = 1 - Mx - (len1 - len2);

    for (j = 0; j <= Mx; j++)
        buf[j] = j;

    for (i = 1; i <= len1; i++) {
        buf[0] = i - 1;

        m = MAX(mx, 1);
        M = MIN(Mx, len2);
        mx++;
        Mx++;

        dia = buf[m - 1];
        top = buf[m];

        if (s1[i - 1] != s2[m - 1])
            dia = MIN(dia, top) + 1;

        buf[m] = dia;
        left = dia;
        dia = top;

        for (j = m + 1; j <= M; j++) {
            top = buf[j];

            if (s1[i - 1] != s2[j - 1])
                dia = MIN(MIN(dia, top), left) + 1;
            buf[j] = dia;
            left = dia;
            dia = top;
        }

        if (len2 == M)
            continue;

        if (s1[i - 1] != s2[M])
            dia = MIN(dia, left) + 1;

        buf[M + 1] = dia;
    }

    return buf[len2];
}

int32_t myers1999(char *s1, int32_t len1, char *s2, int32_t len2) {

    uint256_t Peq[256];
    uint256_t Eq, Xv, Xh, Ph, Mh, Pv, Mv, Last;
    int32_t i;
    int32_t Score = len2;

    memset(Peq, 0, sizeof(Peq));

    for (i = 0; i < len2; i++)
        Peq[(uint8_t)s2[i]] |= (uint256_t)1 << i;

    Mv = 0;
    Pv = (uint256_t)-1;
    Last = (uint256_t)1 << (len2 - 1);

    for (i = 0; i < len1; i++) {
        Eq = Peq[(uint8_t)s1[i]];

        Xv = Eq | Mv;
        Xh = (((Eq & Pv) + Pv) ^ Pv) | Eq;

        Ph = Mv | ~(Xh | Pv);
        Mh = Pv & Xh;

        if (Ph & Last)
            Score++;
        if (Mh & Last)
            Score--;

        Ph = (Ph << 1) | 1;
        Mh = (Mh << 1);

        Pv = Mh | ~(Xv | Ph);
        Mv = Ph & Xv;
    }

    return Score;
}

