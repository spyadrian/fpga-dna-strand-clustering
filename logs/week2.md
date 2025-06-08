# Week 2 <a name="week2"></a>

### Table of contents

1. [Monday 02 June](#02june)
2. [Tuesday 03 June](#03june)
3. [Wednesday 04 June](#04june)
4. [Thursday 05 June](#05june)
5. [Friday 06 June](#06june)
6. [Saturday 07 June](#07june)
7. [Sunday 08 June](#sunday--08-june-)

### Tasks

- [x] Generate a new dataset
- [x] Make the Nvidia GPU work
- [x] Create a Docker container for the GPU
- [x] Create a Docker container for the FPGA
- [x] Getting started with VTune profiler
- [ ] Test the FPGA simulator of SYCL
- [ ] Analyse OneJoin algorithm implementation

### Links

- [SYCL](https://sycl.tech/)
- [OneAPI download](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html?packages=oneapi-toolkit&oneapi-toolkit-os=linux&oneapi-lin=offline)
- [OneAPI for Nvidia GPU](https://developer.codeplay.com/products/oneapi/nvidia/2025.1.1/guides/)
- [FPGA Support Package for the Intel](https://www.intel.com/content/www/us/en/developer/articles/release-notes/intel-oneapi-compiler-fpga-add-on-release-notes.html)
- [Compare version Quartus](https://www.intel.com/content/dam/www/central-libraries/us/en/documents/quartus-prime-compare-editions-guide.pdf)
- [Download Quartus Prime Pro 24.2](https://www.intel.fr/content/www/fr/fr/software-kit/826843/intel-quartus-prime-pro-edition-design-software-version-24-2-for-linux.html)
- [Download Codeplay plugin](https://developer.codeplay.com/products/oneapi/nvidia/download)
- [OneJoin paper](https://adms-conf.org/2021-camera-ready/marinelli_adms21.pdf)
- [OneJoin implementation C++/SYCL](https://github.com/Eug9/oneoligo)
- [Michaël's dataset-generator](https://gitlab.unige.ch/Michael.ElKharroubi/dataset-generator)
- [Altera University Program Teaching Materials](https://www.intel.com/content/www/us/en/developer/topic-technology/fpga-academic/materials.html)


## Monday : 02 June <a name="02june"></a>

I kept reading about the OneJoin algorithm and analyse the implementation.
Whenever I have to check a function in detail, it take time to understand well the mechanism of it.
For the moment I'm just gonna make a pipeline of the algorithm to know the data flow of it.


## Tuesday : 03 June <a name="03june"></a>

In the morning I had a rendezvous with Laurent and Michaël.
We talk about the general algorithm and how I should look at it.
One of my problem was to understand everything in the implementation, but, in fact, that's not necessary.
It's better for me to understand well the overall algorithm, its data flow and only understand in detail the function that could be parallelize.

We also setup new goals for me, that could help me doing the work :

- To use the my CUDA Nvidia GPU, I can download a Codeplay toolkit (careful to the version)
- It would be nice to try the FPGA mode simulator that offers SYCL (look at Nvidia tutorials)
- The dataset I'm using now is to perfect, let's use the python script from Michaël (before Friday)
- The use of a profiler would let me test the speed of the algorithm and see where the bottleneck are (see VTune profiler)

Michaël talk me about a bug where the number of groups the algorithm find tend to 0 when there is more than 100000 something (I forgot, I'll ask him next time).
I'm also thinking about using docker for this project, but I'll see if I have some problem with my distro during the rest of it.

I put the analyse of the implementation aside, and started by trying the dataset-generator.
It worked.

```
python3 dataset_generator.py dna-little.txt -n 250 -c 30
python3 dataset_generator.py dna-big.txt -n 25000 -c 30

docker run -v ./:/model -it julia:1.10.8-alpine3.21 /model/noise_model/DNA_data_storage_channel.sh -n 1 -k 6 -i /model/dna-little.txt -o /model/dna-little-noised.txt
docker run -v ./:/model -it julia:1.10.8-alpine3.21 /model/noise_model/DNA_data_storage_channel.sh -n 1 -k 6 -i /model/dna-big.txt -o /model/dna-big-noised.txt
```

I tried all day to enable my Nvidia GPU, but I failed.
I'll try from zero tomorrow.


## Wednesday : 04 June <a name="04june"></a>

I try all day long to have a setup that work on CPU, GPU and FPGA but didn't managed to.
Whether it was on my own laptop or on a docker, it didn't go well.
The main problem was the version of the library that was incompatible.

Even if it didn't work I managed to correct some problem and understand the main dependencies of the divers libraries.
I'll keep in mind what I have done and will brief it when I'm done with those task, maybe on Thursday.


## Thursday : 05 June <a name="05june"></a>

I start the day by trying the python script that Michaël add on the dataset-generator.
It allow to fix the length of the strands by a certain number, the default number being the median of the size.
It worked doing :

```
python3 postprocess.py dna-little-noised.txt -o dna-little-processed.txt
python3 postprocess.py dna-big-noised.txt -o dna-big-processed.txt
```

Next I continue with fixing the setup for OneAPI.
Half day through, I understand that :

- oneAPI Base Toolkit 2025.0 is the last version that support FPGA
- it needs CUDA version 12
- Codeplay plugin 2025.1 doesn't work with the oneAPI Base Toolkit 2025.0
- Codeplay plugin 2025.0 cannot be download with `apt` or `wget`

On my Cachyos, I was able to do it easily as long as I respected these constraints.
I end up with a setup that support CPU, GPU and FPGA (FPGA not tested yet), doing :

```
sudo pacman -S cuda                                     # CUDA 12.8
./intel-oneapi-base-toolkit-2025.0.1.46.sh              # oneAPI 2025.0.1 (2025.0.0 not availabe)
./oneapi-for-nvidia-gpus-2025.0.0-cuda-12.0-linux.sh    # Codeplay plugin 2025.0.0
```

Then my `sycl-ls` look like so :

```
[opencl:cpu][opencl:0] Intel(R) OpenCL, Intel(R) Core(TM) i7-1065G7 CPU @ 1.30GHz OpenCL 3.0 (Build 0) [2024.18.12.0.05_160000]
[opencl:gpu][opencl:1] rusticl, Mesa Intel(R) Iris(R) Plus Graphics (ICL GT2) OpenCL 3.0  [25.1.1-cachyos1.3]
[cuda:gpu][cuda:0] NVIDIA CUDA BACKEND, NVIDIA GeForce GTX 1660 Ti with Max-Q Design 7.5 [CUDA 12.8]
```

For the Docker container I tried with the same setup on the `intel/oneapi-basekit:2025.0.0-0-devel-ubuntu24.04`.
My error was that, on my Dockerfile, I was downloading the Codeplay plugin doing `apt-get install oneapi-nvidia-12.6` aka the 2025.1 version.
Because of that I spend a lot of time trying to solve some unrelated problems.

There was two option to fix this problem :

- I install on my host the offline installer (idk if I can `wget` it) for the Codeplay plugin and `COPY` it into my docker using my Dockerfile
- I create two Dockerfile, one for CPU + GPU (Codeplay plugin) and the other for CPU + FPGA (oneAPI 2025.0)

I choose the second option as I think that the first one runs counter to the container principle, where, as a general rule, you simply build then run the container.
It's likely that it will be possible to download the Codeplay 2025.0 plugin directly onto the container, but for the moment I'm sticking to the second approach.

I managed to create two different Dockerfile that allows to do so.
I'll run test on them tomorrow before to push them on the git.


## Friday : 06 June <a name="06june"></a>

I started the day by doing some test on my host setup.
The goal here was to make sure that the GPU is used, prepare the FPGA setup and to understand how the Vtune profiler works.

For the GPU I struggle a bit but in short, I forget to put the `-fsycl-targets=nvptx64-nvidia-cuda` flag at the build.
I need to figure out a way to add this line to the Makefile if I run it on the Docker container.

Preparing the FPGA setup and installing Quartus Prime, I saw that we need to get the Quartus Prime Pro 24.2 version (a pay version) to use the Agilex 7.
The standard one doesn't have the support for Agilex.
The get it there is two possibilities :

- one "voucher" version come with the Agliex 7 we've already ordered
- we get the student licence
- (we paid it, we don't want to do that)

The ideas was to wait for the Agliex 7 to be delivered and see at that moment.
But, waiting, I already ask for the student licence just in case (it might be useless, cause a forum told that only professor can make them).


## Saturday : 07 June <a name="07june"></a> 

The Vtune profiler works well.
I saw that there were many diverse type of diagnostic.
I tried them on the OneJoin algorithm but I didn't see much cause I have some problems having the right value for each parameters of the algorithm.

I tried with multiple parameters but I either get zero output or to much candidates resulting in a `out of memory`.
I'll try to get more in the algorithm to be sure that I making no mistake with the parameters.

## Sunday : 08 June <a name="08june"></a>

...

