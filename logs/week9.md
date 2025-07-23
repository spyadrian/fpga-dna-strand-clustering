# Week 9

### Table of contents

1. [Monday 21 July](#monday--21-july)
2. [Tuesday 22 July](#tuesday--22-july)
3. [Wednesday 23 July](#wednesday--23-july)
4. [Thursday 24 July](#thursday--24-july)
5. [Friday 25 July](#friday--25-july)
6. [Saturday 26 July](#saturday--26-july)
7. [Sunday 27 July](#sunday--27-july)

### Tasks

- [ ] Launch a sample code on the FPGA
- [ ] Test all levels of the FPGA compilation

### Links

- [FPGA tutorial - How to compile SYCL for FPGAs](https://github.com/oneapi-src/oneAPI-samples/tree/master/DirectProgramming/C++SYCL_FPGA/Tutorials/GettingStarted/fpga_compile)
- [vector-add example](https://github.com/oneapi-src/oneAPI-samples/tree/release/2024.2/DirectProgramming/C%2B%2BSYCL/DenseLinearAlgebra/vector-add)


## Monday : 21 July

I still have this error message doing the compilation of the `vector-add-buffers.cpp` file :

```
Error (24155): The Quartus Partition Database File 'ofs_top.qdb' was generated using version 'Version 23.2.0 Build 94 06/14/2023 Patches 0.02iofs,0.11,0.19,0.02 SC Pro Edition', which cannot be read by the current version of the Quartus Prime software. Regenerate 'ofs_top.qdb' using the current version of the Quartus Prime Software.
```

The problems is that my ASP was build on Quartus Prime Pro 23.2.0 version.
I have two possibilities :

1. Use Quartus 23.2.0 for hardware builds
2. Regenerate or obtain an updated ASP

I saw that the `oneapi-asp-a7sk` is based on the `f-series` boards so it'll be doable to upgrade the ASP, but it'll take time.
It's better for me to install the Quartus 23.2.0 in parallel of my actual version and change the some of the env.

Only the archive of Quartus Prime Pro 23.2.0 can be download aka 85GB.
It take 5 hours...
During that time, I study the Compilation Flow of the SYCL and OFS.


## Tuesday : 22 July

To make Quartus Prime Pro 23.2, I had to make some change on my `.bashrc`, here are they :

```bash
export QUARTUS_VERSION=23.2 # 23.2 or 24.1
export INTELFPGAOCLSDKROOT=/opt/intel/oneapi/compiler/2025.0/opt/oclfpga
export AOCL_BOARD_PACKAGE_ROOT=$INTELFPGAOCLSDKROOT/board/oneapi-asp-a7sk
export QSYS_ROOTDIR=/home/dna-fpga-workstation/intelFPGA_pro/$QUARTUS_VERSION/qsys/bin
export LM_LICENSE_FILE=/home/dna-fpga-workstation/Documents/LR-242596_License.dat
source /opt/intel/oneapi/setvars.sh

# Adding Quartus to PATH
export QUARTUS_ROOTDIR=/home/dna-fpga-workstation/intelFPGA_pro/$QUARTUS_VERSION/quartus
export QUARTUS_ROOTDIR_OVERRIDE=$QUARTUS_ROOTDIR
export PATH=$PATH:$QUARTUS_ROOTDIR/bin:$QUARTUS_ROOTDIR/sopc_builder/bin/
# Other OFS environment variables
# export OFS_ROOTDIR=path-to-directory-containing-cloned-ofs-fim-repo/ #ofs-agx7-pcie-attach for Agilex® 7 FPGA or ofs-d5005 for Stratix® 10 FPGA
# export WORKDIR=$OFS_ROOTDIR
export QUARTUS_HOME=$QUARTUS_ROOTDIR
export QUARTUS_INSTALL_DIR=$QUARTUS_ROOTDIR
export IMPORT_IP_ROOTDIR=$QUARTUS_ROOTDIR/../ip
export OPAE_SDK_REPO_BRANCH=release/2.13.0-3
export OFS_PLATFORM_AFU_BBB=/home/dna-fpga-workstation/Documents/ofs-platform-afu-bbb
export OFS_ASP_ROOT=/opt/intel/oneapi/compiler/2025.0/opt/oclfpga/board/oneapi-asp-a7sk
export LIBOPAE_C_ROOT=/usr
```

When I try to launch a executable after its compilation, I got an error telling that SYCL wasn't able to find any device to launch the hardware binary with.
So my PC was able to see my FPGA (`lspci` and `aoc -list-boards`) but SYCL wasn't.
I recheck the oneAPI guide from Terasic, and I try the `pci_device` commands.
This taught me that my PC wasn't cable of allocate memory for my FPGA : "OSERROR: \[Errno 12\] Cannot allocate memory".

I notice something important : My CPU don't support SR-IOV !
I though that the option I enabled in the BIOS was equivalent to it but it wasn't.
In fact, my CPU is a 7th generation which doesn't (or rarely) support this options.
I had to change PC...
Hopefully, Mr. Gantel had one for me with a 10th CPU.

During the manipulation, something went wrong with the SSD I was using; the boot partition wasn't detected and the partition that contained all my data was broken.
So I had to reinstall everything.
But as I already know all the things I need and how to install it, it was quite quick.
Here is a brief of the step of the install, but for more details refer to the [week 8](week8.md) :

1. Installing the Intel oneAPI FPGA Development Environment (base-toolkit and compiler-fpga 2025.0)
3. Install Quartus Prime Pro **23.2**
4. Update the kernel, kernel headers and kernel devel (4.18.0-477)
5. Add the kernel driver : intel-fpga-dfl-dkms
6. Enable Grub2 SR-IOV and IOMMU options
7. Add USB Blaster II Driver
8. Install Opae 2.13
9. Install ASP : oneapi-asp-a7sk
10. Update environment variables
11. Bring up the ASP and add the virtual function
12. Initialise the device A7SK

There is still the need to patch Quartus Prime Pro, but I don't know which patch are useful for the 23.2 yet.
I'll see that later.

When I finish those step, my computer was able to see my FPGA with `sycl-ls` !
Note: it was detected but they were an error with the DMA doing the `sycl-ls` commands.


## Wednesday : 23 July

When turning on the PC.
I didn't saw my FPGA on the `lspci` (same for `sycl-ls`).
I think I had to make these few commands after every turnoff :

```bash
cd /opt/intel/oneapi/compiler/2024.0/opt/oclfpga/board/oneapi-asp-a7sk/bringup/sof
./bringup_fpga.sh

sudo pci_device 05:00.0 vf 1
sudo opae.io init -d 0000:05:00.5 $USER
aocl initialize acl0 a7sk
```

I received and add the licence so I could try to compile and run.
When I run it I have errors about the DMA :

```
Error allocating DMA buffer
Error allocating write_fence buffer
```

I'm searching about the issue, but don't find something relevant.

