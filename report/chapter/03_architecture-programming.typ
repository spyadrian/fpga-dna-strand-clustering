#import "../conf.typ": *

= FPGA : Hardware Architecture and Programming

== The Agilex 7 Starter Kits

The Agilex 7 Starter Kit, abbreviated as A7SK, is a development board created by Terasic.
It leverages the latest Intel (formerly Altera) Agilex 7 SoC FPGA F-Series device, featuring 2.7 million logic elements.
It comes with an Hard Processor System (HPS) ARM Cortex-A53 quad-core 64 bits working up to 1,5GHz.
The board offers multiple interfaces including PCI Express 4.0 x8 and up to 16GB of DDR4 memory to provide optimal acceleration.
In top of that it provide $259"Mb"$ of M20K and $28"Mb"$ of MLAB memory.
Additionally, the board includes an FMC+ expansion connector, enabling compatibility with a variety of daughter cards for extended functionality.

The Agilex 7 FPGA fabric delivers 50% higher performance and 40% lower power consumption compared to previous generation devices, making it ideal for demanding workloads.
The board also supports Intel's oneAPI and OpenCL frameworks, allowing developers to easily customize hardware acceleration workloads.
Below is a block diagram showing all the peripherals of the A7SK :

// source: link("https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=142&No=1295&PartNo=2", [Agilex 7 FPGA Starter Kit Specification]),
#figure(
  caption: [Block diagram of The Agilex 7 Starter Kits],

  image("../figure/a7sk_blockdiagram.jpg", width: 100%)
)


== Open FPGA Stack (OFS)

Open FPGA Stack (OFS) is a fully open-source hardware and software infrastructure that is transforming the development of custom FPGA platforms.
It consists of multiple components that enable rapid FPGA development and is available through their Git repositories.
OFS is utilized by Intel (formerly Altera) as well as by several third-party platforms, supporting Intel FPGA families such as Stratix® 10, Agilex™ FPGA, and future devices.

// source: link("https://ofs.github.io/ofs-2024.3-1/", [Open FPGA Stack Overview]),
#figure(
  caption: [Base FPGA Interface Manager (FIMs)],

  image("../figure/base-fim.png", width: 100%)
)

=== Infrastructure Hardware

The FPGA Interface Manager (FIM) acts as the foundational "shell" that provides platform management, functionality, clocks, resets, and standard interfaces to both the host system and the Accelerator Functional Unit (AFU).
Think of the FIM as the operating system for the FPGA, it handles all the low-level communication protocols and platform-specific details so that developers can focus on their actual application logic.
These reference FIMs are provided as working examples to help users develop their own custom platforms.

The Accelerator Functional Unit (AFU) is the dedicated region where custom workload implementations are deployed.
This is where the OneJoin algorithm would be implement.
The AFU includes partial reconfiguration (PR) regions for dynamic programming, meaning you can update your algorithm implementation without reconfiguring the entire FPGA.

Essentially, the AFU is the computational heart of your FPGA design, it performs the actual data processing work, while the FIM handles all the platform-specific interfaces and communication protocols.

The Board Management Controller (BMC) is responsible for controlling, monitoring, and granting access to board features like power management, thermal monitoring, and others.
It provides root of trust and authentication to verify that bitstreams come from a trusted source.

The oneAPI Accelerator Support Package (ASP) is a collection of hardware and software components enabling High-Level Design (HLD) workload support.
HLD abstracts the FPGA hardware and design flow, enabling users to design FPGA custom hardware using familiar programming languages like SYCL and development environments.

This is particularly relevant for the project since it uses SYCL to implement the algorithms talk earlier.
The ASP provides the necessary abstraction layer between the SYCL code and the underlying FPGA hardware, allowing to focus on the algorithm implementation rather than low-level hardware details.

=== Infrastructure Software

The open-source kernel drivers provide a layer that decomposes implemented functionality into sets of individual device features.
These drivers handle the low-level communication between your host system and the FPGA hardware.
The DFL kernel drivers represent a specialized layer of the Linux kernel.
It defines a list structure of feature headers within the device MMIO (Memory-Mapped Input/Output) space, creating an extensible way of adding and discovering FPGA features.

The Open Programmable Acceleration Engine (OPAE) libraries and APIs are lightweight, user-space libraries that provide abstraction for FPGA resources.
OPAE installs tools to expedite development, providing useful functions such as displaying FPGA information, implementing secure firmware updates, enabling virtualization, downloading new images to the board, and more.
These tools are essential for debugging and monitoring the implementation of the project.


== Setup

While working on the project, I encountered many errors related to incompatible versions of different tools.
During an initial attempt on my base distro CachyOS, I was unable to correctly configure the environment.
One of the several errors I encountered concerned the compatibility between libc and gcc, which I was unable to resolve.
A second attempt was made on Ubuntu 22.04. This one is said to be compatible with all the tools, yet when using the A7SK board, it did not respond.
This was likely due to an error related to a poorly configured kernel.
Finally, the configuration I used is very close to the one recommended by OFS for oneAPI on Agilex 7 series F FPGAs.
Here is a summary table:

#figure(
  caption: [Versions of components and tools used for FPGA development],

  table(
    columns: 2,
    align: left,
    table.header([*Component / Tool*], [*Version*]),
    [FPGA Platform], [Agilex® 7 FPGA F-Series Development Kit (2x F-Tile)],
    [Operating System], [RHEL 8.8 , Kernel : 4.18.0-477],
    [Linux Kernel Driver], [Tag: intel-1.11.0-2],
    [OPAE], [Branch: release/2.13.0, Tag: 2.13.0-3],
    [OFS], [Tag: ofs-2024.2-1],
    [ASP], [oneapi-asp-a7sk],
    [Quartus Prime Pro Edition], [Version 23.2 Pro Edition],
    [Intel® oneAPI Base Toolkit], [2025.0.1],
    [FPGA Support Package], [2025.0.1]
  )
)

These versions were specifically chosen to be compatible with FPGA.
Notably, the oneAPI Base Toolkit is at version 2025.2.0 but no longer includes FPGA support since version 2025.1.0.
Additionally, certain hardware features must be present on the PC using the configuration.
Such as Single Root I/O Virtualization (SR-IOV), a technology that allows a PCI Express device, like an FPGA, to be shared among multiple virtual machines (VMs) while maintaining near-native hardware performance.
For Intel CPUs, this feature is available on 8th generation or newer CPUs, which was not my case and forced me to completely change machines.
Another feature to enable in the BIOS is the IOMMU (Input-Output Memory Management Unit), which ensures secure and efficient management of direct memory access (DMA) between PCIe devices and system memory.

