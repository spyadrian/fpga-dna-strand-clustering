# Week 6

### Table of contents

1. [Monday 30 June](#monday--30-june)
2. [Tuesday 01 July](#tuesday--01-july)

### Tasks

- [x] Check for Michaël's problem about Bucket converging to 0
- [x] Test FPGA compilation level 2
- [x] Test FPGA compilation level 3
- [ ] Test all levels of the FPGA usage

### Links

- [OneJoin implementation C++/SYCL](https://github.com/Eug9/oneoligo)
- [FPGA tutorial - How to compile SYCL for FPGAs](https://github.com/oneapi-src/oneAPI-samples/tree/master/DirectProgramming/C++SYCL_FPGA/Tutorials/GettingStarted/fpga_compile)


## Monday : 30 June

Writing the intermediate report...

I try to mimic the problems that encounter Michaël and I don't have the same output as him.
I gonna see with him what is happening, and I'm gonna ask him some question about the `-c` and `-K` parameters.

I try to launch the level 2 and 3 of the FPGAs thing.
The 2 named report work great, I can see the report on a html page, I just need to understand it now.
For the level 3 named simulator, I try to launch him on my laptop but forgot that the license was the PC (not the laptop).
I'm gonna try on it later.


## Tuesday : 01 July

During the appointment, we talk about my advancement on the project.
I need to check if the raport that give the FPGA compilation level 2 is only on the compilation.
I just checked it is !
And I need to make a demo for the next appointment.

After setting up the PC and fixing some issue on it (the same I could have on my laptop).
I try the FPGA level 3 on the PC and it run but failed at some point because of libraries dependencies (I'm gonna fix that later).
At first it wasn't working because of the `LM_LICENSE_FILE` and the `PATH` variable that was not set.
The `LM_LICENSE_FILE` need to point on the `.dat` license file and the `PATH` need to have the Quartus executable path and the `questa_fe/linux_x86_64` for the `vsim` script.

