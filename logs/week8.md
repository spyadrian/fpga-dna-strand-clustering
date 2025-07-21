# Week 8

### Table of contents

1. [Monday 14 July](#monday--14-july)

### Tasks

- [ ] Test all levels of the FPGA compilation

### Links

- [FPGA Support Package for Intel® oneAPI DPC++/C++ Compiler](https://www.intel.com/content/www/us/en/developer/tools/oneapi/fpga.html)
- [Intel® oneAPI DPC++/C++ Compiler System Requirements](https://www.intel.com/content/www/us/en/developer/articles/system-requirements/oneapi-dpcpp/2025.html)
- [OS Support for Altera® FPGA Pro Edition Software Versions (same for Quartus Prime Pro)](https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-software/os-support.html#tab-blade-2-4)

#### Guides

- [FPGA tutorial - How to compile SYCL for FPGAs](https://github.com/oneapi-src/oneAPI-samples/tree/master/DirectProgramming/C++SYCL_FPGA/Tutorials/GettingStarted/fpga_compile)
- [Intel® oneAPI DPC++/C++ Compiler Handbook for FPGAs](https://www.intel.com/content/www/us/en/docs/oneapi-fpga-add-on/developer-guide/2025-0/installing-the-intel-oneapi-fpga-development.html)
- [Ubuntu: Installing the OPAE Framework from Prebuilt Binaries](https://www.intel.com/content/www/us/en/docs/programmable/683633/1-2-1/ubuntu-installing-the-framework-from.html)
- [Installing the Intel oneAPI FPGA Development Environment (pdf)](https://cdrdv2.intel.com/v1/dl/getContent/854477)
- [Software Installation Guide: Open FPGA Stack for PCIe Attach](https://ofs.github.io/ofs-2024.2-1/hw/common/sw_installation/pcie_attach/sw_install_pcie_attach/)
- [oneAPI Accelerator Support Package (ASP): Getting Started User Guide](https://ofs.github.io/ofs-2024.2-1/hw/common/user_guides/oneapi_asp/ug_oneapi_asp/)
- [Agilex 7 FPGA Starter Kit oneAPI Toolkit User Manual (pdf)](https://www.terasic.com.tw/cgi-bin/page/archive_download.pl?Language=English&No=1295&FID=a92b06c2fd045fcd5e9be408f67965d9)

#### Resources

- [Agilex 7 FPGA Starter Kit Resources](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=142&No=1295&PartNo=4)
- [ofs-2024.2-1 Release for Agilex 7](https://github.com/OFS/ofs-agx7-pcie-attach/releases/tag/ofs-2024.2-1)
- [ofs-2023.2 Release for Agilex 7](https://github.com/OFS/ofs-agx7-pcie-attach/releases/tag/ofs-2023.2-1)
- [vector-add example](https://github.com/oneapi-src/oneAPI-samples/tree/release/2024.2/DirectProgramming/C%2B%2BSYCL/DenseLinearAlgebra/vector-add)


## Monday : 14 July

As the OFS DFL and the OPAE SDK are mendatory to use the FPGA Agilex 7 series F I have.
I need to find a solution to install them.

On their Git, OFS give the assets in `.deb` to install the OFS and OPAE tools.
I choose the release 2024.2 as it's the last that support oneAPI, even if they install the 2023.2 in the guide.

In this releases some of the tools they use not match mine in term of version, as the Quartus Prime Pro Software or the Kernel version.
I'll try as it's supposed to be retro compatible, let's see.
The release strongly advise to patch quartus with the patch 0.18 (memory optimization) and 0.26 (Quartus assembler), what I did.

After installing the kernel, OFS and the OPAE with dpkg and manually mounting the module with :

```bash
sudo modprobe dfl
sudo modprobe dfl-pci
sudo modprobe dfl-fme
sudo modprobe dfl-afu
```

I still can't see my FPGA doing either `lspci` or `fpgainfo`.


## Tuesday : 15 July

In the A7SK guide, they use the assets (OFS, OPAE and kernel) of the ofs-2023.2.
As it's the only thing I see, I'll try with this release doing the same step as they do.

The assets of the ofs-2023.2 don't have the `.deb` but only the `.rpm`.
However, it's possible to build them from their depot Git.

Trying all the afternoon to build them, I gave up.
I've been blocked with an unexpected errors and I didn't find the solution to it.


## Wednesday : 16 July

I read that the SR-IOV option in the bios need to be enable to be able to see the device.
I might be in trouble as I use a PC locked by the DSI, with a secured bios that don't let anyone change some option.
Hopefully a options doing the same as SR-IOV is enable.

So according to some sources the ofs-2024.1-1 should work on Ubuntu 22.04.
So let's try it.

I'm on the same situation as with the 2024.2...


## Thursday : 17 July

As I can't fix the fact that I don't see my FPGA on Ubuntu 22.04.
I choose to change my OS and pick a guide that's work good and follow it to the letter.
Also I want to be clear with the compatibility between the different tools and OS.

Here a some note about the compatibility of the tools :

- Intel® oneAPI Base Toolkit System Requirements
  - OS : Ubuntu 22.04, 24.04, RHEL 8.x, 9.x (for CPU)

- oneAPI DPC++/C++ compiler 2025.0.4 release for FPGA (APT, YUM, DNF, Zypper)
  - OS : Ubuntu 22.04, RHEL 8.6, 9.0, 9.1 (for FPGA)
  - Quartus Prime Pro Software : 22.3 to 24.2
  - Mem : 64 GB for Intel FPGA

- Intel Quartus Prime Pro Software (22.3 to 24.2) for FPGA
  - OS : RHEL 8 et 9, Ubuntu 22.04

- OFS DFL Kernel Drivers
  - (intel redirect on the ofs-2024.2-1)
  - OS : RHEL 8, Ubuntu 22.04
  - OPAE : 2.13

At first I wanna follow the guide "A7SK oneAPI User Manual" given by Terasic but, even if the guide has been updated in 2025, they use some really old tools.
In particular CentOS Stream 8, which has reached its end of life.
Something also strange is that they use Quartus Prime Pro 23.2 that is not supposed to be working on CentOS Stream 8, at least not made for it (it got a cross on the table of supportable OS).

The official OFS documentation offers a guide using oneAPI and the FPGA Agilex 7 series F.
It doesn't mention the A7SK, but it should work since it uses this Agilex 7.
Here's the setup it proposes:

| Component/Tool | Version |
|---|---|
| FPGA Platform | Intel® FPGA SmartNIC N6001-PL |
| | Agilex® 7 FPGA F-Series Development Kit (2x F-Tile) |
| | Agilex® 7 FPGA I-Series Development Kit (2x R-Tile and 1xF-Tile) |
| Operating System | RHEL 8.8 , Kernel : 4.18.0-dfl |
| linux-dfl (DFL Kernel Driver) | Tag: intel-1.11.0-2 |
| opae-sdk | Branch: release/2.13.0, Tag: 2.13.0-3 |
| ofs-fim | Tag: ofs-2024.2-1 |
| oneapi-asp | Tag: ofs-2024.2-2 > Note: Cloning and build of this repo is discussed in the section 2.4 |
| Quartus Prime Pro Edition | Version 24.1 Pro Edition with patches (0.18, 0.26 and 0.02iofs) under assets and summary sections in this link patch-agx7-2024-2-1.tar.gz |
| Intel® oneAPI Base Toolkit (Base Kit) | Latest version > Note: Ensure to install the oneAPI compiler patches required, according to the version you are using, you can download them in the patch history section from the FPGA Support Package for Intel® oneAPI DPC++/C++ Compiler page |
| GCC | 8.5.0 |
| cmake | 3.15 |

They also told us to be careful about :

- "Intel VT for Directed I/O (VT-d)" in BIOS (enable)
- Ensure that IOMMU is turned on as explained
- For Agilex® 7 FPGA ensure Quartus patches 0.18, 0.26 and 0.02iofs are installed.

With my teacher, we made a new license with those parameters :

- xx:xx:xx:xx:xx:xx
- dna-fpga-workstation

So I'll try to do it with RHEL 8.8 following the [oneAPI Accelerator Support Package (ASP): Getting Started User Guide](https://ofs.github.io/ofs-2024.2-1/hw/common/user_guides/oneapi_asp/ug_oneapi_asp/).


## Friday : 18 July

To install the RHEL 8.8 I had to make an account on Red Hat.
After that, I install the `.iso` and install the OS on my machine.

On Red Hat we need to enable the repos doing `sudo subscription-manager repos --enable=reposname`.
But I wasn't able to do so because I didn't had a subscription (as they said).
Something really weird because my account is set on "Simple Content Access" and it allows me to use the OS without any subscription.
I search on internet about the problem but nothing appear expect an solution talking about the time zone.
But checking the diagnostic of the error, I understand that I didn't have the same problems.


## Saturday : 19 July

I don't know why, but I was able to do enable the repos this time doing nothing different from yesterday.

```bash
sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms
sudo subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms

sudo dnf upgrade --refresh
```

#### Following the "[Installing the Intel oneAPI FPGA Development Environment](https://cdrdv2.intel.com/v1/dl/getContent/854477)"

```bash
tee > /tmp/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

sudo mv /tmp/oneAPI.repo /etc/yum.repos.d

sudo yum install intel-oneapi-base-toolkit-2025.0
sudo yum install intel-oneapi-compiler-fpga-2025.0
```

#### Install Quartus Prime Pro 24.1

```bash
chmod u+x qinst-linux-24.1-115.run
./qinst-linux-24.1-115.run
```

I checked those options :

- [x] Intel Quartus Prime Pro Edition Software
- [x] Questa-Intel FPGA and Starter Edition
- [x] Intel Agilex 5 device support
- [x] Intel Agilex 7 device support
- [x] Intel Arria 10 device support
- [x] Intel Cyclone 10 GX device support
- [x] Intel FPGA Power Thermal Calculator
- [x] Intel Quartus Prime Pro Edition Programmer and Tools
- [x] Intel Quartus Prime Pro Edition Help

After that I launch Quartus Prime Pro to enable the license.

#### Following the "[Software Installation Guide: Open FPGA Stack for PCIe Attach](https://ofs.github.io/ofs-2024.2-1/hw/common/sw_installation/pcie_attach/sw_install_pcie_attach/)"

The guide use the RHEL 8.10.
But for my case is important to stay on RHEL 8.8 because I'll use oneAPI and it's strongly recommends to stay on this version for that as said in the ofs-2024.2-1 "Note: OneAPI has been validated with Red Hat® Enterprise Linux® 8.8. If you are using OneAPI it is recommended you use RHEL 8.8.".

For this reason some of the version will be different as the kernel, `4.18.0-533.5.1_el8_10.x86_64` for the guide `4.18.0-477.27.1.el8_8.x86_64` for me (the most recent version for RHEL 8-8).
Of course, the kernel will change anyway to `4.18.0-dfl`.

I checked, the intel VT for Directed I/O (VT-d) is enable.

Freeze release and add enable repos.

```bash
subscription-manager release --set=8.8
sudo dnf update
subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
```

Install the dependencies.

```bash
# I could not install some of them, because some of they "does not belong to a distupgrade"
sudo dnf install python3 python3-pip python3-devel python3-jsonschema python3-pyyaml git gcc gcc-c++ make cmake libuuid-devel json-c-devel hwloc-devel tbb-devel cli11-devel spdlog-devel libedit-devel systemd-devel doxygen python3-sphinx pandoc rpm-build rpmdevtools python3-virtualenv yaml-cpp-devel libudev-devel libcap-devel numactl-devel bison flex automake autoconf libtools

python3 -m pip install --user jsonschema virtualenv pudb pyyaml setuptools pybind11

sudo dnf install kernel-4.18.0-553.5.1.el8_10.x86_64
sudo dnf install kernel-headers-4.18.0-553.5.1.el8_10.x86_64
sudo dnf install kernel-devel-4.18.0-553.5.1.el8_10.x86_64
```

The `dnf install` skipped the `platform-python-3.6.8` and the `platform-python-3-devel-3.6.8`.
As I don't have the RHEL 8.10 but 8.8, I install the `kernel-4.18.0-477.27.1.el8_8.x86_64` instead of the `kernel-4.18.0-533.5.1.el8_10.x86_64`.
So, instead of the three last commands, I made :

```bash
sudo dnf install kernel-4.18.0-477.27.1.el8_8.x86_64
sudo dnf install kernel-headers-4.18.0-477.27.1.el8_8.x86_64
sudo dnf install kernel-devel-4.18.0-477.27.1.el8_8.x86_64
```

Installing the OFS DFL Backport Kernel Drivers from Pre-Built Packages.

```bash
wget https://github.com/OFS/ofs-agx7-pcie-attach/releases/download/ofs-2024.2-1/kernel-4.18.0_dfl_2024.06.14_276007e.tar.gz

tar xf kernel-4.18.0_dfl_2024.06.14_276007e.tar.gz

sudo dnf install dkms
sudo rpm -i kernel-4.18.0_dfl_2024.06.14_276007e/intel-fpga-dfl-dkms-1.11.0-2.2024.06.14.g276007e.noarch.rpm

# Set this kernel as your new default boot target
sudo grubby --set-default /boot/vmlinuz-4.18.0-477.27.1.el8_8.x86_64
sudo reboot
```

Doing so didn't install me a new kernel, I don't know why, instead it install me on `/usr/lib/modules/4.18.0-477.27.1.el8_8.x86_64/extra` the drivers for the fpga.
For X reason this result differs from the guide where, it seems, that they change of kernel.
They have the drivers in `/usr/lib/modules/4.18.0-dfl/kernel/drivers/fpga` and have a new entry in grub named `vmlinuz-4.18.0-dfl` under `/boot/`.
My setup is supposed to work as well as I have the drivers installed.
For me it's really weird that I don't have the same result as the guide, but OK.

Also the modules just installed are not add automatically from the Linux Kernel.
Doing `lsmod | grep dfl` nothing appear (sometime after a reboot there is dfl, dfl_pci, fpga_region)
I can add them with `sudo modprobe modulename` :

```bash
# get all the modules in .../extra without the .ko.xz
find /usr/lib/modules/$(uname -r)/extra/ -name "*.ko.xz" -exec basename {} \; | sed 's/\.ko\.xz$//' | xargs -r sudo modprobe -a
```

I add the necessary to the GRUB_CMDLINE_LINUX, and rebbot.

```bash
cat /proc/cmdline
BOOT_IMAGE=(hd0,msdos1)/vmlinuz-4.18.0-477.27.1.el8_8.x86_64 root=/dev/mapper/rhel-root ro crashkernel=auto resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet intel_iommu=on pcie=realloc hugepagesz=2M hugepages=200
```

Not the same as in the guide but it's coherent according to what I did.

Installing the OPAE SDK with Pre-Built Packages

```bash
sudo dnf remove opae*
```

Installing from the archive of the ofs-2024.2-1 release.

```bash
tar xf opae-2.13.0-3.x86_64-*.tar.gz

rm opae-*.src.rpm
sudo dnf localinstall opae*.rpm
```


```bash
rpm -qa | grep opae
opae-debugsource-2.13.0-2.el8.x86_64
opae-extra-tools-2.13.0-2.el8.x86_64
opae-2.13.0-2.el8.x86_64
opae-devel-debuginfo-2.13.0-2.el8.x86_64
opae-devel-2.13.0-2.el8.x86_64
opae-extra-tools-debuginfo-2.13.0-2.el8.x86_64
opae-debuginfo-2.13.0-2.el8.x86_64
```

#### Following the "[oneAPI Accelerator Support Package (ASP): Getting Started User Guide](https://ofs.github.io/ofs-2024.2-1/hw/common/user_guides/oneapi_asp/ug_oneapi_asp/)"

The `iommu` is on :

```bash
cat /proc/cmdline
BOOT_IMAGE=(hd0,msdos1)/vmlinuz-4.18.0-477.27.1.el8_8.x86_64 root=/dev/mapper/rhel-root ro crashkernel=auto resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet intel_iommu=on pcie=realloc hugepagesz=2M hugepages=200
```

Apply the Quartus' patches

```bash
tar xf patch-agx7-2024-2-1.tar.gz
cd patch-agx7-2024-2-1

chmod u+x *.run
./quartus-24.1-0.26-linux.run
./quartus-24.1-0.18-linux.run
```

Set the required environment variables.
Here is the last few line of my `.bashrc` :

```bash
export QSYS_ROOTDIR="/home/dna-fpga-workstation/intelFPGA_pro/24.1/qsys/bin"
export LM_LICENSE_FILE=/home/dna-fpga-workstation/Documents/LR-242596_License.dat
source /opt/intel/oneapi/setvars.sh

# Adding Quartus to PATH
export PATH=$PATH:/home/dna-fpga-workstation/intelFPGA_pro/24.1/quartus/bin
export QUARTUS_ROOTDIR=/home/dna-fpga-workstation/intelFPGA_pro/24.1/quartus
export QUARTUS_ROOTDIR_OVERRIDE=$QUARTUS_ROOTDIR
# Other OFS environment variables
# export OFS_ROOTDIR=path-to-directory-containing-cloned-ofs-fim-repo/ #ofs-agx7-pcie-attach for Agilex® 7 FPGA or ofs-d5005 for Stratix® 10 FPGA
# export WORKDIR=$OFS_ROOTDIR
export QUARTUS_HOME=$QUARTUS_ROOTDIR
export QUARTUS_INSTALL_DIR=$QUARTUS_ROOTDIR
export IMPORT_IP_ROOTDIR=$QUARTUS_ROOTDIR/../ip
export OPAE_SDK_REPO_BRANCH=release/2.13.0-3 # Refer to Table 2-4 and 2-5, for OPAE SDK branch tag
export OFS_PLATFORM_AFU_BBB=/home/dna-fpga-workstation/Documents/ofs-platform-afu-bbb
# export OPAE_PLATFORM_ROOT=path-to-ofs-fim-pr_build_template-directory # (see section 2.2 for more details)
export OFS_ASP_ROOT=/opt/intel/oneapi/compiler/2025.0/opt/oclfpga/board/oneapi-asp-a7sk
#export OFS_ASP_ROOT=/home/dna-fpga-workstation/Documents/oneapi-asp/fseries-dk #platform-name is n6001 for Intel® FPGA SmartNIC N6001-PL, fseries-dk for Agilex® 7 FPGA F-Series Development Kit (2x F-Tile), iseries-dk for Agilex® 7 FPGA I-Series Development Kit (2x R-Tile and 1xF-Tile) and d5005 for Intel® FPGA PAC D5005. 
export LIBOPAE_C_ROOT=/usr # (OPAE libraries are installed in /usr/lib64 by default if you followed the OPAE SDK steps covered in section 2.1 as is and installed OPAE rpm packages. If you have a different OPAE installation path, please point LIBOPAE_C_ROOT to your OPAE installation location that you specified using -DCMAKE_INSTALL_PREFIX=installation-path in cmake command for building OPAE)
```

The next part is about build and install the asp.
As I use the A7SK, I'll use the asp given by Terasic and install it with `aocl install oneapi-asp-a7sk`.

Doing `aocl list-devices` I have an error saying `p is NULL` and a warning "No device attached for packages : .../oneapi-asp-a7sk".
I can either search more on that error/warning or try to build the fseries asp of the guide.


## Sunday : 20 July

After some research, the DKMS package I installed (intel-fpga-dfl-dkms-1.11.0-2) back-ports the drivers into the running kernel.
It does not create a new kernel named 4.18.0-dfl.
Therefore the driver files live under `/usr/lib/modules/4.18.0-477.27.1.el8_8.x86_64/extra/…` instead of `/usr/lib/modules/4.18.0-dfl/kernel/drivers/fpga/…`.
This difference is cosmetic, the functionality is identical.

I understand that what was missing on my setup was the Accelerator Support Package (ASP) and the FPGA Interface Manager (FIM).
The way we normally install them is by building with a Git repos.
I start doing it to see how it was, but for my setup (using the A7SK) both was given in the A7SK oneAPI 2024.0.

The ASP was already installed by doing the `aocl install oneapi-asp-a7sk` after downloading it and putting it into a specific folder (see A7SK oneAPI guide).
For the FIM it was necessary to run the `bringup_fpga.sh` and to reboot the system.
After that, I was able to see the FPGA doing :

```bash
lspci -d 8086:bcce
01:00.0 Processing accelerators: Intel Corporation Device bcce (rev 01)
01:00.1 Processing accelerators: Intel Corporation Device bcce
01:00.2 Processing accelerators: Intel Corporation Device bcce
01:00.3 Processing accelerators: Intel Corporation Device bcce
01:00.4 Processing accelerators: Intel Corporation Device bcce
```

```bash
aoc -list-boards
Board list:
  a7sk (default)
     Board Package: /opt/intel/oneapi/compiler/2025.0/opt/oclfpga/board/oneapi-asp-a7sk

  a7sk_usm
     Board Package: /opt/intel/oneapi/compiler/2025.0/opt/oclfpga/board/oneapi-asp-a7sk
     Memories:      device, host
```

The fact that it worked on RHEL 8.8 and not on Ubuntu 22.04 is really a mystery for me.

To try SYCL on FPGA I decide to download some code sample.
I try divers method, code and others, but what worked for me was the "[vector-add](https://github.com/oneapi-src/oneAPI-samples/tree/release/2024.2/DirectProgramming/C%2B%2BSYCL/DenseLinearAlgebra/vector-add)" example.
At least, it's what worked the better.

Trying the FPGA simulation doing `icpx -fintelfpga -DFPGA_SIMULATOR vector-add-buffers.cpp -Xssimulation -Xstarget=a7sk -Xsghdl -o vector-add-sim-buffers.fpga_sim` and running it via `./vector-add-sim-buffers.fpga_sim`.
I got this "error" :

```
An exception is caught for vector add.
terminate called after throwing an instance of 'sycl::_V1::exception'
  what():  No device of requested type available. Please check https://software.intel.com/content/www/us/en/develop/articles/intel-oneapi-dpcpp-system-requirements.html
Aborted (core dumped)
```

About the FPGA hardware, compiling with `icpx -fintelfpga -DFPGA_HARDWARE vector-add-buffers.cpp -Xshardware -Xstarget=a7sk -o vector-add.fpga`, I got this message :

```
aoc: Compiling for FPGA. This process may take several hours to complete.  Prior to performing this compile, be sure to check the reports to ensure the design will meet your performance targets.  If the reports indicate performance targets are not being met, code edits may be required.  Please refer to the oneAPI FPGA Optimization Guide for information on performance tuning applications for FPGAs.
Error (24155): The Quartus Partition Database File 'ofs_top.qdb' was generated using version 'Version 23.2.0 Build 94 06/14/2023 Patches 0.02iofs,0.11,0.19,0.02 SC Pro Edition', which cannot be read by the current version of the Quartus Prime software. Regenerate 'ofs_top.qdb' using the current version of the Quartus Prime Software.

[...]

icpx: error: fpga compiler command failed with exit code 1 (use -v to see invocation)
```

When I search for the `ofs_top.qdb`, I don't know if they are talking about the one in the ASP or in the `vector-add` project.
If it's the one in the ASP, I might need to install Quartus Prime Pro 23.2.
When compiling the oneoligo algorithm, I don't have the same error (maybe because we stop before it), instead I have : `undefined reference to 'tbb::detail::r1::initialize(tbb::detail::d1::task_group_context&)'`, after the `aoc: Simulation generation done`.
For the hardware one it's the same.
Of course, the executable is not generated.

I had to add the `-Wno-enum-constexpr-conversion` in the makefile as some because til Clang/LLVM 16 some warning are now diagnosed as errors.

