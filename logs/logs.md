<!--- TOC --->

# Table of contents
1. [Week 1](#week1)
    1. [Monday 26 May](#26may)
    2. [Tuesday 27 May](#27may)


<!--- BODY --->

# Week 1 <a name="week1"></a>

### Tasks

- [x] Set up and install SYCL tools
- [ ] Get started with SYCL (SYCL Academy)

### Links

- [SYCL](https://sycl.tech/)
- [SYCL Academy](https://sycl.tech/getting-started/academy)
- [Get the Intel oneAPI Base Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html?packages=oneapi-toolkit&oneapi-toolkit-os=linux&oneapi-lin=offline)


## Monday : 26 May <a name="26may"></a>

### Notes

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

### Notes

#### 1. What is SYCL

"SYCL is a single source, high-level, standard C++ programming model, that can target a range of heterogeneous platforms"

Command to compile a `.cpp` file using SYCL :
```
icpx -fsycl solution.cpp -o solution
```

#### 2. Enqueueing a Kernel

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

#### 3. Managing Data

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
[1]    8973 IOT instruction (core dumped)  ONEAPI_DEVICE_SELECTOR=opencl:gpu ./solution
```

For the CPU it worked easily :

```
🎗️ ❯ ONEAPI_DEVICE_SELECTOR=opencl:cpu ./solution
[SUCCESS] Test passed
[SUCCESS] Test passed
```

[_See solution_](https://github.com/codeplaysoftware/syclacademy/blob/main/Code_Exercises/Managing_Data/solution.cpp)

