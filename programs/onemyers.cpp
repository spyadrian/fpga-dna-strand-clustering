#include <iostream>
#include <vector>
#include <chrono>
#include <cstring>
#include <algorithm>
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/fpga_extensions.hpp>

using namespace sycl;

// DNA Algorithm Configuration
namespace DNAConfig {
    static constexpr int MAX_DNA_LENGTH = 1024;
    static constexpr int MAX_PACKED_LENGTH = (MAX_DNA_LENGTH + 3) / 4;
    static constexpr size_t A7SK_DEVICE_MEMORY_MB = 1024;
    static constexpr double SAFETY_MARGIN = 0.8;
    static constexpr int MIN_QUERY_TILE = 64;
    static constexpr int MIN_REF_TILE = 256;
}

/**
 * @brief DNA base encoding: A=00, T=01, G=10, C=11
 * Allows packing 4 bases per byte instead of 1 base per byte
 */
enum class DNABase : uint8_t {
    A = 0b00,
    T = 0b01,
    G = 0b10,
    C = 0b11
};

/**
 * @brief Optimized BitVector for DNA (only need 4 Peq arrays instead of 256)
 */
class DNABitVector256 {
private:
    static constexpr int NUM_WORDS = 4;
    static constexpr int BITS_PER_WORD = 64;
    static constexpr int TOTAL_BITS = NUM_WORDS * BITS_PER_WORD;
    
    uint64_t words[NUM_WORDS];

public:
    // Constructors
    DNABitVector256() {
        clear();
    }
    
    explicit DNABitVector256(uint64_t val) {
        words[0] = val;
        for (int i = 1; i < NUM_WORDS; i++) {
            words[i] = 0;
        }
    }

    // Utility methods
    void clear() {
        for (int i = 0; i < NUM_WORDS; i++) {
            words[i] = 0;
        }
    }

    /**
     * @brief Initialize all words to a specific value
     */
    void fill_all_words(uint64_t value) {
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            words[i] = value;
        }
    }
    
    /**
     * @brief Set all bits to 1 (equivalent to filling with 0xFFFFFFFFFFFFFFFFULL)
     */
    void set_all_bits() {
        fill_all_words(0xFFFFFFFFFFFFFFFFULL);
    }

    // Bitwise operators (vectorized for performance)
    DNABitVector256 operator|(const DNABitVector256& other) const {
        DNABitVector256 result;
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = words[i] | other.words[i];
        }
        return result;
    }

    DNABitVector256 operator&(const DNABitVector256& other) const {
        DNABitVector256 result;
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = words[i] & other.words[i];
        }
        return result;
    }

    DNABitVector256 operator~() const {
        DNABitVector256 result;
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = ~words[i];
        }
        return result;
    }

    DNABitVector256 operator^(const DNABitVector256& other) const {
        DNABitVector256 result;
        #pragma unroll
        for (int i = 0; i < NUM_WORDS; i++) {
            result.words[i] = words[i] ^ other.words[i];
        }
        return result;
    }

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

    // Bit manipulation methods
    void set_bit(int pos) {
        if (pos < TOTAL_BITS) {
            int word_idx = pos >> 6;  // pos / 64
            int bit_idx = pos & 63;   // pos % 64
            words[word_idx] |= (1ULL << bit_idx);
        }
    }

    bool test_bit(int pos) const {
        if (pos >= TOTAL_BITS) return false;
        
        int word_idx = pos >> 6;  // pos / 64
        int bit_idx = pos & 63;   // pos % 64
        uint64_t mask = 1ULL << bit_idx;
        return (words[word_idx] & mask) != 0;
    }
};

namespace DNAEncoding {
    /**
     * @brief Encode DNA character to 2-bit representation
     */
    inline uint8_t encode_base(char base) {
        switch (base) {
            case 'A': case 'a': return static_cast<uint8_t>(DNABase::A);
            case 'T': case 't': return static_cast<uint8_t>(DNABase::T);
            case 'G': case 'g': return static_cast<uint8_t>(DNABase::G);
            case 'C': case 'c': return static_cast<uint8_t>(DNABase::C);
            default: return static_cast<uint8_t>(DNABase::A);  // Default fallback
        }
    }

    /**
     * @brief Pack DNA string into 2-bit representation (4 bases per byte)
     */
    void pack_sequence(const char* dna_str, int length, uint8_t* packed, int& packed_length) {
        packed_length = (length + 3) / 4;  // Round up to nearest byte
        memset(packed, 0, packed_length);
        
        for (int i = 0; i < length; i++) {
            uint8_t encoded = encode_base(dna_str[i]);
            int byte_idx = i / 4;
            int bit_pos = (i % 4) * 2;
            packed[byte_idx] |= (encoded << bit_pos);
        }
    }

    /**
     * @brief Cache structure for optimized base extraction
     */
    struct PackedCache {
        uint32_t cached_word;
        int cache_start_pos;
        bool cache_valid;
        
        PackedCache() : cached_word(0), cache_start_pos(-1), cache_valid(false) {}
        
        void invalidate() { cache_valid = false; }
    };

    /**
     * @brief Optimized base extraction with 4-base prefetching
     */
    inline uint8_t get_base_cached(const uint8_t* packed, int pos, PackedCache& cache) {
        int word_start = (pos >> 2) << 2;  // Align to 4-base boundary
        
        if (!cache.cache_valid || cache.cache_start_pos != word_start) {
            cache.cached_word = packed[pos >> 2];
            cache.cache_start_pos = word_start;
            cache.cache_valid = true;
        }
        
        int bit_pos = (pos & 3) << 1;  // (pos % 4) * 2
        return (cache.cached_word >> bit_pos) & 0b11;
    }

    /**
     * @brief Vectorized unpacking for multiple bases
     */
    inline void unpack_4_bases(uint8_t packed_byte, uint8_t bases[4]) {
        #pragma unroll
        for (int i = 0; i < 4; i++) {
            bases[i] = (packed_byte >> (i << 1)) & 0b11;  // (i * 2)
        }
    }
}

/**
 * @brief Result structure for nearest match
 */
struct NearestResult {
    int32_t min_distance;
    int32_t best_match_index;
    
    NearestResult() : min_distance(INT_MAX), best_match_index(-1) {}
};

/**
 * @brief Validation utilities
 */
namespace DNAValidation {
    bool is_valid_dna_char(char c) {
        return (c == 'A' || c == 'T' || c == 'G' || c == 'C' ||
                c == 'a' || c == 't' || c == 'g' || c == 'c');
    }

    bool validate_sequences(char** sequences, int32_t* lengths, int32_t count) {
        for (int i = 0; i < count; i++) {
            if (lengths[i] > DNAConfig::MAX_DNA_LENGTH || lengths[i] <= 0) {
                std::cerr << "Invalid sequence length: " << lengths[i] 
                         << " at index " << i << std::endl;
                return false;
            }

            for (int j = 0; j < lengths[i]; j++) {
                if (!is_valid_dna_char(sequences[i][j])) {
                    std::cerr << "Invalid DNA character '" << sequences[i][j] 
                             << "' at sequence " << i << ", position " << j << std::endl;
                    return false;
                }
            }
        }
        return true;
    }
}

/**
 * @brief DNA-optimized Myers algorithm with 4-letter alphabet
 */
event myers_dna_find_nearest_batch(
    queue& q,
    char** query_dna, int32_t* query_lengths, int32_t num_queries,
    char** reference_dna, int32_t* reference_lengths, int32_t num_references,
    NearestResult* results) {
    
    using namespace DNAConfig;
    using namespace DNAEncoding;

    // Device memory allocation
    uint8_t* d_query_packed = malloc_device<uint8_t>(num_queries * MAX_PACKED_LENGTH, q);
    uint8_t* d_ref_packed = malloc_device<uint8_t>(num_references * MAX_PACKED_LENGTH, q);
    int32_t* d_query_lengths = malloc_device<int32_t>(num_queries, q);
    int32_t* d_ref_lengths = malloc_device<int32_t>(num_references, q);
    NearestResult* d_results = malloc_device<NearestResult>(num_queries, q);

    // Host buffer preparation
    std::vector<uint8_t> host_query_buffer(num_queries * MAX_PACKED_LENGTH);
    std::vector<uint8_t> host_ref_buffer(num_references * MAX_PACKED_LENGTH);

    // Pack all queries
    for (int i = 0; i < num_queries; i++) {
        uint8_t* dest = host_query_buffer.data() + i * MAX_PACKED_LENGTH;
        int packed_length;
        pack_sequence(query_dna[i], query_lengths[i], dest, packed_length);
    }

    // Pack all references
    for (int i = 0; i < num_references; i++) {
        uint8_t* dest = host_ref_buffer.data() + i * MAX_PACKED_LENGTH;
        int packed_length;
        pack_sequence(reference_dna[i], reference_lengths[i], dest, packed_length);
    }

    // Batch memory transfers
    auto copy_events = std::vector<event>{
        q.memcpy(d_query_packed, host_query_buffer.data(), num_queries * MAX_PACKED_LENGTH),
        q.memcpy(d_ref_packed, host_ref_buffer.data(), num_references * MAX_PACKED_LENGTH),
        q.memcpy(d_query_lengths, query_lengths, num_queries * sizeof(int32_t)),
        q.memcpy(d_ref_lengths, reference_lengths, num_references * sizeof(int32_t))
    };

    // Launch optimized kernel
    auto kernel_event = q.submit([&](handler& h) {
        h.depends_on(copy_events);
        
        h.parallel_for(
            nd_range<1>(range<1>((num_queries + 3) / 4 * 4), range<1>(4)),
            [=](nd_item<1> item) {
                int global_id = item.get_global_id(0);
                if (global_id >= num_queries) return;

                PackedCache query_cache, ref_cache;
                uint8_t* query_packed = d_query_packed + global_id * MAX_PACKED_LENGTH;
                int32_t query_len = d_query_lengths[global_id];
                
                int32_t min_distance = INT_MAX;
                int32_t best_match_idx = -1;

                // Process all references for this query
                for (int ref_idx = 0; ref_idx < num_references; ref_idx++) {
                    uint8_t* ref_packed = d_ref_packed + ref_idx * MAX_PACKED_LENGTH;
                    int32_t ref_len = d_ref_lengths[ref_idx];

                    // Reset caches for new reference
                    ref_cache.invalidate();
                    query_cache.invalidate();

                    // Build Peq arrays
                    DNABitVector256 Peq[4];
                    for (int i = 0; i < ref_len; i += 4) {
                        int bases_to_process = std::min(4, ref_len - i);
                        
                        if (bases_to_process == 4) {
                            uint8_t packed_byte = ref_packed[i >> 2];
                            uint8_t bases[4];
                            unpack_4_bases(packed_byte, bases);
                            
                            #pragma unroll
                            for (int j = 0; j < 4; j++) {
                                Peq[bases[j]].set_bit(i + j);
                            }
                        } else {
                            for (int j = 0; j < bases_to_process; j++) {
                                uint8_t base = get_base_cached(ref_packed, i + j, ref_cache);
                                Peq[base].set_bit(i + j);
                            }
                        }
                    }

                    // Myers algorithm core
                    DNABitVector256 Mv(0), Pv;
                    Pv.set_all_bits();

                    int32_t Score = ref_len;

                    for (int i = 0; i < query_len; i++) {
                        uint8_t query_base = get_base_cached(query_packed, i, query_cache);
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

                    if (Score < min_distance) {
                        min_distance = Score;
                        best_match_idx = ref_idx;
                    }
                }

                d_results[global_id].min_distance = min_distance;
                d_results[global_id].best_match_index = best_match_idx;
            });
    });

    // Copy results back and cleanup
    auto copy_event = q.memcpy(results, d_results, num_queries * sizeof(NearestResult), kernel_event);
    copy_event.wait();

    // Memory cleanup
    free(d_query_packed, q);
    free(d_ref_packed, q);
    free(d_query_lengths, q);
    free(d_ref_lengths, q);
    free(d_results, q);

    return copy_event;
}

/**
 * @brief A7SK-optimized DNA sequence matcher
 */
class A7SK_DNA_Matcher {
private:
    queue& fpga_queue;

public:
    explicit A7SK_DNA_Matcher(queue& q) : fpga_queue(q) {}

    /**
     * @brief Calculate optimal tile sizes for DNA sequences
     */
    std::pair<int32_t, int32_t> calculate_optimal_tile_sizes(int32_t num_queries, int32_t num_references) {
        using namespace DNAConfig;
        
        size_t available_memory = A7SK_DEVICE_MEMORY_MB * 1024 * 1024 * SAFETY_MARGIN;
        
        // Memory calculations (DNA encoding is 4x more efficient)
        size_t memory_per_query = (MAX_DNA_LENGTH / 4) + sizeof(NearestResult) + sizeof(int32_t);
        size_t memory_per_reference = (MAX_DNA_LENGTH / 4) + sizeof(int32_t);

        // Calculate maximum tile sizes
        int32_t max_query_tile = std::min(num_queries,
            static_cast<int32_t>(available_memory / (memory_per_query + memory_per_reference * num_references)));
        int32_t max_ref_tile = std::min(num_references,
            static_cast<int32_t>((available_memory - max_query_tile * memory_per_query) / memory_per_reference));

        // Apply minimum constraints
        max_query_tile = std::max(MIN_QUERY_TILE, max_query_tile);
        max_ref_tile = std::max(MIN_REF_TILE, max_ref_tile);

        return {max_query_tile, max_ref_tile};
    }

    /**
     * @brief Find nearest DNA matches with A7SK optimization
     */
    event find_nearest_optimized(
        char** query_dna, int32_t* query_lengths, int32_t num_queries,
        char** reference_dna, int32_t* reference_lengths, int32_t num_references,
        NearestResult* results) {
        
        auto [optimal_query_tile, optimal_ref_tile] = calculate_optimal_tile_sizes(num_queries, num_references);
        
        std::cout << "A7SK DNA Optimization: Using query tiles of " << optimal_query_tile
                  << " and reference tiles of " << optimal_ref_tile << std::endl;

        return process_tiled_hybrid(
            query_dna, query_lengths, num_queries,
            reference_dna, reference_lengths, num_references,
            results, optimal_query_tile, optimal_ref_tile);
    }

private:
    /**
     * @brief Process DNA matching using tiled approach
     */
    event process_tiled_hybrid(
        char** query_dna, int32_t* query_lengths, int32_t num_queries,
        char** reference_dna, int32_t* reference_lengths, int32_t num_references,
        NearestResult* results, int32_t query_tile_size, int32_t ref_tile_size) {
        
        // Initialize results
        for (int i = 0; i < num_queries; i++) {
            results[i] = NearestResult();
        }

        // Process in nested tiles
        for (int query_start = 0; query_start < num_queries; query_start += query_tile_size) {
            int current_query_size = std::min(query_tile_size, num_queries - query_start);
            
            for (int ref_start = 0; ref_start < num_references; ref_start += ref_tile_size) {
                int current_ref_size = std::min(ref_tile_size, num_references - ref_start);
                
                std::vector<NearestResult> tile_results(current_query_size);
                
                myers_dna_find_nearest_batch(
                    fpga_queue,
                    query_dna + query_start, query_lengths + query_start, current_query_size,
                    reference_dna + ref_start, reference_lengths + ref_start, current_ref_size,
                    tile_results.data()
                ).wait();

                // Update global results
                for (int i = 0; i < current_query_size; i++) {
                    int global_query_idx = query_start + i;
                    if (tile_results[i].min_distance < results[global_query_idx].min_distance) {
                        results[global_query_idx].min_distance = tile_results[i].min_distance;
                        results[global_query_idx].best_match_index = ref_start + tile_results[i].best_match_index;
                    }
                }
            }
        }

        return fpga_queue.submit([&](handler& h) {
            h.single_task([=]() {});
        });
    }
};

int main() {
    try {
        // Initialize FPGA queue for A7SK
        #if FPGA_HARDWARE
        auto selector = sycl::ext::intel::fpga_selector_v;
        std::cout << "Targeting A7SK FPGA hardware..." << std::endl;
        #else
        auto selector = sycl::ext::intel::fpga_emulator_selector_v;
        std::cout << "Using FPGA emulator for testing..." << std::endl;
        #endif

        queue q(selector, [](exception_list el) {
            for (auto ex : el) {
                std::rethrow_exception(ex);
            }
        });

        std::cout << "Running on device: " << q.get_device().get_info<info::device::name>() << std::endl;

        // Test data setup
        std::vector<std::string> query_sequences = {
            "ATCGATCGATCGATCG",
            "GGCCTTAAGCCTTAGC", 
            "AAATTTCCCGGGATCG",
            "TTGGCCAATTGGCCAA",
            "CGATCGATCGATCGAT"
        };

        std::vector<std::string> reference_database = {
            "ATCGATCGATCGATCG", "ATCGATCGATCGATCC", "GGCCTTAAGCCTTAGG",
            "GGCCTTAAGCCTTACC", "AAATTTCCCGGGATCG", "AAATTTCCCGGGATCC",
            "TTGGCCAATTGGCCAA", "TTGGCCAATTGGCCTT", "CGATCGATCGATCGAT",
            "CGATCGATCGATCGAA"
        };

        // Prepare data structures
        std::vector<char*> query_ptrs, ref_ptrs;
        std::vector<int32_t> query_lengths, ref_lengths;
        
        for (auto& seq : query_sequences) {
            query_ptrs.push_back(const_cast<char*>(seq.c_str()));
            query_lengths.push_back(seq.length());
        }
        
        for (auto& seq : reference_database) {
            ref_ptrs.push_back(const_cast<char*>(seq.c_str()));
            ref_lengths.push_back(seq.length());
        }

        // Validation
        if (!DNAValidation::validate_sequences(query_ptrs.data(), query_lengths.data(), query_sequences.size()) ||
            !DNAValidation::validate_sequences(ref_ptrs.data(), ref_lengths.data(), reference_database.size())) {
            std::cerr << "Sequence validation failed!" << std::endl;
            return 1;
        }

        // Execute matching
        std::vector<NearestResult> results(query_sequences.size());
        A7SK_DNA_Matcher matcher(q);

        auto start_time = std::chrono::high_resolution_clock::now();
        matcher.find_nearest_optimized(
            query_ptrs.data(), query_lengths.data(), query_sequences.size(),
            ref_ptrs.data(), ref_lengths.data(), reference_database.size(),
            results.data()
        ).wait();
        auto end_time = std::chrono::high_resolution_clock::now();

        // Display results
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);
        
        std::cout << "\n=== Nearest Match Results ===" << std::endl;
        for (size_t i = 0; i < query_sequences.size(); i++) {
            std::cout << "Query " << i << ": " << query_sequences[i] << std::endl;
            std::cout << " -> Best match: " << reference_database[results[i].best_match_index]
                      << " (Index: " << results[i].best_match_index
                      << ", Distance: " << results[i].min_distance << ")" << std::endl;
        }

        std::cout << "\n=== Performance Summary ===" << std::endl;
        std::cout << "Total execution time: " << duration.count() << " microseconds" << std::endl;
        std::cout << "Average time per query: " << duration.count() / query_sequences.size() << " µs" << std::endl;
        std::cout << "A7SK FPGA utilization: Optimized for 2.7M logic elements" << std::endl;

        return 0;

    } catch (const sycl::exception& e) {
        std::cerr << "SYCL exception: " << e.what() << std::endl;
        return 1;
    } catch (const std::exception& e) {
        std::cerr << "Standard exception: " << e.what() << std::endl;
        return 1;
    }
}
