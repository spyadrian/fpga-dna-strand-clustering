/*
 * Based from : https://ceptord.net/index.html
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>

#include "algorithm/algorithm.h"

char *dataset;


// --- UTILS ---

void randomhex(char *buf, int32_t len) {

    static const char hex[] = "0123456789abcdef";
    srand(time(NULL));

    for (int32_t i = 0; i < len; i++)
        buf[i] = hex[rand() & 0x0f];
}

double now(void) {

    struct timeval t;
    gettimeofday(&t, (struct timezone *)0);

    return t.tv_sec + t.tv_usec / (double)(1000000);
}

uint8_t bench_init(int32_t size) {

    dataset = malloc(size);
    if (dataset == NULL)
        return -1;

    randomhex(dataset, size);
    return 0;
}

void bench_finish(void) {

    free(dataset);
}

double bench_run(uint32_t line_number, uint32_t len, int32_t(func)(char *, int32_t, char *, int32_t)) {

    uint32_t i, j;
    double t0 = now();

    for (i = 0; i < line_number; i++)
        for (j = i + 1; j < line_number; j++)
            func(dataset + i * len, len, dataset + j * len, len);

    return now() - t0;
}

int main(void) {

    int32_t line_number[] = {64, 128, 256, 1024, 2048, 4096, 8192, 32768};
    int32_t line_len[] = {  244, 244, 244,  244,  244,  244,  244,   244};

    printf("%-6s %-5s %-16s %-16s\n", "#", "len", "WAGNER_FISCHER", "MYERS1999");

    for (int32_t i = 0; i < 8; i++) {

        if (bench_init(line_number[i] * line_len[i]))
            return -1;

        double time_wf = bench_run(line_number[i], line_len[i], wagner_fischer);
        double time_my = bench_run(line_number[i], line_len[i], myers1999);

        printf("%-6i %-5i %-16.3f %-16.3f\n", line_number[i], line_len[i], time_wf, time_my);

        bench_finish();
    }

    return 0;
}
