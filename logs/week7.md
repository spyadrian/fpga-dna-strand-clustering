# Week 7

### Table of contents

1. [Wednesday 09 July](#wednesday--09-july)
2. [Thursday 10 July](#thursday--10-july)
3. [Friday 11 July](#friday--11-july)
4. [Saturday 12 July](#saturday--12-july)
5. [Sunday 13 July](#sunday--13-july)

### Tasks

- [x] Setup Ubuntu 22.04
- [x] Test level 3 of the FPGA compilation
- [ ] Test all levels of the FPGA compilation

### Links

- [OneJoin implementation C++/SYCL](https://github.com/Eug9/oneoligo)
- [FPGA tutorial - How to compile SYCL for FPGAs](https://github.com/oneapi-src/oneAPI-samples/tree/master/DirectProgramming/C++SYCL_FPGA/Tutorials/GettingStarted/fpga_compile)
- [FPGA Operating System (OS) Support](https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-software/os-support.html)
- [Intel® oneAPI Base Toolkit System Requirements](https://www.intel.com/content/www/us/en/developer/articles/system-requirements/oneapi-base-toolkit/2025.html)
- [Agilex 7 FPGA Starter Kit Resources](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=142&No=1295&PartNo=4)
- [OFS Release for Intel Agilex 7 PCIe Attach Reference Shells](https://github.com/OFS/ofs-agx7-pcie-attach/releases/tag/ofs-2023.2-1)


## Wednesday : 09 July

Getting some trouble with the level 3 of the FPGAs compilation.
It's due to a library.
CachyOS uses recent versions of glibc (2.37+ according to changelogs) and binutils (2.40+) which generate libraries with RELR relocations enabled.
These libraries are incompatible with older development tools like GCC 10.3.0 included in Quartus.

So I'm trying to install the glibc version 2.27, but it take a lot of time.
So much time, that I think it crashed silently or something.

As it's been the nth error I have with CachyOS, I might pass on Ubuntu 22.04.
I'm still happy with CachyOS as I could learn a lot fixing those errors, but time being to be quite precious now.


## Thursday : 10 July

To summarise the situation about the OS, CachyOS is not recommended for my configuration, because :

- Confirmed compatibility issues with Intel FPGA tools
- Glibc too recent causing errors with Quartus Prime 24.2
- No official support from Intel

And the best OS should be Ubuntu 22.04 LTS, because the official support is confirmed for all three tools 

- Intel OneAPI Base Toolkit 2025.0.1
- Quartus Prime Pro 24.2
- Intel FPGA Support Compiler 2025.0.0

So I'll reinstall my setup on the workstation (PC) only.
I decide to try the latest version of Quartus, because I can't remember why I install the 24.2.

I started by installing the tools :

```bash
./intel-oneapi-base-toolkit-2025.0.1.46_offline.sh
./qinst-linux-25.1-129.run
./intel-fpga-support-for-compiler-2025.0.0.591_offline.sh

sudo apt install build-essential g++ libstdc++-12-dev
```

I add the latest version of the library `boost` otherwise I was lacking some functionalities :

```bash
sudo add-apt-repository ppa:mhier/libboost-latest
sudo apt update

sudo apt install libboost1.83-all-dev
```

I add the necessary export, and the source of `setvars.sh` on the `.bashrc` file.
The end of my `.bashrc` look like so (after some modification next day) :

```bash
export QSYS_ROOTDIR="/home/adrian/intelFPGA_pro/24.2/qsys/bin"
export QUARTUS_ROOTDIR="/home/adrian/intel/intelFPGA_pro/24.2/quartus"
export QUARTUS_ROOTDIR_OVERRIDE="$QUARTUS_ROOTDIR"
export LM_LICENSE_FILE="/home/adrian/Downloads/LR-238975_License.dat"
export PATH="$PATH:/home/adrian/intelFPGA_pro/24.2/quartus/bin:/home/adrian/intelFPGA_pro/24.2/questa_fe/linux_x86_64:/home/adrian/intel/oneapi/compiler/2025.0/lib"

source /home/adrian/intel/oneapi/setvars.sh
source /home/adrian/intel/oneapi/compiler/2025.0/opt/oclfpga/fpgavars.sh
```

After all that I started testing the level 3 of the FPGA compilation, but I got some errors, again...
To be sure I reinstall the older version of Quartus, but the errors didn't fade out.


## Friday : 11 July

I decide to restart from the level 1 of the FPGA compilation.
For the level 1 I got the same error that I had on CachyOS : `platform is empty`.
To fix it, run those commands :

```bash
# add device
sudo mkdir -p /etc/OpenCL/vendors/
echo "libalteracl.so" | sudo tee /etc/OpenCL/vendors/Altera.icd
echo "libintelocl_emu.so" | sudo tee /etc/OpenCL/vendors/Intel_FPGA_SSG_Emulator.icd

# fix lib "not found"
ln -s /home/adrian/intel/oneapi/compiler/2025.0/lib/libcommon_clang.so.2024.18.12.0 /home/adrian/intel/oneapi/compiler/2025.0/lib/libcommon_clang.so.2024.18.10.0
```

For the level 2 (report), it compile till the end and create all the `onejoin.report.prj` needed but printed `segmentation fault` during the process.
On the kernel ring buffer `dmesg -H`, I can see those errors with more details (because there was nothing on the log).

I ignore the first one, because it's about the PCIe, that's not used in my case :

```
pcieport 10000:e0:1b.4: AER: Correctable error message received from 10000:00:1b.4
pcieport 10000:e0:1b.4: PCIe Bus Error: severity=Correctable, type=Physical Layer, (Receiver ID)
pcieport 10000:e0:1b.4:   device [8086:7ac4] error status/mask=00000001/00002000
pcieport 10000:e0:1b.4:    [ 0] RxErr                  (First)
```

The second one is more tricky :

```
aocl-boardspec[51987]: segfault at ffffffffffffffe8 ip 000058ad01ee37ce sp 00007ffc04200c20 error 5 in aocl-boardspec[58ad01edc000+50000] likely on CPU 10 (core 20, socket 0)
```

I don't know how to fix it, it seems that there is a library trying to point on the `ffffffffffffffe8` address creating a segfault.
I notice that on my laptop CachyOS, I had the same thing, only the `segmentation fault` wasn't print during the compilation.
For the moment I'll ignored them, but I keep them in mind, as they might be a potential error.
The same error on CachyOS :

```
[Jul11 16:37] aocl-boardspec[17106]: segfault at ffffffffffffffe8 ip 0000593e1980b7ce sp 00007ffe008a6b50 error 5 in aocl-boardspec[77ce,593e19804000+50000] likely on CP>
```

For the level 3, the same happens but multiple time, creating multiple `segfault` on the `dmesg` :

```
[Jul11 16:47] aocl-boardspec[53255]: segfault at ffffffffffffffe8 ip 0000629d224e57ce sp 00007ffcae212810 error 5 in aocl-boardspec[629d224de000+50000] likely on CPU 8 (core 16, socket 0)
[  +0.000026] Code: 84 20 10 00 00 4c 8b ac 24 b0 06 00 00 4c 89 3c 24 45 31 f6 48 89 5c 24 20 31 c0 49 89 cf 4c 89 cb 4d 8b 5d 08 4c 89 6c 24 38 <4d> 8b 43 e8 4c 89 5c 24 40 4d 89 c5 eb 14 0f 1f 40 00 41 8d 46>
[Jul11 16:48] aocl-boardspec[54085]: segfault at ffffffffffffffe8 ip 00005fbfb71ea7ce sp 00007ffd0eec2b70 error 5 in aocl-boardspec[5fbfb71e3000+50000] likely on CPU 0 (core 0, socket 0)
[  +0.000024] Code: 84 20 10 00 00 4c 8b ac 24 b0 06 00 00 4c 89 3c 24 45 31 f6 48 89 5c 24 20 31 c0 49 89 cf 4c 89 cb 4d 8b 5d 08 4c 89 6c 24 38 <4d> 8b 43 e8 4c 89 5c 24 40 4d 89 c5 eb 14 0f 1f 40 00 41 8d 46>
[  +0.075594] aocl-boardspec[54093]: segfault at ffffffffffffffe8 ip 00005c3f48f467ce sp 00007ffc26558700 error 5 in aocl-boardspec[5c3f48f3f000+50000] likely on CPU 16 (core 28, socket 0)
[  +0.000016] Code: 84 20 10 00 00 4c 8b ac 24 b0 06 00 00 4c 89 3c 24 45 31 f6 48 89 5c 24 20 31 c0 49 89 cf 4c 89 cb 4d 8b 5d 08 4c 89 6c 24 38 <4d> 8b 43 e8 4c 89 5c 24 40 4d 89 c5 eb 14 0f 1f 40 00 41 8d 46>
[  +0.060983] aocl-boardspec[54097]: segfault at ffffffffffffffe8 ip 00005e08039907ce sp 00007ffe16ff1d00 error 5 in aocl-boardspec[5e0803989000+50000] likely on CPU 14 (core 26, socket 0)
[  +0.000012] Code: 84 20 10 00 00 4c 8b ac 24 b0 06 00 00 4c 89 3c 24 45 31 f6 48 89 5c 24 20 31 c0 49 89 cf 4c 89 cb 4d 8b 5d 08 4c 89 6c 24 38 <4d> 8b 43 e8 4c 89 5c 24 40 4d 89 c5 eb 14 0f 1f 40 00 41 8d 46>
```

Run the `./onejoin.fsim` output seems to work as it run on the simulator `Device: SimulatorDevice : Multi-process Simulator (aclmsim0)`.
But the script stop at the start of onejoin doing the first batch.

For me there is 2 possibility, the `segfault` on the kernel ring buffer are critical or the algorithm can't handle the FPGAs and I need to change something on it.
I'll check that tomorrow.


## Saturday : 12 July

About the two errors possibilities that I've highlighted, I was wrong.
The algorithm work but just really slowly.
It's after the whole night, letting the script run, that I see that the algorithm was working (even after one night it didn't finished).

Reading the logs more attentively, I saw that all the batch (`print` concerning the batch) are run really quickly but that the algorithm lose time between them.
Here are some `print` that shows it :

```
[2025-07-11 17:02:31.578611] [info] Reading dataset...
[2025-07-11 17:02:31.580854] [info] Starting OneCluster...
7499
[2025-07-11 17:02:31.582506] [info] Computing OneJoin...
[2025-07-11 17:02:31.582547] [info] Parameter selected:
[2025-07-11 17:02:31.582560] [info] Num of strings:                                  7499
[2025-07-11 17:02:31.582566] [info] Len output:                                      84
[2025-07-11 17:02:31.582575] [info] Samplingrange:                                   300
[2025-07-11 17:02:31.582587] [info] Number of Hash Function:                         7
[2025-07-11 17:02:31.582594] [info] Number of Bits per hash function:                12
[2025-07-11 17:02:31.582600] [info] Number of Random Strings per input string:       5
[2025-07-11 17:02:31.582605] [info] Number of Replication per input string:          1
[2025-07-11 17:02:31.582609] [info] K distance:                                      6
[2025-07-11 17:02:31.582616] [info] Count filter:                                    1
[2025-07-11 17:02:31.582622] [info] Batch size:                                      30
[2025-07-11 17:02:31.582631] [info] Number of batches:                               249

[2025-07-11 17:02:31.582640] [debug] Size last batch: 29
[2025-07-11 17:02:31.582646] [debug] Number of batches: 250
[2025-07-11 17:02:31.604776] [debug] Number of devices: 1
[2025-07-11 17:02:31.605009] [info] Start parallel algorithm...
[2025-07-11 17:02:31.606009] [info] Parallel Embedding
[2025-07-11 17:02:31.606016] [debug] Len output: 84
[2025-07-11 17:02:31.606121] [info] Start profiling on devices...
[2025-07-11 17:02:31.606125] [debug] Offset input strings: 0
[2025-07-11 17:02:31.606136] [info] Task: Embedding DataDevice: SimulatorDevice : Multi-process Simulator (aclmsim0)
[2025-07-11 17:02:31.606161] [debug] Batch size: 30
[2025-07-11 17:02:31.606164] [debug] Range: (30, 5, 1)
[2025-07-11 23:26:38.401590] [debug] Offset input strings: 6210
[2025-07-11 23:26:38.401628] [info] Task: Embedding DataDevice: SimulatorDevice : Multi-process Simulator (aclmsim0)
[2025-07-11 23:26:38.401650] [debug] Batch size: 30
[2025-07-11 23:26:38.401652] [debug] Range: (30, 5, 1)
[2025-07-12 05:46:47.811140] [debug] Times kernel: 22809.4sec
[2025-07-12 05:46:47.811179] [debug] n_fast: 248
[2025-07-12 05:46:47.811182] [debug] n_slow: 0
[2025-07-12 05:46:47.811183] [debug] id_fastest: 0
[2025-07-12 05:46:47.811185] [debug] id_slowest: 18446744073709551615
[2025-07-12 05:46:47.811187] [debug] Dev 0:
[2025-07-12 05:46:47.811189] [debug] 0. 2
[2025-07-12 05:46:47.811214] [debug] 1. 248
[2025-07-12 05:46:47.811215] [info] Start computing on devices...
[2025-07-12 05:46:47.811218] [debug] Offset input strings: 12420
[2025-07-12 05:46:47.811232] [info] Task: Embedding DataDevice: SimulatorDevice : Multi-process Simulator (aclmsim0)
[2025-07-12 05:46:47.811251] [debug] Batch size: 30
[2025-07-12 05:46:47.811253] [debug] Range: (30, 5, 1)
[2025-07-12 05:46:47.811579] [debug] Offset input strings: 18630
[2025-07-12 05:46:47.811589] [info] Task: Embedding DataDevice: SimulatorDevice : Multi-process Simulator (aclmsim0)
[2025-07-12 05:46:47.811596] [debug] Batch size: 30
[2025-07-12 05:46:47.811597] [debug] Range: (30, 5, 1)

[...]

[2025-07-12 05:46:47.869511] [debug] Offset input strings: 1546290
[2025-07-12 05:46:47.869517] [info] Task: Embedding DataDevice: SimulatorDevice : Multi-process Simulator (aclmsim0)
[2025-07-12 05:46:47.869522] [debug] Batch size: 29
[2025-07-12 05:46:47.869525] [debug] Range: (29, 5, 1)
[2025-07-11 17:02:31.578611] [info] Reading dataset...
[2025-07-11 17:02:31.580854] [info] Starting OneCluster...
7499
[2025-07-11 17:02:31.582506] [info] Computing OneJoin...
```

It might be cause of :

1. the time to give the data to the FPGA simulator, if so I might try to use other form of data usage
2. all the print are print at the end of the computation, one after the others

In any case, it might be the cause of the simulator, my principal goals is the hardware so I'll let it like so.

For the level 4 (hardware), I notice that I don't have the Board Support Package (BSP) doing `aoc -list-boards`.
We can create it via the Open FPGA Stack (OFS) software but in our case, with the Terasic Agilex 7 FPGA Starter Kit, we can downloads it on their site, and add it to the board doing :

```bash
tar xf oneapi-asp-a7sk.tar.gz
mv oneapi-asp-a7sk /home/adrian/intel/oneapi/compiler/2025.0/opt/oclfpga/board/

aocl install oneapi-asp-a7sk
```

Now, doing `aoc -list-boards`, I have :

```
Board list:
  a7sk (default)
     Board Package: /home/adrian/intel/oneapi/compiler/2025.0/opt/oclfpga/board/oneapi-asp-a7sk

  a7sk_usm
     Board Package: /home/adrian/intel/oneapi/compiler/2025.0/opt/oclfpga/board/oneapi-asp-a7sk
     Memories:      device, host`
```

To start using the Agilex 7, I need now to bring up the FPGA Board.


## Sunday : 13 July

Following the guide of the Agilex 7 Starter Kit (A7SK), they say to install three more tools :

1. OFS DFL Kernel Drivers - Essential for PCIe communication
2. USB Blaster II Driver - Essential for FPGA programming
3. OPAE SDK - Recommended for completeness, even if not directly used

The guide is made on and for CentOS, so I don't really know if I'm gonna have some errors doing it on Ubuntu 22.04.
In fact, quite all of the Intel tools work on Ubuntu 22.04 but maybe that the A7SK is not made for it.
What I did is still install those tools, converting the `.rpm` to `.deb` with `alien --to-deb`.
We'll see if it work or not.

As the `alien` conversion fail on some of the package, I didn't install the whole OFS.
I'll check for a solution later, if it didn't work.
Same for OPAE.

Passing through the guide, I didn't manage to make that my PC recognize my PCIe card doing `lspci -d 8086:bcce`.
The `aocl diagnose` reveal some of the potential errors mostly due to the fact that I was unable to install the OFS and OPAE tools.
