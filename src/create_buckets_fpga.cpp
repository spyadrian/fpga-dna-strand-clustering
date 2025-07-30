#include "onejoin.hpp"

using namespace cl::sycl;
using namespace oneapi::dpl::execution;
using namespace std;

Time timer_fpga(false);

void inititalize_dictory_fpga(uint8_t *dictory) {

  if (NUM_CHAR == 4) {
    dictory[static_cast<uint8_t>('A')] = 0;
    dictory[static_cast<uint8_t>('C')] = 1;
    dictory[static_cast<uint8_t>('G')] = 2;
    dictory[static_cast<uint8_t>('T')] = 3;
  } else if (NUM_CHAR == 5) {
    dictory[static_cast<uint8_t>('A')] = 0;
    dictory[static_cast<uint8_t>('C')] = 1;
    dictory[static_cast<uint8_t>('G')] = 2;
    dictory[static_cast<uint8_t>('T')] = 3;
    dictory[static_cast<uint8_t>('N')] = 4;
  } else if (NUM_CHAR == 26 || NUM_CHAR == 25) {
    int j = 0;
    for (int i = (int)'A'; i <= (int)'Z'; i++) {
      dictory[i] = j;
      j++;
    }
  } else if (NUM_CHAR == 37) {
    int j = 0;
    for (int i = (int)'A'; i <= (int)'Z'; i++) {
      dictory[i] = j;
      j++;
    }
    for (int i = (int)'0'; i <= (int)'9'; i++) {
      dictory[i] = j;
      j++;
    }
    dictory[static_cast<uint8_t>(' ')] = j;
  } else {
    BOOST_LOG_TRIVIAL(error)
        << "input error: check the dictory of your input\n";
    exit(-1);
  }
}

void create_buckets_usm(queue &device_queue, char *usm_embdata,
                       buckets_t *usm_buckets, size_t *usm_batch_size, 
                       size_t split_size, size_t *usm_split_offset,
                       uint32_t *usm_a, size_t *usm_len_output,
                       uint8_t *usm_dict) {

  BOOST_LOG_TRIVIAL(info)
      << "\t\tTask: Buckets Generation\tDevice: "
      << device_queue.get_device().get_info<info::device::name>() << std::endl;
  BOOST_LOG_TRIVIAL(debug) << "\t\tSplit size: " << split_size;

  range<2> glob_range(split_size * NUM_STR * NUM_REP, NUM_HASH);

  BOOST_LOG_TRIVIAL(debug) << "\t\tGlobal range: "
                           << "(" << glob_range[0] << ", " << glob_range[1]
                           << ")" << std::endl;

  device_queue.submit([&](handler &cgh) {
    // Executing kernel with USM pointers
    cgh.parallel_for<class CreateBucketsUSM>(
        range<2>(glob_range),
        [=, NUM_REP = NUM_REP, NUM_CHAR = NUM_CHAR, NUM_BITS = NUM_BITS,
         NUM_STR = NUM_STR, HASH_SZ = HASH_SZ](item<2> index) {
          int itq = index[0];
          int i = itq / (NUM_STR * NUM_REP) + usm_split_offset[0];
          int tq = itq % (NUM_STR * NUM_REP);
          int t = tq / NUM_REP;
          int q = tq % NUM_REP;

          int k = index[1];

          int id = 0;
          char dict_index = 0;
          int id_mod = 0;
          int digit = -1;

          for (int j = 0; j < NUM_BITS; j++) {
            digit = k * NUM_BITS + j;
            dict_index = usm_embdata[ABSPOS(i % usm_batch_size[0], t, q,
                                           digit, usm_len_output[0])];
            id += (usm_dict[dict_index]) * usm_a[j];
          }

          id_mod = id % HASH_SZ;
          size_t output_position = index.get_linear_id();

          usm_buckets[output_position].idx_rand_str = t;
          usm_buckets[output_position].idx_hash_func = k;
          usm_buckets[output_position].hash_id = id_mod;
          usm_buckets[output_position].idx_str = i;
          usm_buckets[output_position].idx_rep = q;
        });
  });
}

void create_buckets_wrapper_fpga(queue &q, char **embdata,
                                vector<buckets_t> &buckets, size_t n_batches,
                                vector<batch_hdr> &batch_hdrs, vector<int> &a,
                                vector<int> &lshnumber, size_t len_output) {

  BOOST_LOG_TRIVIAL(info) << "Create buckets" << std::endl;
  BOOST_LOG_TRIVIAL(debug) << "\tLen output: " << len_output;

  {
    uint8_t dictory[256] = {0};
    inititalize_dictory_fpga(dictory);

    size_t max_batch_size = batch_hdrs[0].size; // all values are equals, except for the last one

    // Allocate USM memory for dictionary (shared between host and device)
    uint8_t *usm_dict = malloc_shared<uint8_t>(256, q);
    memcpy(usm_dict, dictory, 256 * sizeof(uint8_t));

    // Allocate USM memory for arrays a and lshnumber (device memory for better performance)
    uint32_t *usm_a = malloc_device<uint32_t>(a.size(), q);
    uint32_t *usm_lshnumber = malloc_device<uint32_t>(lshnumber.size(), q);

    // Copy host data to device USM memory
    q.memcpy(usm_a, a.data(), a.size() * sizeof(uint32_t));
    q.memcpy(usm_lshnumber, lshnumber.data(), lshnumber.size() * sizeof(uint32_t));

    // Allocate USM memory for scalar values (shared memory for easy access)
    size_t *usm_batch_size = malloc_shared<size_t>(1, q);
    size_t *usm_len_output = malloc_shared<size_t>(1, q);
    *usm_batch_size = max_batch_size;
    *usm_len_output = len_output;

    timer_fpga.start_time(buckets::compute); // Start computing directly

    BOOST_LOG_TRIVIAL(info) << "\tStart computing on single device..." << std::endl;

    // Process all batches on the single queue
    for (int n = 0; n < n_batches; n++) {
      size_t loc_split_size = batch_hdrs[n].size;
      size_t offset = batch_hdrs[n].offset;
      
      cout << "\n\tSet offset to: " << offset << std::endl;

      // Allocate USM memory for buckets output (device memory)
      buckets_t *usm_buckets = malloc_device<buckets_t>(
          loc_split_size * NUM_STR * NUM_HASH * NUM_REP, q);

      // Allocate USM memory for embedded data (device memory)
      size_t emb_size = static_cast<size_t>(loc_split_size * NUM_STR * NUM_REP * len_output);
      char *usm_embdata = malloc_device<char>(emb_size, q);

      // Copy embedded data to device
      q.memcpy(usm_embdata, embdata[n], emb_size * sizeof(char));

      // Allocate USM memory for offset (shared memory)
      size_t *usm_offset = malloc_shared<size_t>(1, q);
      *usm_offset = offset;

      // Wait for all memory operations to complete before kernel execution
      q.wait();

      // Call the kernel with USM pointers instead of buffers
      create_buckets_usm(q, usm_embdata, usm_buckets,
                        usm_batch_size, loc_split_size,
                        usm_offset, usm_a,
                        usm_len_output, usm_dict);

      // Wait for kernel completion
      q.wait();

      // Copy results back to host buckets vector
      buckets_t *host_buckets_ptr = buckets.data() + offset * NUM_REP * NUM_HASH * NUM_STR;
      q.memcpy(host_buckets_ptr, usm_buckets, 
               loc_split_size * NUM_STR * NUM_HASH * NUM_REP * sizeof(buckets_t));
      
      // Wait for copy completion
      q.wait();

      // Free USM memory for this iteration
      free(usm_buckets, q);
      free(usm_embdata, q);
      free(usm_offset, q);
    }

    // Free shared USM memory
    free(usm_dict, q);
    free(usm_a, q);
    free(usm_lshnumber, q);
    free(usm_batch_size, q);
    free(usm_len_output, q);

  } // End of scope

  timer_fpga.end_time(buckets::compute);
}
