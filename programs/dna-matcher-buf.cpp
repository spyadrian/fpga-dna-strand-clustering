#include <map>
#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <fstream>
#include <cstring>
#include <algorithm>
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/fpga_extensions.hpp>

using namespace sycl;

/**
 * @namespace DNAConfig
 * @brief Configuration constants for A7SK FPGA DNA processing
 * 
 * Hardware-specific constants for Intel Agilex 7 Starter Kit optimizations
 * including memory limits, tile sizes, and DNA encoding parameters.
 */
namespace DNAConfig {
    static constexpr int MAX_DNA_LENGTH = 1024;                         // Max DNA length in char (8 bits)
    static constexpr int MAX_PACKED_LENGTH = (MAX_DNA_LENGTH + 3) / 4;  // Max bytes for a packed format DNA 
    static constexpr int MAX_LEVENSHTEIN_DISTANCE = 20;                 // Distance maximale acceptée
    static constexpr int MIN_LEVENSHTEIN_DISTANCE = 0;                  // Distance minimale pour arrêt précoce}
}

/**
 * @enum class DNABase
 * @brief 2-bit DNA base encoding
 * 
 * Compact representation: A=00, T=01, G=10, C=11
 * Enables 4x memory compression for FPGA optimization.
 */
enum class DNABase : uint8_t {
    A = 0b00,
    T = 0b01,
    G = 0b10,
    C = 0b11
};

/**
 * @class DNABitVector256
 * @brief FPGA-optimized 256-bit vector for Myers algorithm
 * 
 * Custom bit vector with vectorized operations, optimized memory layout,
 * and unrolled loops for maximum A7SK FPGA performance.
 */
class DNABitVector256 {

private:
    static constexpr int NUM_WORDS = 4;                                 // Number of words
    static constexpr int BITS_PER_WORD = 64;                            // Bits per word
    static constexpr int TOTAL_BITS = NUM_WORDS * BITS_PER_WORD;        // Total of bits contained

    uint64_t words[NUM_WORDS];

public:

    /**
     * @brief Default constructor - initializes all bits to zero
     * Creates a 256-bit vector optimized for DNA sequence operations with 4 64-bit words
     */
    DNABitVector256() {
        clear();
    }

    /**
     * @brief Clears all bits in the vector (sets to zero)
     * Efficiently resets all 4 words using unrolled loop for FPGA optimization
     */
    void clear() {
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            words[i] = 0;
        }
    }

    /**
     * @brief Initializes all words to a specific 64-bit value
     * @param value The 64-bit value to replicate across all 4 words
     * Used for bulk initialization operations with custom patterns
     */
    void fill_all_words(uint64_t value) {
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            words[i] = value;
        }
    }

    /**
     * @brief Sets all 256 bits to 1 (creates all-ones bit pattern)
     * Optimized for Myers algorithm initialization where all positions start as matches
     */
    void set_all_bits() {
        fill_all_words(0xFFFFFFFFFFFFFFFFULL);
    }

    /**
     * @brief Bitwise OR operation between two bit vectors
     * @param other The bit vector to OR with this vector
     * @return New DNABitVector256 containing the OR result
     * Performs element-wise OR across all 4 words with loop unrolling
     */
    DNABitVector256 operator|(const DNABitVector256& other) const {
        DNABitVector256 result;

        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = words[i] | other.words[i];
        }

        return result;
    }

    /**
     * @brief Bitwise AND operation between two bit vectors
     * @param other The bit vector to AND with this vector
     * @return New DNABitVector256 containing the AND result
     * Essential for Myers algorithm mask operations
     */
    DNABitVector256 operator&(const DNABitVector256& other) const {
        DNABitVector256 result;

        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = words[i] & other.words[i];
        }

        return result;
    }

    /**
     * @brief Bitwise NOT operation (complement of all bits)
     * @return New DNABitVector256 with all bits flipped
     * Used in Myers algorithm for creating inverse masks
     */
    DNABitVector256 operator~() const {
        DNABitVector256 result;

        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = ~words[i];
        }

        return result;
    }

    /**
     * @brief Bitwise XOR operation between two bit vectors
     * @param other The bit vector to XOR with this vector
     * @return New DNABitVector256 containing the XOR result
     * Critical for Myers algorithm's bit manipulation steps
     */
    DNABitVector256 operator^(const DNABitVector256& other) const {
        DNABitVector256 result;
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = words[i] ^ other.words[i];
        }
        return result;
    }

    /**
     * @brief Left bit shift operation with multi-word handling
     * @param shift Number of positions to shift left (0-255)
     * @return New DNABitVector256 with bits shifted left
     * Handles cross-word carries for shifts > 64 bits, essential for Myers progression
     */
    DNABitVector256 operator<<(int shift) const {
        DNABitVector256 result;
        if (shift >= TOTAL_BITS) return result;

        int word_shift = shift >> 6;  // shift / 64
        int bit_shift = shift & 63;   // shift % 64

        #pragma unroll
        for (int i = NUM_WORDS - 1; i >= word_shift; i--) {
            result.words[i] = words[i - word_shift] << bit_shift;

            if (bit_shift > 0 && (i - word_shift - 1) >= 0) {
                result.words[i] |= words[i - word_shift - 1] >> (BITS_PER_WORD - bit_shift);
            }
        }

        return result;
    }

    /**
     * @brief Binary addition of two bit vectors with carry propagation
     * @param other The bit vector to add to this vector
     * @return New DNABitVector256 containing the sum
     * Used in Myers algorithm for score computation with overflow handling
     */
    DNABitVector256 operator+(const DNABitVector256& other) const {
        DNABitVector256 result;
        uint64_t carry = 0;
        
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            uint64_t sum = words[i] + other.words[i] + carry;
            result.words[i] = sum;
            carry = (sum < words[i]) ? 1 : 0;
        }

        return result;
    }

    /**
     * @brief Sets a specific bit position to 1
     * @param pos Bit position to set (0-255)
     * Efficiently calculates word index and bit offset for FPGA-optimized access
     */
    void set_bit(int pos) {
        if (pos < TOTAL_BITS) {
            int word_idx = pos >> 6;  // pos / 64
            int bit_idx = pos & 63;   // pos % 64
            words[word_idx] |= (1ULL << bit_idx);
        }
    }

    /**
     * @brief Tests if a specific bit position is set
     * @param pos Bit position to test (0-255)
     * @return true if bit is set, false otherwise
     * Critical for Myers algorithm termination and score tracking
     */
    bool test_bit(int pos) const {
        if (pos >= TOTAL_BITS) return false;
        
        int word_idx = pos >> 6;  // pos / 64
        int bit_idx = pos & 63;   // pos % 64
        uint64_t mask = 1ULL << bit_idx;

        return (words[word_idx] & mask) != 0;
    }
};

/**
 * @namespace DNAEncoding
 * @brief DNA sequence encoding and compression utilities
 * 
 * Provides functions for converting DNA sequences from ASCII representation to 
 * optimized 2-bit packed format. This namespace handles the core data transformation
 * that enables 4x memory compression (from 8 bits per base to 2 bits per base),
 * critical for maximizing FPGA memory bandwidth and capacity utilization.
 */
namespace DNAEncoding {

    /**
     * @struct PackedCache
     * @brief Single-word cache for packed DNA access
     * 
     * Caches 4 DNA bases per access to reduce FPGA memory bandwidth
     * requirements by up to 75%.
     */
    struct PackedCache {
        uint32_t cached_word;
        int cache_start_pos;
        bool cache_valid;
        
        PackedCache() : cached_word(0), cache_start_pos(-1), cache_valid(false) {}
        
        void invalidate() { cache_valid = false; }
    };

    /**
     * @brief Encodes a single DNA character to 2-bit representation
     * @param base DNA character ('A', 'T', 'G', 'C', case-insensitive)
     * @return 2-bit encoded value (A=00, T=01, G=10, C=11)
     * Provides 4x memory compression compared to ASCII storage
     */
    inline uint8_t encode_base(char base) {
        switch (base) {
            case 'A': case 'a': return static_cast<uint8_t>(DNABase::A);
            case 'T': case 't': return static_cast<uint8_t>(DNABase::T);
            case 'G': case 'g': return static_cast<uint8_t>(DNABase::G);
            case 'C': case 'c': return static_cast<uint8_t>(DNABase::C);

            default: return static_cast<uint8_t>(DNABase::A);  // default fallback
        }
    }

    /**
     * @brief Packs DNA string into compressed 2-bit format
     * @param dna_str Input DNA sequence as null-terminated string
     * @param length Length of the DNA sequence
     * @param packed Output buffer for packed sequence (4 bases per byte)
     * @param packed_length Output parameter containing packed data length in bytes
     * Optimizes memory usage and cache performance for FPGA processing
     */
    void pack_sequence(const char* dna_str, int length, uint8_t* packed, int& packed_length) {
        packed_length = (length + 3) / 4;  // round up to nearest byte
        memset(packed, 0, packed_length);
        
        for (int i = 0; i < length; i++) {
            uint8_t encoded = encode_base(dna_str[i]);

            int byte_idx = i / 4;
            int bit_pos = (i % 4) * 2;
            packed[byte_idx] |= (encoded << bit_pos);
        }
    }

    /**
     * @brief Extracts a single base from packed format with caching optimization
     * @param packed Pointer to packed DNA sequence data
     * @param pos Position of base to extract
     * @param cache Cache structure for 4-base prefetching optimization
     * @return 2-bit encoded base value
     * Uses word-aligned caching to minimize memory accesses on FPGA
     */
    inline uint8_t get_base_cached(const uint8_t* packed, int pos, PackedCache& cache) {
        int word_start = (pos >> 2) << 2;  // align to 4-base boundary
        
        if (!cache.cache_valid || cache.cache_start_pos != word_start) {

            cache.cached_word = packed[pos >> 2];
            cache.cache_start_pos = word_start;
            cache.cache_valid = true;
        }
        
        int bit_pos = (pos & 3) << 1;  // (pos % 4) * 2
        return (cache.cached_word >> bit_pos) & 0b11;
    }

    /**
     * @brief Vectorized unpacking of 4 bases from a single byte
     * @param packed_byte Single byte containing 4 packed DNA bases
     * @param bases Output array of 4 unpacked base values
     * SIMD-style operation optimized for FPGA parallel processing
     */
    inline void unpack_4_bases(uint8_t packed_byte, uint8_t bases[4]) {
        #pragma unroll
        for (int i = 0; i < 4; i++) {
            bases[i] = (packed_byte >> (i << 1)) & 0b11;  // (i * 2)
        }
    }
}

/**
 * @struct NearestResult
 * @brief DNA matching result container
 * 
 * Stores minimum Levenshtein distance and best match index.
 * Initialized with sentinel values for proper error handling.
 */
struct NearestResult {
    int32_t min_distance;
    int32_t match_count;                // Number of equidistant matches
    int32_t best_match_indices[16];     // Fixed-size array for matches (adjust size as needed)
    bool early_termination;             // Ajouter ce flag pour indiquer l'arrêt précoce

    NearestResult() : min_distance(INT_MAX), match_count(0), early_termination(false) {
        for (int i = 0; i < 16; i++) {
            best_match_indices[i] = -1;
        }
    }
    
    // Helper method for host-side processing
    void add_match(int32_t distance, int32_t match_index) {
        if (distance < min_distance) {
            min_distance = distance;
            match_count = 1;
            best_match_indices[0] = match_index;
            for (int i = 1; i < 16; i++) {
                best_match_indices[i] = -1;
            }
        } else if (distance == min_distance && match_count < 16) {
            best_match_indices[match_count] = match_index;
            match_count++;
        }
    }
};

/**
* @brief Creates query-reference pairs from equidistant matching results
* @param bucket_ids Original bucket ID sequences
* @param reference_sequences Original reference sequences  
* @param results Results with multiple equidistant matches
* @param num_bucket_ids Number of bucket IDs
* @return Vector of query-reference pairs in the format "query;reference"
*/
std::vector<std::string> create_query_reference_pairs(
    const std::vector<std::string>& bucket_ids,
    const std::vector<std::string>& reference_sequences,
    const NearestResult* results,
    int32_t num_bucket_ids) {
    
    std::vector<std::string> pairs;
    
    for (int32_t i = 0; i < num_bucket_ids; i++) {
        const auto& result = results[i];
        
        // Pour chaque match équidistant, créer une paire
        for (int32_t j = 0; j < result.match_count && j < 16; j++) {
            int32_t ref_idx = result.best_match_indices[j];
            if (ref_idx >= 0 && ref_idx < static_cast<int32_t>(reference_sequences.size())) {
                pairs.push_back(reference_sequences[ref_idx] + ";" + bucket_ids[i]);
            }
        }
    }
    
    return pairs;
}

/**
 * @struct Bucket
 * @brief Container for queries that match the same reference bucket ID
 */
struct Bucket {
    int32_t reference_index;        // Index of the reference this bucket corresponds to
    std::vector<int32_t> query_indices; // Indices of queries in this bucket
    
    // Default constructor
    Bucket() : reference_index(-1) {}
    
    // Parameterized constructor
    Bucket(int32_t ref_idx) : reference_index(ref_idx) {}
};

/**
 * @brief Creates buckets by grouping bucket IDs with their nearest reference matches
 * @param bucket_ids Original bucket ID sequences
 * @param reference_sequences Original reference sequences
 * @param results Results from nearest neighbor search
 * @param num_bucket_ids Number of bucket IDs
 * @return Vector of buckets grouped by reference match
 */
// std::vector<Bucket> create_buckets(
//     const std::vector<std::string>& bucket_ids,
//     const std::vector<std::string>& reference_sequences,
//     const NearestResult* results,
//     int32_t num_bucket_ids) {

//     std::map<int32_t, Bucket> bucket_map;

//     // Group bucket IDs by their best matching reference
//     for (int32_t i = 0; i < num_bucket_ids; i++) {
//         if (results[i].best_match_index >= 0) {
//             int32_t ref_idx = results[i].best_match_index;
//             if (bucket_map.find(ref_idx) == bucket_map.end()) {
//                 bucket_map[ref_idx] = Bucket(ref_idx);
//             }
//             bucket_map[ref_idx].query_indices.push_back(i);
//         }
//     }

//     // Convert map to vector
//     std::vector<Bucket> buckets;
//     for (auto& pair : bucket_map) {
//         buckets.push_back(std::move(pair.second));
//     }

//     return buckets;
// }


/**
* @brief Batch DNA sequence matching using optimized Myers algorithm with buffers/accessors
* @param q SYCL queue for FPGA device execution
* @param query_dna Array of query DNA sequences
* @param query_lengths Array of query sequence lengths
* @param num_queries Number of query sequences
* @param reference_dna Array of reference DNA sequences
* @param reference_lengths Array of reference sequence lengths
* @param num_references Number of reference sequences
* @param results Output array for nearest match results
* @return SYCL event for asynchronous execution tracking
*
* Implements Myers bit-parallel algorithm with DNA-specific optimizations using buffers/accessors:
* - 2-bit DNA encoding for 4x memory efficiency
* - Vectorized bit operations using 256-bit vectors
* - FPGA-optimized memory access patterns
* - Batch processing for high throughput
*/
event myers_find_nearest(
    queue& q,
    char** query_dna, int32_t* query_lengths, int32_t num_queries,
    char** reference_dna, int32_t* reference_lengths, int32_t num_references,
    NearestResult* results) {
    
    using namespace DNAConfig;
    using namespace DNAEncoding;
    
    // Host buffer preparation for packed data
    std::vector<uint8_t> host_query_buffer(num_queries * MAX_PACKED_LENGTH);
    std::vector<uint8_t> host_ref_buffer(num_references * MAX_PACKED_LENGTH);
    std::vector<int32_t> host_query_lengths(num_queries);
    std::vector<int32_t> host_ref_lengths(num_references);
    
    // Pack all queries
    for (int i = 0; i < num_queries; i++) {
        uint8_t* dest = host_query_buffer.data() + i * MAX_PACKED_LENGTH;
        int packed_length;
        pack_sequence(query_dna[i], query_lengths[i], dest, packed_length);
        host_query_lengths[i] = query_lengths[i];
    }
    
    // Pack all references
    for (int i = 0; i < num_references; i++) {
        uint8_t* dest = host_ref_buffer.data() + i * MAX_PACKED_LENGTH;
        int packed_length;
        pack_sequence(reference_dna[i], reference_lengths[i], dest, packed_length);
        host_ref_lengths[i] = reference_lengths[i];
    }
    
    // Create SYCL buffers
    buffer<uint8_t, 1> query_packed_buf(host_query_buffer.data(), range<1>(num_queries * MAX_PACKED_LENGTH));
    buffer<uint8_t, 1> ref_packed_buf(host_ref_buffer.data(), range<1>(num_references * MAX_PACKED_LENGTH));
    buffer<int32_t, 1> query_lengths_buf(host_query_lengths.data(), range<1>(num_queries));
    buffer<int32_t, 1> ref_lengths_buf(host_ref_lengths.data(), range<1>(num_references));
    buffer<NearestResult, 1> results_buf{range<1>(num_queries)};
    
    // Launch optimized kernel with buffers/accessors
    auto kernel_event = q.submit([&](handler& h) {
        // Create accessors
        accessor query_packed_acc = query_packed_buf.get_access<access::mode::read>(h);
        accessor ref_packed_acc = ref_packed_buf.get_access<access::mode::read>(h);
        accessor query_lengths_acc = query_lengths_buf.get_access<access::mode::read>(h);
        accessor ref_lengths_acc = ref_lengths_buf.get_access<access::mode::read>(h);
        accessor results_acc = results_buf.get_access<access::mode::write>(h);

        h.parallel_for(
            nd_range<1>(range<1>((num_queries + 3) / 4 * 4), range<1>(4)), 
            [=](nd_item<1> item) {
                int global_id = item.get_global_id(0);
                if (global_id >= num_queries) return;
                
                PackedCache query_cache, ref_cache;
                
                // Calculate base pointer for this query (simulate pointer arithmetic)
                size_t query_base_offset = global_id * MAX_PACKED_LENGTH;
                int32_t query_len = query_lengths_acc[global_id];
                
                int32_t min_distance = INT_MAX;
                int32_t equidistant_matches[16];
                int32_t match_count = 0;
                
                #pragma unroll
                for (int i = 0; i < 16; i++) {
                    equidistant_matches[i] = -1;
                }
                
                // Process all references for this query
                for (int ref_idx = 0; ref_idx < num_references; ref_idx++) {
                    size_t ref_base_offset = ref_idx * MAX_PACKED_LENGTH;
                    int32_t ref_len = ref_lengths_acc[ref_idx];
                    
                    // Reset caches for new reference
                    ref_cache.invalidate();
                    query_cache.invalidate();
                    
                    // Build Peq arrays
                    DNABitVector256 Peq[4];
                    
                    for (int i = 0; i < ref_len; i += 4) {
                        int bases_to_process = std::min(4, ref_len - i);
                        if (bases_to_process == 4) {
                            uint8_t packed_byte = ref_packed_acc[ref_base_offset + (i >> 2)];
                            uint8_t bases[4];
                            unpack_4_bases(packed_byte, bases);
                            #pragma unroll
                            for (int j = 0; j < 4; j++) {
                                Peq[bases[j]].set_bit(i + j);
                            }
                        } else {
                            for (int j = 0; j < bases_to_process; j++) {
                                // Simulate get_base_cached with accessor access
                                int pos = i + j;
                                int word_start = (pos >> 2) << 2;
                                if (!ref_cache.cache_valid || ref_cache.cache_start_pos != word_start) {
                                    ref_cache.cached_word = ref_packed_acc[ref_base_offset + (pos >> 2)];
                                    ref_cache.cache_start_pos = word_start;
                                    ref_cache.cache_valid = true;
                                }
                                int bit_pos = (pos & 3) << 1;
                                uint8_t base = (ref_cache.cached_word >> bit_pos) & 0b11;
                                Peq[base].set_bit(i + j);
                            }
                        }
                    }
                    
                    // Myers algorithm core
                    DNABitVector256 Mv, Pv;
                    Pv.set_all_bits();
                    int32_t Score = ref_len;
                    
                    for (int i = 0; i < query_len; i++) {
                        // Simulate get_base_cached with accessor access for query
                        int pos = i;
                        int word_start = (pos >> 2) << 2;
                        if (!query_cache.cache_valid || query_cache.cache_start_pos != word_start) {
                            query_cache.cached_word = query_packed_acc[query_base_offset + (pos >> 2)];
                            query_cache.cache_start_pos = word_start;
                            query_cache.cache_valid = true;
                        }
                        int bit_pos = (pos & 3) << 1;
                        uint8_t query_base = (query_cache.cached_word >> bit_pos) & 0b11;
                        
                        DNABitVector256 Eq = Peq[query_base];
                        DNABitVector256 Xv = Eq | Mv;
                        DNABitVector256 Xh = (((Eq & Pv) + Pv) ^ Pv) | Eq;
                        
                        DNABitVector256 Ph = Mv | ~(Xh | Pv);
                        DNABitVector256 Mh = Pv & Xh;
                        
                        if (Ph.test_bit(ref_len - 1)) Score++;
                        if (Mh.test_bit(ref_len - 1)) Score--;
                        
                        Ph = (Ph << 1);
                        Ph.set_bit(0);
                        Mh = Mh << 1;
                        
                        Pv = Mh | ~(Xv | Ph);
                        Mv = Ph & Xv;
                    }
                    
                    // Collecter les matches équidistants
                    if (Score <= min_distance && Score <= MAX_LEVENSHTEIN_DISTANCE) {

                        if (Score == min_distance && match_count < 16) {
                            // Match équidistant trouvé
                            equidistant_matches[match_count] = ref_idx;
                            match_count++;
                        } else {

                            // Nouvelle distance minimale trouvée
                            min_distance = Score;
                            match_count = 1;
                            equidistant_matches[0] = ref_idx;
                            // Reset du reste du tableau
                            #pragma unroll
                            for (int i = 1; i < 16; i++) {
                                equidistant_matches[i] = -1;
                            }

                            if (Score <= MIN_LEVENSHTEIN_DISTANCE) {
                                break;
                            }
                        }
                    }
                }
                
                results_acc[global_id].min_distance = min_distance;
                results_acc[global_id].match_count = match_count;
                results_acc[global_id].early_termination = (min_distance <= MIN_LEVENSHTEIN_DISTANCE);
                #pragma unroll
                for (int i = 0; i < 16; i++) {
                    results_acc[global_id].best_match_indices[i] = equidistant_matches[i];
                }
            });
    });
    
    // Copy results back to host
    auto copy_event = q.submit([&](handler& h) {
        h.depends_on(kernel_event);
        accessor results_acc = results_buf.get_access<access::mode::read>(h);
        h.copy(results_acc, results);
    });
    
    return copy_event;
}

/**
 * @class A7SK_DNA_Matcher
 * @brief High-level DNA matcher for Agilex 7 FPGA
 * 
 * Handles memory management, optimal tiling, and batch processing
 * with automatic optimization for A7SK hardware constraints.
 */
class A7SK_DNA_Matcher {

private:
    queue& fpga_queue;

public:

    /**
     * @brief Constructor for A7SK FPGA-optimized DNA matcher
     * @param q SYCL queue configured for A7SK FPGA device
     * Initializes matcher with device-specific optimizations for Agilex 7 architecture
     */
    explicit A7SK_DNA_Matcher(queue& q) : fpga_queue(q) {}

    /**
     * @brief Main entry point for A7SK-optimized DNA sequence matching
     * @param query_dna Array of query DNA sequences
     * @param query_lengths Array of query sequence lengths
     * @param num_queries Number of query sequences
     * @param reference_dna Array of reference DNA sequences
     * @param reference_lengths Array of reference sequence lengths
     * @param num_references Number of reference sequences
     * @param results Output array for nearest match results
     * @return SYCL event for execution tracking
     */
    event find_nearest_optimized(
        char** query_dna, int32_t* query_lengths, int32_t num_queries,
        char** reference_dna, int32_t* reference_lengths, int32_t num_references,
        NearestResult* results) {
        
        std::cout << "\n=== Find Nearest Match ===" << std::endl;
        std::cout << "Processing " << num_queries << " queries against " 
                << num_references << " references" << std::endl;
        
        return myers_find_nearest(
            fpga_queue,
            query_dna, query_lengths, num_queries,
            reference_dna, reference_lengths, num_references,
            results);
    }
};

/**
 * @namespace DNAValidation
 * @brief Input validation for DNA sequences
 * 
 * Validates DNA character sets, sequence lengths, and format requirements
 * before FPGA processing.
 */
namespace DNAValidation {

    /**
     * @brief Validates if a character is a valid DNA base
     * @param c Character to validate
     * @return true if character is A, T, G, C (case-insensitive), false otherwise
     * Input sanitization for robust DNA sequence processing
     */
    bool is_valid_dna_char(char c) {
        return (c == 'A' || c == 'T' || c == 'G' || c == 'C' || 
                c == 'a' || c == 't' || c == 'g' || c == 'c');
    }

    /**
     * @brief Validates an array of DNA sequences for correctness
     * @param sequences Array of DNA sequence strings
     * @param lengths Array of sequence lengths
     * @param count Number of sequences to validate
     * @return true if all sequences are valid, false otherwise
     * Comprehensive validation including length limits and character checking
     */
    bool validate_sequences(char** sequences, int32_t* lengths, int32_t count) {
        for (int i = 0; i < count; i++) {

            if (lengths[i] > DNAConfig::MAX_DNA_LENGTH || lengths[i] <= 0) {
                std::cerr << "Invalid sequence length: " << lengths[i] << " at index " << i << std::endl;
                return false;
            }

            for (int j = 0; j < lengths[i]; j++) {
                if (!is_valid_dna_char(sequences[i][j])) {
                    std::cerr << "Invalid DNA character '" << sequences[i][j] << "' at sequence " << i << ", position " << j << std::endl;
                    return false;
                }
            }
        }
        return true;
    }
}

namespace DNAFileIO {
    /**
     * @brief Validates command line arguments for two file paths
     * @param argc Number of command line arguments
     * @param argv Array of command line argument strings  
     * @param bucket_file Output parameter for bucket ID file path
     * @param ref_file Output parameter for reference file path
     * @return true if arguments are valid, false otherwise
     */
    bool parse_command_line_args(int argc, char* argv[], std::string& bucket_file, std::string& ref_file) {
        if (argc != 3) {
            std::cerr << "Usage: " << argv[0] << " <bucket_id_file> <reference_file>" << std::endl;
            std::cerr << "Example: " << argv[0] << " bucket_ids.txt references.txt" << std::endl;
            return false;
        }

        bucket_file = argv[1];
        ref_file = argv[2];
        return true;
    }

    /**
     * @brief Reads bucket IDs from a text file
     * @param filename Path to the input file containing bucket IDs
     * @param bucket_ids Output vector of bucket ID strings
     * @return true if file was read successfully, false otherwise
     * 
     * Expected file format:
     * - One bucket ID per line
     * - Lines starting with '#' are treated as comments and ignored
     * - Empty lines are ignored
     * - Variable length bucket IDs are supported
     */
    bool read_bucket_ids_from_file(const std::string& filename, std::vector<std::string>& bucket_ids) {
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cerr << "Error: Cannot open bucket ID file " << filename << std::endl;
            return false;
        }

        std::string line;
        bucket_ids.clear();
        
        while (std::getline(file, line)) {
            // Skip empty lines and comments
            if (line.empty() || line[0] == '#') {
                continue;
            }

            // Remove any trailing whitespace
            line.erase(line.find_last_not_of(" \t\r\n") + 1);
            
            // Validate bucket ID length
            if (line.length() > DNAConfig::MAX_DNA_LENGTH) {
                std::cerr << "Warning: Bucket ID too long (" << line.length() 
                         << " chars), truncating to " << DNAConfig::MAX_DNA_LENGTH << std::endl;
                line = line.substr(0, DNAConfig::MAX_DNA_LENGTH);
            }

            bucket_ids.push_back(line);
        }

        file.close();
        if (bucket_ids.empty()) {
            std::cerr << "Error: No valid bucket IDs found in " << filename << std::endl;
            return false;
        }

        std::cout << "Successfully loaded " << bucket_ids.size() 
                 << " bucket IDs from " << filename << std::endl;
        return true;
    }

        /**
     * @brief Reads DNA sequences from a text file
     * @param filename Path to the input file
     * @param sequences Output vector of DNA sequence strings
     * @return true if file was read successfully, false otherwise
     * 
     * Expected file format:
     * - One DNA sequence per line
     * - Lines starting with '#' are treated as comments and ignored
     * - Empty lines are ignored
     */
    bool read_dna_sequences_from_file(const std::string& filename, std::vector<std::string>& sequences) {
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cerr << "Error: Cannot open file " << filename << std::endl;
            return false;
        }
        
        std::string line;
        sequences.clear();
        
        while (std::getline(file, line)) {
            // Skip empty lines and comments
            if (line.empty() || line[0] == '#') {
                continue;
            }
            
            // Remove any trailing whitespace
            line.erase(line.find_last_not_of(" \t\r\n") + 1);
            
            // Validate sequence length
            if (line.length() > DNAConfig::MAX_DNA_LENGTH) {
                std::cerr << "Warning: Sequence too long (" << line.length() 
                         << " chars), truncating to " << DNAConfig::MAX_DNA_LENGTH << std::endl;
                line = line.substr(0, DNAConfig::MAX_DNA_LENGTH);
            }
            
            sequences.push_back(line);
        }
        
        file.close();
        
        if (sequences.empty()) {
            std::cerr << "Error: No valid sequences found in " << filename << std::endl;
            return false;
        }
        
        std::cout << "Successfully loaded " << sequences.size() 
                  << " sequences from " << filename << std::endl;
        return true;
    }
}

int main(int argc, char* argv[]) {
    try {
        // Parse command line arguments - now expects 2 files
        std::string bucket_file, reference_file;
        if (!DNAFileIO::parse_command_line_args(argc, argv, bucket_file, reference_file)) {
            return 1;
        }

        // Choose device (keep existing device selection code)
        #if FPGA_SIMULATOR
        auto selector = sycl::ext::intel::fpga_simulator_selector_v;
        #elif FPGA_HARDWARE
        auto selector = sycl::ext::intel::fpga_selector_v;
        #elif FPGA_EMULATOR
        auto selector = sycl::ext::intel::fpga_emulator_selector_v;
        #elif GPU
        auto selector = gpu_selector_v;
        #else
        auto selector = cpu_selector_v;
        #endif

        queue q(selector, [](exception_list el) {
            for (auto ex : el) {
                std::rethrow_exception(ex);
            }
        });

        std::cout << "Running on device: " << q.get_device().get_info<info::device::name>() << std::endl;

        // Load data from files
        std::cout << "\n=== Setup Data ===" << std::endl;
        std::vector<std::string> bucket_ids, reference_database;

        std::cout << "Loading bucket IDs..." << std::endl;
        if (!DNAFileIO::read_bucket_ids_from_file(bucket_file, bucket_ids)) {
            return 1;
        }

        std::cout << "Loading reference sequences..." << std::endl;
        if (!DNAFileIO::read_dna_sequences_from_file(reference_file, reference_database)) {
            return 1;
        }

        // Display bucket ID statistics
        size_t min_bucket_size = std::numeric_limits<size_t>::max();
        size_t max_bucket_size = 0;
        double avg_bucket_size = 0;
        
        for (const auto& bucket_id : bucket_ids) {
            min_bucket_size = std::min(min_bucket_size, bucket_id.length());
            max_bucket_size = std::max(max_bucket_size, bucket_id.length());
            avg_bucket_size += bucket_id.length();
        }
        avg_bucket_size /= bucket_ids.size();
        
        std::cout << "Queries statistics:" << std::endl;
        std::cout << "  Count: " << bucket_ids.size() << std::endl;
        std::cout << "  Min length: " << min_bucket_size << std::endl;
        std::cout << "  Max length: " << max_bucket_size << std::endl;
        std::cout << "  Avg length: " << std::fixed << std::setprecision(1) << avg_bucket_size << std::endl;

        // Prepare data structures for matching
        std::vector<char*> bucket_ptrs, ref_ptrs;
        std::vector<int32_t> bucket_lengths, ref_lengths;

        for (auto& bucket_id : bucket_ids) {
            bucket_ptrs.push_back(const_cast<char*>(bucket_id.c_str()));
            bucket_lengths.push_back(bucket_id.length());
        }

        for (auto& seq : reference_database) {
            ref_ptrs.push_back(const_cast<char*>(seq.c_str()));
            ref_lengths.push_back(seq.length());
        }

        // Validation
        if (!DNAValidation::validate_sequences(bucket_ptrs.data(), bucket_lengths.data(), bucket_ids.size()) ||
            !DNAValidation::validate_sequences(ref_ptrs.data(), ref_lengths.data(), reference_database.size())) {
            std::cerr << "Sequence validation failed!" << std::endl;
            return 1;
        }

        // Execute matching
        std::vector<NearestResult> results(bucket_ids.size());
        A7SK_DNA_Matcher matcher(q);
        
        auto start_time = std::chrono::high_resolution_clock::now();
        
        matcher.find_nearest_optimized(
            bucket_ptrs.data(), bucket_lengths.data(), bucket_ids.size(),
            ref_ptrs.data(), ref_lengths.data(), reference_database.size(),
            results.data()
        ).wait();
        
        auto end_time_matcher = std::chrono::high_resolution_clock::now();

        std::cout << "\nCreating query-reference pairs..." << std::endl;
        std::vector<std::string> pairs = create_query_reference_pairs(
            bucket_ids, reference_database, results.data(), bucket_ids.size());

        auto end_time = std::chrono::high_resolution_clock::now();

        // Display results
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);
        auto duration_matcher = std::chrono::duration_cast<std::chrono::microseconds>(end_time_matcher - start_time);
        auto duration_bucket = std::chrono::duration_cast<std::chrono::microseconds>(end_time - end_time_matcher);

        int64_t total_comparisons = static_cast<int64_t>(bucket_ids.size()) * reference_database.size();
        double avg_time_per_comparison = static_cast<double>(duration_matcher.count()) / total_comparisons;

        int32_t total_references_found = 0;
        int32_t early_terminations = 0;
        int32_t queries_without_matches = 0;

        for (size_t i = 0; i < bucket_ids.size(); i++) {
            total_references_found += results[i].match_count;
            if (results[i].early_termination) {
                early_terminations++;
            }
            if (results[i].match_count == 0) {
                queries_without_matches++;
            }
        }

        std::cout << "\n=== Performance Summary ===" << std::endl;
        std::cout << "Total execution time: " << duration.count() << " microseconds" << std::endl;
        std::cout << "Matcher execution time: " << duration_matcher.count() << " microseconds" << std::endl;
        std::cout << "Bucket regroupement execution time: " << duration_bucket.count() << " microseconds" << std::endl;
        std::cout << "Total references found: " << total_references_found << std::endl;
        std::cout << "Queries with early termination: " << early_terminations << std::endl;
        std::cout << "Queries without valid matches: " << queries_without_matches << std::endl;
        std::cout << "\nAverage time per bucket ID: " << duration_matcher.count() / bucket_ids.size() << " µs" << std::endl;
        std::cout << "Average time per comparison: " << std::fixed << std::setprecision(3) << avg_time_per_comparison << " µs" << std::endl;

        std::cout << "\n=== Displaying Results ===" << std::endl;
        std::cout << "Do you want to display all query-reference pairs? (y/n):";
        std::string user_input;
        std::getline(std::cin, user_input);

        if (user_input == "y" || user_input == "Y") {            
            int displayed_count = 0;
            
            for (size_t i = 0; i < bucket_ids.size(); i++) {
                
                if (results[i].match_count > 0) {
                    for (int32_t j = 0; j < results[i].match_count && j < 16; j++) {
                        int32_t ref_idx = results[i].best_match_indices[j];
                        if (ref_idx >= 0 && ref_idx < static_cast<int32_t>(reference_database.size())) {
                            std::cout << reference_database[ref_idx] << ";" << bucket_ids[i] << std::endl;
                            displayed_count++;
                        }
                    }
                }
            }
            
            std::cout << "Total pairs displayed: " << displayed_count << std::endl;
        }

        return 0;
        
    } catch (const sycl::exception& e) {
        std::cerr << "SYCL exception: " << e.what() << std::endl;
        return 1;
    } catch (const std::exception& e) {
        std::cerr << "Standard exception: " << e.what() << std::endl;
        return 1;
    }
}
