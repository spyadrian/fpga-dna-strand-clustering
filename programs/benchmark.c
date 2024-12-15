/*
 * Based from : https://ceptord.net/index.html
 *
 * License: public domain.
 */

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

char *dataset;


// --- ALGORITHM ---

/**
 * @brief Computes the edit distance between two strings using the Wagner-Fischer algorithm.
 *
 * This function implements the Wagner-Fischer algorithm with Ukkonen optimization
 * to compute the minimum number of single-character edits (insertions, deletions, or substitutions)
 * required to transform one string into another. The function is optimized for short strings
 * and uses a buffer for efficient computation.
 *
 * @param s1 Pointer to the first string.
 * @param len1 Length of the first string.
 * @param s2 Pointer to the second string.
 * @param len2 Length of the second string.
 * @return The edit distance between the two strings.
 */
int8_t wagner_fischer(char *s1, int8_t len1, char *s2, int8_t len2) {
    int8_t Mx, mx, dia, top, left;
    int8_t i, j, m, M;
    int8_t buf[4096];
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

/**
 * @brief Computes the edit distance between two strings using Myers' bit-parallel algorithm.
 *
 * This function implements the bit-parallel string matching algorithm described by
 * G. Myers in the Journal of the ACM (1999). It efficiently computes the edit distance
 * by leveraging bitwise operations and parallel processing capabilities of modern CPUs.
 *
 * @param s1 Pointer to the first string.
 * @param len1 Length of the first string.
 * @param s2 Pointer to the second string.
 * @param len2 Length of the second string.
 * @return The edit distance between the two strings.
 */
int8_t myers1999(char *s1, int8_t len1, char *s2, int8_t len2) {

    uint64_t Peq[256];
    uint64_t Eq, Xv, Xh, Ph, Mh, Pv, Mv, Last;
    int8_t i;
    int8_t Score = len2;

    memset(Peq, 0, sizeof(Peq));

    for (i = 0; i < len2; i++)
        Peq[(uint8_t)s2[i]] |= (uint64_t)1 << i;

    Mv = 0;
    Pv = (uint64_t)-1;
    Last = (uint64_t)1 << (len2 - 1);

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


// --- UTILS ---

void randomhex(char *buf, int len) {

    static const char hex[] = "0123456789abcdef";
    srand(time(NULL));

    for (int i = 0; i < len; i++)
        buf[i] = hex[rand() & 0x0f];
}

double now(void) {

    struct timeval t;
    gettimeofday(&t, (struct timezone *)0);

    return t.tv_sec + t.tv_usec / (double)(1000000);
}

int bench_init(int size) {

    dataset = malloc(size);
    if (dataset == NULL)
        return -1;

    randomhex(dataset, size);
    return 0;
}

void bench_finish(void) {

    free(dataset);
}

double bench_run(int line_number, int len, int8_t(func)(char *, int8_t, char *, int8_t)) {

    int i, j;
    double t0 = now();

    for (i = 0; i < line_number; i++)
        for (j = 0; j < line_number; j++)
            func(dataset + i * len, len, dataset + j * len, len);

    return now() - t0;
}

int main(void) {

    int line_number[] = {2048, 8192, 32768};
    int line_len[] = {64, 128, 256};

    printf("%-6s %-5s %-16s %-16s\n", "#", "len", "WAGNER_FISCHER", "MYERS1999");

    for (int i = 0; i < 3; i++) {

        if (bench_init(line_number[i] * line_len[i]))
            return -1;

        double time_wf = bench_run(line_number[i], line_len[i], wagner_fischer);
        double time_my = bench_run(line_number[i], line_len[i], myers1999);

        printf("%-6i %-5i %-16.3f %-16.3f\n", line_number[i], line_len[i], time_wf, time_my);

        bench_finish();
    }

    return 0;
}
