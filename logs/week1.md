<!--- TOC --->

# Table of contents

1. [Monday 26 May](#26may)
2. [Tuesday 27 May](#27may)
3. [Wednesday 28 May](#28may)
4. [Thursday 29 May](#29may)
5. [Friday 30 May](#30may)

<!--- BODY --->

# Week 1 <a name="week1"></a>

### Tasks

- [x] Set up and install SYCL tools
- [x] Get started with SYCL (SYCL Academy)
- [ ] Analyse OneJoin Algorithm Implementation

### Links

- [SYCL](https://sycl.tech/)
- [SYCL Academy](https://sycl.tech/getting-started/academy)
- [Git SYCL Academy](https://github.com/codeplaysoftware/syclacademy)
- [Get the Intel oneAPI Base Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html?packages=oneapi-toolkit&oneapi-toolkit-os=linux&oneapi-lin=offline)
- [OneJoin implementation C++/SYCL](https://github.com/Eug9/oneoligo)


## Monday : 26 May <a name="26may"></a>

After installing the *Intel oneAPI Base Toolkit*, I launched the `intel-oneapi-base-toolkit-2025.1.3.7_offline.sh` and installed these components :
- DPC++ Compatibility Tool (mendatory)
- DPC++ Library (mendatory)
- Threading Building Blocks (mendatory)
- DPC++/C++ Compiler (mendatory)
- Collective Communications Library (why not)
- VTune(TM) Profiler (why not)

After that I add this to my `.zshrc` (equivalent of `.bashrc` for zsh) :
```
source /home/adrian/intel/oneapi/setvars.sh
```

To start SYCL Academy I cloned their repos like that :
```
git clone --recursive https://github.com/codeplaysoftware/syclacademy.git
```

And start reading and exercising.


## Tuesday : 27 May <a name="27may"></a>

Doing SYCL Academy today.

### 1. What is SYCL

"SYCL is a single source, high-level, standard C++ programming model, that can target a range of heterogeneous platforms"

Command to compile a `.cpp` file using SYCL :
```
icpx -fsycl solution.cpp -o solution
```

### 2. Enqueueing a Kernel

In SYCL all work is submitted via commands to a queue.
The queue has an associated device that any commands enqueued to it will target.

With `sycl-ls` I see my CPU and first GPU.
The seconds doesn't appear because it used CUDA that is not supported.
```
[opencl:cpu][opencl:0] Intel(R) OpenCL, Intel(R) Core(TM) i7-1065G7 CPU @ 1.30GHz OpenCL 3.0 (Build 0) [2025.19.4.0.18_160000.xmain-hotfix]
[opencl:gpu][opencl:1] rusticl, Mesa Intel(R) Iris(R) Plus Graphics (ICL GT2) OpenCL 3.0  [25.1.0-cachyos1.4]
```

I only managed to compile the exercise with the CPU because I don't have the right backend to use the GPU.
```
🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:cpu ./solution
Hello World!
[SUCCESS] Test passed
```

I could use a docker for the GPU, but "j'ai d'autre chat à fouetter".

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Enqueueing_a_Kernel/solution.cpp)

### 3. Managing Data

In SYCL there are two models for managing data:

- The `buffer`/`accessor` model: `buffer` are shared memory between host and device, you handle them via `accessor`
- The USM (unified shared memory) model: allows three type of memory: `device`, `host` and `shared`.
  `malloc_device` allows memory on the device, you need then to copy value on it from the host.
  Memory allows with `malloc_shared` is accessible from the host and device (performance might be poor).

For the GPU, it's seems like mine don't even support USM.

```
🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:gpu ./solution
terminate called after throwing an instance of 'sycl::_V1::exception'
  what():  Device does not support USM device allocations!
```

For the CPU it worked easily :

```
🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:cpu ./solution
[SUCCESS] Test passed
[SUCCESS] Test passed
```

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Managing_Data/solution.cpp)


## Wednesday : 28 May <a name="28may"></a>

SYCL Academy loading...

### 4. Handling Errors and Debugging

In SYCL errors are handled by throwing exceptions.
There are two kinds of error:

- Synchronous errors (thrown in user thread from host).
- Asynchronous errors (thrown by the SYCL scheduler from device).

They can be catch with a `try catch` statement and an async handler.
Any SYCL application can be debugged on the host device by switching the queue for a host queue.

The solution worked on both CPU and GPU which is surprising but cool.

```
🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:gpu ./solution
Exception caught: accessor with requested offset and range would exceed the bounds of the buffer
[SUCCESS] Test passed

🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:cpu ./solution
Exception caught: accessor with requested offset and range would exceed the bounds of the buffer
[SUCCESS] Test passed
```

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Handling_Errors/solution.cpp)

### 5. Device Discovery

The SYCL runtime will discover a set of platforms in the system and also all devices that are available for each of those platforms.

A device selector is is a callable C++ object which defines a heuristic for scoring devices.
Used to query all devices and return the one with the highest "score".
A device with a negative score will never be chosen.

On the solution, they choose the device with a custom device selector getting a GPU or nothing.
Launching the solution via `./solution` worked well and choose my first GPU.

```
🎗️ ❯ ./solution
Chosen device: Mesa Intel(R) Iris(R) Plus Graphics (ICL GT2)
[SUCCESS] Test passed
```

Forcing the GPU worked too, but forcing the CPU with `ONEAPI_DEVICE_SELECTOR=opencl:cpu` resulted in an error.

```
🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:cpu ./solution
Exception caught: No device of requested type available. Please check https://software.intel.com/content/www/us/en/develop/articles/intel-oneapi-dpcpp-system-requirements.html
[FAILURE] SYCLAcademy::equal(r, 42) failed in solution.cpp:71:main
Exiting
```

When trying with the `sycl::gpu_selector_v` and `sycl::cpu_selector_v` it worked well, if we don't force the wrong device.

[See solution](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Device_Discovery/solution.cpp)

### 6. Data Parallelism

**Task parallelism** is where you have several, possibly distinct tasks executing in parallel.
In task parallelism you optimize for latency.
**Data parallelism** is where you have the same task being performed on multiple elements of data.
In data parallelism you optimize for throughput.

**SPMD** (Single Program, Multiple Data) is a parallel programming paradigm where multiple processors execute the same program, but on different data.

In SYCL kernel functions are executed by work- items.
You can think of a work-item as a thread of execution.
Each work-item will execute a SYCL kernel function from start to end.
A work-item can run on CPU threads, SIMD lanes, GPU threads, or any other kind of processing element.

SYCL kernel functions are invoked within an nd-range.
An nd-range has a number of work-groups and subsequently a number of work-items.

Worked on CPU !

```
🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:cpu ./solution
[SUCCESS] Test passed
[SUCCESS] Test passed
```

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Data_Parallelism/solution.cpp)

### 7. Introduction to USM

Unified shared memory (USM) provides an alternative pointer-based data management model to the accessor-buffer model

- Unified virtual address space
- Pointer-based structures
- Explicit memory management
- Shared memory allocations

So when should you use the accessor/buffer mode and when should you use the USM model?

- The buffer/accessor provides guaranteed consistency and automatically manages dependencies
   - Recommended when you need to iterate over or prototype your application
   - Recommended for maximum performance portability
   - Provides a lot of information to the SYCL runtime which can perform many optimizations automatically
- The USM model provides a lower-level pointer-based solution with fine grained control
   - Recommended when porting existing C++ applications or using pointer-based structures
   - User has responsibility for certain aspects relevant for performance (e.g. data transfers or data prefetches)

Easy-peasy, only my CPU handle USM.

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Introduction_to_USM/solution.cpp)

### 8. Using USM

Here is a function using all of the tools to manipulate USM :

```c
int square_number(int x){

  auto myQueue = queue{usm_selector{}};

  auto devicePtr = malloc_device<int>(1, myQueue);

  myQueue.memcpy(devicePtr, &x, sizeof(int)).wait();

  myQueue.single_task<square>([=](){
    *devicePtr = (*devicePtr) * (*devicePtr);
  }).wait();

  myQueue.memcpy(&x, devicePtr, sizeof(int)).wait();

  free(devicePtr, myQueue);

  return x;
}
```

It's like regular memory in C.

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Using_USM/solution.cpp)

### 9. Asynchronous Execution

All command submitted to a queue are done so asynchronously.
The functions return immediately and the command is run in a background thread.
This includes individual commands like `memcpy` and collections of commands derived from a command group.
This means you have to synchronize with those commands.

Calling `wait` or `wait_and_throw` on a queue will wait for all commands enqueued to it to complete.

- When using the USM data management model you can synchronize the same way you would for kernel functions, calling wait on an event or the queue.
- When using the buffer/access data management model command groups don't automatically copy data back so there are other ways to synchronize with the data.
   - Creating a `host_accessor`
   - Destroying `the buffer`

A `host_accessor` gives immediate access to the data managed by a buffer in the host application.
This will wait for any kernel functions accessing the buffer to complete.

The solution propose a lot of different ways of access memory.
For `buffer` and `usm` it's mostly about putting a `wait` at the right spot.
For the `host_buffer`, it wait automatically to be updated before to compute what you ask it to do.
They all worked with my CPU :

```
🎗️ ❯ ./solution
[SUCCESS] Test passed
[SUCCESS] Test passed
[SUCCESS] Test passed
[SUCCESS] Test passed
[SUCCESS] Test passed
[SUCCESS] Test passed
```

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Asynchronous_Execution/solution.cpp)


## Thursday : 29 May <a name="29may"></a>

Keep doing SYCL Academy !

### 10. Data and Dependencies

There are two ways to move data and create dependencies between kernel functions in SYCL :

- Buffer/accessor data movement model
    - Data dependencies analysis
    - Implicit data movement
- USM data movement model
    - Manual chaining of dependencies
    - Explicit data movement

For data flow with buffers and accessors.
An `accessor` describes what data a kernel function is accessing and how it is accessing it.
The buffer object uses this information to create infer dependencies and data movement.

```c
sycl::buffer buf {data, sycl::range{1024}};

gpuQueue.submit([&](sycl::handler &cgh) {
  sycl::accessor acc {buf, cgh};

  // [...]
});
```

The USM data management model data model is prescriptive.
Dependencies are defined explicitly by passing around `event` objects.
Passing those `event` objects when enqueueing other commands creates dependencies.
The user is responsible for ensuring data dependencies and consistency are maintained

```c
auto e1 = gpuQueue.memcpy(devicePtrA, dataA, sizeof(int));

auto e3 = gpuQueue.parallel_for<kernel_a>(sycl::range{1024}, e1, [=](sycl::id<1> idx) {
  devicePtrA[idx] = /* some computation */ 
});
```

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Data_and_Dependencies/solution.cpp)

### 11. In Order Queue

SYCL `queues` are by default out-of-order.
This means commands are allowed to be overlapped, re-ordered, and executed concurrently, providing dependencies are honoured to ensure consistency.

SYCL `queues` can be configured to be in-order.
This mean commands must execute strictly in the order they were enqueued.

With USM, to handle dependencies you need to define an ordering manually (error prone) with `cgh.depends_on(event)`.
Buffer/accessors models automatically handle dependencies for you.

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/In_Order_Queue/solution_vector_add.cpp)

### 12. Advanced Data Flow

When using the buffer/accessor model a `buffer` can manage already allocated memory or have the SYCL runtime allocate it.
To prevent the runtime allocation memory you can provide the `property::buffer::use_host_ptr` property when constructing the `buffer`.
They can also be constructed without initial data like so : `auto buf = sycl::buffer<T>{sycl::range{size}}`.

A `buffer` will synchronize the latest modified copy of the data it manages back to the initial pointer on destruction.
To change the destination that a buffer will synchronize to on destruction you can call `set_final_data` with another.
Alternatively to prevent the `buffer` from synchronizing back to the initial data entirely you can call `set_final_data` with `nullptr`.

```c
auto buf = sycl::buffer{initialData, sycl::range{size}};
buf.set_final_data(finalData);
buf.set_final_data(nullptr);
```

Here we have an example of using these techniques:

- **Input** data is initialized with initial data but doesn't need to be copied back so it can use `set_final_data(nullptr)`.
- **Temporary** is only used on the device so can be an uninitialized `buffer`.
- **Output** data is initialized on the device and needs to be copied back so it can be an uninitialized buffer and use `set_final_data` to provide the final data address.

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Advanced_Data_Flow/solution.cpp)

For the rest of SYCL Academy I'm gonna let it for another moment as they are really specific and complex topic and some of them are not useful for me right now.
I might read about vectors and matrix topics later.


## Friday : 30 May <a name="30may"></a>

I start the day cloning the building the C++/SYCL implementation of the OneJoin algorithm.
Doing so I had a bit of trouble with my configuration of Nvim on CachyOS because of the LSP.
The LSP was notifying some errors that was due to the linking of the file.
So I install `bear` and create a `compile_commands.json` that fix most of it.
Some of them are still here but I think I can work with them without to much problems.

I start analysing the general structure of the code, brief on this table :

| Level                         | Files                                                            | Main Role                                                                                                                                                                                         |
| ---------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **I. Interface & Constants** | `onejoin.hpp`, `constants.hpp/.cpp`                              | Exposes constants (hash sizes, *K* threshold, etc.) and type aliases, declares all core OneJoin functions.                                                                                       |
| **II. OneJoin Pipeline**     | `onejoin_dpcpp.cpp`, `verification.cpp`, `utils.cpp`, `Time.cpp` | Implements the parallel join: LSH generation, SYCL embedding, bucketing, candidate generation/filtering, edit distance verification, performance measurement, and utilities.                    |
| **III. Application**         | `main.cpp`, `DBSCAN.cpp`                                         | Parses the command line, orchestrates either the simple join or the full *OneCluster* chain (join + DBSCAN + consensus).                                                                         |


