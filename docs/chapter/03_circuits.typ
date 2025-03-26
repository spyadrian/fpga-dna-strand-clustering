= VHDL Implementation and hardware Optimization
// - introduce the challenges of implementing string-matching algorithms on FPGAs
// - state the motivation for hardware acceleration and its potential benefits

// ...

== Architecture Overview
// - present the overall architecture of the VHDL implementation
// - use a block diagram to illustrate the major components and how they interact
// - describe the data flow, pipelining strategies, and parallelization techniques used.

// ...

== Module Description
// - explain the different VHDL modules you designed, including their purpose and interaction
// - include key components such as distance calculation, input handling, and output processing

// ...

== Finite State Machine Design
// - explain why an FSM is needed, e.g., to control data flow, manage states efficiently, or coordinate multiple components
// - describe the states of the FSM and the transitions between them
// - detail how the FSM is coded in VHDL, including state encoding and transition logic
// - discuss how it interacts with the core component and manages the input and output

// ...

== Core Component of Myers' Algorithm
// - briefly recall the Myers algorithm and its role in calculating the Levenshtein distance
// - describe the structure of the core component, including input, processing, and output
// - discuss how the component handles parallelism or pipelining to maximize throughput
// - go through the critical parts of the VHDL code, explaining how you mapped the algorithm to hardware
// - highlight key optimizations, such as reducing computation cycles or leveraging FPGA-specific features
// - explain how you verified the correctness of the core component through simulations and testbenches
//(- present performance results compared to the C implementation)

// ...
