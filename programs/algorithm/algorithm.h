/*
 * Based from : https://ceptord.net/index.html
 */

#ifndef _ALGORITHM_H_

#include <stdint.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

typedef unsigned _BitInt(256) uint256_t;


// --- FUNCTION ---

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
int32_t wagner_fischer(char *s1, int32_t len1, char *s2, int32_t len2);

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
int32_t myers1999(char *s1, int32_t len1, char *s2, int32_t len2);

#endif // !_ALGORITHM_H_
