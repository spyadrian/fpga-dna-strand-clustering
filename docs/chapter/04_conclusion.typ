#heading(level: 1, numbering: none, [Conclusion])

// Summary of Achievements
// - briefly summarizing the motivation behind the project
// - recap the main steps taken throughout the project

This project involved hardware acceleration of a Levenshtein distance calculation algorithm between two strings, in this case DNA strands.
After researching and gaining a thorough understanding of the different existing algorithms, the algorithms were compared.
The most suitable algorithm for this project was the Myers algorithm.
It is one of the fastest Levenshtein distance calculation algorithms and, more importantly, it is very well-suited for FPGAs.
For testing purposes, it was implemented in C alongside one of its competitors, the Wagner-Fischer algorithm.
Their tests concluded that the Myers algorithm was indeed the most suitable for this project.
Following this, a review and initial VHDL implementation were undertaken.
This review focused on the overall architecture of the project and the circuit components. The most important component of all was implemented first, namely the Myers core component.
This expected behavior was explained in the last section of this document.

// Main Challenges and Solutions
// - acknowledge the difficulties encountered
// - summarize the solutions you found to overcome these challenges

During this project, there were many challenges to overcome.
One of them, which was certainly the most challenging, was the research on alignment algorithms and Levenshtein distance calculations.
Indeed, algorithms are often not well defined; they are rather a base upon which many scientists add their own grain of sand.
Whether optimizations for time complexity, space complexity, or modifications to adapt the algorithm to other purposes, it is difficult at first glance to obtain clear and precise information.
This information is often subject to change during the research.
Even during the writing of these last chapters, new optimizations were found on some of the algorithms.

// Impact and Contributions
// - reflect on how your work contributes to the dnamic project and the field of dna data storage
// - mention how the acceleration of the levenshtein distance calculation can make large-scale dna clustering feasible

The bachelor's project will aim to accelerate a crucial step in the DNAMIC project's microfactory.
Accelerating the calculation of the Levenshtein distance will allow for the management of much larger amounts of data, providing a vision for the future of this microfactory.
This semester project allowed us to learn about and evaluate the possibilities of this optimization.
This was a necessary step that ensures the project is moving in the best possible direction.

// Future Work and Perspectives
// - suggest potential improvements

The VHDL implementation of the Myers algorithm remains a prototype for the time being, and will be used for the bachelor's project.
This approach provides a good start to the problem, but does not take into account certain issues that will arise when scaling the system.
Such as managing synchronization between different processing units, optimizing software and hardware resources, and improving error handling at large scales.
Furthermore, aspects related to computational parallelization and efficient memory usage will need to be considered to ensure optimal performance in more complex environments.

// Final Remarks
// - conclude by emphasizing the significance of hardware acceleration in solving scalability challenges in dna data storage
// - express your confidence that the work carried out will have a positive impact on the dnamic project and related research efforts

// ...
