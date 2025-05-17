#import "../conf.typ": summary

= Summary

#summary(
  teacher: [Laurent Gantel],
  appliant: [Spycher Adrian],
  company: [UNIGE, DNAMIC],
  internship_agreement: false,
  confidentiality_agreement: false,

  img: image("../figure/illusatration.jpg", width: 70%),
  content: [

    Today, the entire world is accumulating enormous amounts of computer data.
    This forces the construction of polluting infrastructure and wastes energy.
    DNAMIC is a European project that aims to store data in synthetic DNA.
    To achieve this, a microfactory will be created to read and write on synthetic DNA.
    This microfactory contains six steps: encoding, synthesis, amplification, storage, sequencing, and finally, decoding.
    After reading the DNA, errors can appear, either via the reading device or due to DNA mutations.
    To correct these errors, the PCR technique is used to multiply the DNA.
    With copies of the DNA, it becomes easier to correct errors.
    This is where sequence assembly, a sub-step of the microfactory, comes into play, as it's necessary to group the copies relative to their original DNA.
    Grouping these copies requires calculating their Levenshtein distance.
    A metric that gives the number of operations required to get from one string $a$ to another string $b$.
    These operations are the same as those that can occur in DNA mutations: substitution, addition, and deletion.
    In order to handle the largest possible amount of data, the greatest possible speed is required.
    The goal of this project is to leverage the speed of FPGAs to accelerate this calculation.
    The first step in this project is to find the most viable algorithm for this task.
    This is Myers' bit-parallel algorithm.
    An initial implementation in C is carried out for testing and familiarization purposes with the algorithm.
    The next step is to create a VHDL implementation of this algorithm.
    This has been covered in this project.
  ],
)
