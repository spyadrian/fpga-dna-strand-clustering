#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "algorithm/algorithm.h"

// Adjust this according to the number of tests in the data file
#define MAX_STR_LEN 256
#define NUM_TESTS 200


// --- UTILS ---

/**
 * @brief Compares the edit distance results from two algorithms.
 *
 * @param wf_distance Distance computed by Wagner-Fischer.
 * @param my_distance Distance computed by Myers.
 * @param expected_distance The expected edit distance from the file.
 */
void compare_results(int wf_distance, int my_distance, int expected_distance) {

    if (wf_distance != expected_distance)
        printf("Wagner-Fischer mismatch: expected %d, got %d\n", expected_distance, wf_distance);

    if (my_distance != expected_distance)
        printf("Myers mismatch: expected %d, got %d\n", expected_distance, my_distance);
}

// --- MAIN ---

int main(void) {

    char str1[MAX_STR_LEN + 1], str2[MAX_STR_LEN + 1];
    uint32_t len1, len2;
    int expected_distance;

    // Open the file containing the string pairs and edit distances
    FILE *file = fopen("data.txt", "r");
    if (file == NULL) {
        fprintf(stderr, "Could not open data.txt\n");
        return 1;
    }

    // Read each line and process the strings
    for (uint32_t i = 0; i < NUM_TESTS; i++) {

        // Read the two strings and the expected edit distance from the file
        if (fscanf(file, "\"%[^\"]\",\"%[^\"]\",%d\n", str1, str2, &expected_distance) != 3) {
            fprintf(stderr, "Error reading data.txt\n");
            fclose(file);
            return 1;
        }

        len1 = strlen(str1);
        len2 = strlen(str2);

        // Compute edit distances using your algorithms
        int wf_distance = wagner_fischer(str1, len1, str2, len2);
        int my_distance = myers1999(str1, len1, str2, len2);

        // Compare results with the expected edit distance (from the file)
        compare_results(wf_distance, my_distance, expected_distance);

        // Print test case
        // printf("Test %d:\n", i + 1);
        // printf("  String 1: %s\n", str1);
        // printf("  String 2: %s\n", str2);
        // printf("  Wagner-Fischer: %d\n", wf_distance);
        // printf("  Myers: %d\n", my_distance);
        // printf("  Expected: %d\n\n", expected_distance);
    }

    printf("End of testbench\n");
    fclose(file);
    return 0;
}
