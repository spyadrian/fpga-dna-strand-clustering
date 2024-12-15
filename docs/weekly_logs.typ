// --- conf ---

#show link: set text(fill: blue)
#show link: underline
#set page(numbering: "1")

// --- toc ---

#outline(depth: 1)
#pagebreak()

// --- body ---

= Week 1 : Monday 21 October

=== Tasks

The goal of this week is to become as familiar as possible with the subject.
To understand the concepts of DNA and the edit distance aka Levenshtein distance.
If possible I would like to search some on the topics to see how people already approach the problem.

=== Notes

A lot of my work this week was reading article on Wikipedia about Levenshtein distance and DNA.
I saw that a popular algorithm for computing the Levenshtein distance was the Wagner-Fischer algorithm, the same as proposed in the bachelor's project statement.
I'm not sure on how good does it perform on FPGA and if there are alternative that would be better and faster.
I also translated the project statement in English as my work will be in English.

=== Challenges

Most of the documentation is in English, that can be confusing some times.
By the way, that's why I'm writing everything in English from now on.

=== Links

- #link("https://en.wikipedia.org/wiki/DNA")[DNA]
- #link("https://en.wikipedia.org/wiki/Nucleotide")[Nucleotide]
- #link("https://en.wikipedia.org/wiki/Hamming_distance")[Hamming Distance]
- #link("https://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_algorithm")[Wagner-Fischer Algorithm]
- #link("https://en.wikipedia.org/wiki/Haskell")[Haskell]


= Week 2 : Monday 28 November

=== Tasks

The work of last week let me with a lot of question.
The purpose of this week is to get a response at all of these questions.

=== Notes

We send my question to client.
Here a brief of the e-mail concerning the questions and answers :

```
1. Faut-il uniquement regrouper les brins étant les plus proches, ou bien aussi retrouver le brin d'origine ?

Une fois les brins regroupés, il y a une étape supplémentaire qui consiste à les aligner, un autre algorithme qui nécessite de la puissance de calcul (mais qui peut être entièrement parallélisé). Puis, par l'algorithme de consensus, en principe le brin d'origine est retrouvé, avec possiblement des erreurs résiduelles qui seront ensuite corrigées par Reed Solomon. Par conséquent, je doute qu'il soit possible de retrouver le brin d'origine juste pas regroupement.

2. Sous quel format sont représentées les données ? Lors du calcul de la distance de Levenshtein, nous pouvons arranger l'algorithme pour qu'il s'arrête lors du dépassement d'un certain seuil de différence.

Oui, c'est en effet une très bonne approche d'arrêter la recherche dès qu'un seuil est atteint. D'ailleurs, j'ai mis le seuil final à 75%, mais si dès le départ l'algorithme détecte que le brin n'atteindra jamais ce seuil, il serait bien d'arrêter.

3. Y a-t-il des statistiques de mutation et d'erreur ? Pour trouver un tel seuil de distance maximal, il faudra avoir plus d'informations concernant le nombre de mutations et d'erreurs qu'il y a lors des étapes précédentes au regroupement des brins.

Voici les statistiques d'erreur (c'est un modèle Markovien):
    average error rate 10.53933372691147%
    average substitution error rate 4.68370958424587%
    average delete error rate 4.446790618299498%
    average insertion error rate 1.4088335243654426%
    rate of substitution  3.505224923249875e-7
    rate of delete 3.32791797257575e-7
    rate of insertion 1.0543519604473575e-7

4. Quelle est la taille d'un brin ?

La taille est de 207 nucleotides (nts) sans les primers. Les primers (forward et backward) font 18 nts, pour un total donc de 243 nts pour chaque brin. Mais l'idée est de les enlever avant le grouping pour éviter des erreurs de regroupement. Un fichier de 2.7 MB a 2'857'952 brins et 694'442'336 nts.

5. Y a-t-il des particularités aux brins ? Tels que des parties se répétant fréquemment ou bien d'autres ne devant pas apparaître.

Le CODEC a été fait en sorte que le maximum de répétition est 3 nts identiques (homopolymers). Par exemple, pour 47370 homopolymers de taille 2, il y a 3083 homopolymers de taille 3 (et aucun de taille supérieur). Il peut y avoir des patterns qui se répètent, comme ACTACTACT, mais cela est plus compliqué à éviter, mais reste marginal je pense dans le cas d'un fichier qui a une entropie "standard".
```

The rest of the week I read a bit more on the subject.
I discover new algorithm that could be better than Wagner-Fischer, for the moment I didn't read much about them but that'll be the goal of next week. Here are some of the algorithm :

- Smith-Waterman Algorithm
- Needleman-Wunsch Algorithm
- Myers' Algorithm
- Hunt-Mcllroy Algorithm
- BLAST

=== Links

- #link("https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm")[Needleman-Wunsch Algorithm]
- #link("https://en.wikipedia.org/wiki/Smith%E2%80%93Waterman_algorithm")[Smith–Waterman algorithm]
- #link("https://en.wikipedia.org/wiki/Diff")[diff data comparison tool]
- #link("https://stackoverflow.com/questions/42635889/myers-diff-algorithm-vs-hunt-mcilroy-algorithm")[Myers diff algorithm vs Hunt–McIlroy algorithm]
- #link("https://en.wikipedia.org/wiki/BLAST_(biotechnology)")[BLAST]


= Week 3 : Monday 04 November

=== Tasks

The goal of this week is to read more on the algorithms cite on last week notes.
And if possible to find those most suitable for the project.

=== Notes

Sadly I didn't really have time to work this week, I had to much work with others courses due to exams and project submitting.
Despite of it, I learned and understood a bit more about Wagner-Fischer algorithm and Myers' algorithm.

=== Challenges

Exams of advanced virtualisation and design on FPGA in VHDL, on the same day.

=== Links

- #link("https://neil.fraser.name/writing/diff/myers.pdf")[Myers' Paper : An O(ND) Difference Algorithm and Its Variations]
- #link("https://www.nathaniel.ai/myers-diff/")[Visualizing Diffs]
- #link("https://www.mi.fu-berlin.de/wiki/pub/ABI/RnaSeqP4/myers-bitvector-verification.pdf")[FU Berlin course : Bit-parallel string matching]


= Week 4 : Monday 11 November

=== Tasks

This week' purpose is the same as the last one, to read more about the algorithm and find the most suitable one.
Gladly I'll be able to find one or two algorithm that I'll implement this or next week.
This week I'll be a bit more concern about the FPGA part reading about those algorithm.

=== Notes

I figured something quite important.
"DNA Sequence Alignment" is not the same as "Finding the Edit Distance".
Sequence alignment is about finding optimal matches (with gaps allowed), while edit distance is about calculating how many edits are needed to transform one sequence into another.
Sequence alignment's algorithms add step to allows the user to get where are the errors and how to recover them, when edit distance calculator are not.
Half of the algorithms I was reading on, was about sequence alignment, so I had to drop them from the list.
Just in case, BLAST seems to be the best one.

About the remaining algorithm Myers and Wagner-Fischer are the best two options.

I received e-mail of the client containing documents, data, and more informations about the subject.
I didn't had the time to read and understand it all this week.
I'll plan to do it the next one.

=== Challenges

The confusion I had between "DNA Sequence Alignment" and "Finding the Edit Distance", cost me some time.

=== Links

- #link("https://ieeexplore.ieee.org/document/8778371")[HBLast: An Open-Source FPGA Library for DNA Sequencing Acceleration]
- #link("https://ieeexplore.ieee.org/document/5489221")[Optimization of DNA Sequences Data to Accelerate DNA Sequence Alignment on FPGA]
- #link("https://ieeexplore.ieee.org/document/9097943")[Levenshtein Distance, Sequence Comparison and Biological Database Search]
- #link("https://ieeexplore.ieee.org/document/7552284")[Hardware Acceleration of Smith-Waterman Algorithm for Short Read DNA Alignment Using FPGA]


= Week 5 : Monday 18 November

=== Tasks

Goals' week : compare Myers and Wagner-Fischer algorithm and try to implement them.
Also read and understand the document given by the client.

=== Notes

I find a Python library named Polyleven, that claim be "a fast Levenshtein library for Python 3.x.".
My implement will be not in Python, but they had some Technical Notes really interesting, like #link("https://ceptord.net/20200815-Comparison.html")[Wagner-Fischer vs Myers’ Algorithm], #link("https://ceptord.net/20220515-dna100m.html")[Fast fuzzy search on 100 million DNA dataset] and #link("https://ceptord.net/tinyfss/index.html")[TinyFastSS – An Implementatin of FastSS].

In brief, they said that Myers was clearly the best algorithm between them two.

On their website, they also give their C implement of both algorithms with some optimization.
I will take and adapt them to our data entries and perform my own benchmark with those data.

To improve the speed of the computation, Fujimoto Seiji, the author of Polyleven, suggest to use a specific data structure name FastSS. I didn't really understand it, but will work on it later on, when I'll optimize the code and have more informations about the in and out of the project.

=== Challenges

Except the lack of documentation on FastSS, nothing.

=== Links

- #link("https://ceptord.net/index.html")[Polyleven]
- #link("https://ceptord.net/_downloads/5b6d23d8b798b7137ef483a38895eca2/benchmark.c")[C Benchmark of Myers and W-F algorithm]


= Week 6 : Monday 25 November

=== Tasks

As I have an appointment with the client on Wednesday 27, I would like to have a good understanding of all the subject.
In order to do so, this week, I'll be reading and understand the documents he give us and make or find some documents to back up my words.

=== Notes

At first, my teacher and me, though to use slide to present something to the client, but I found it a bit to much.
So I just took some important file that help me understand both algorithms.

The appointment went well, I could have a bit more explaining about the context of the project and additional informations about the input and output of my task in it.
I write note of the appointment available on the misc folder.

During this appointment I clarify with the client, that I'll focus for the moment on data of DNA of segment not corrupt.
It's an easier start and it allow me to focus and the main task of my project, segment grouping.

= Week 7 : Monday 2 December

=== Tasks

This week I planed to work on three different thing :
- Write about the context of the project (it will be something important during the presentation)
- Make a benchmark of both algorithms
- Test different entries format

=== Notes

Unfortunately I wasn't able to work this week due to the work load that I had from my courses.


= Week 8 : Monday 9 December

=== Tasks

As I couldn't work last week, I'm going to work on the same thing as last week, focusing on making a benchmark with the data that I received from the client.

=== Notes

I rewrite the benchmark program from Fujimoto Seiji to be able to change the length of the string input and the number of string compared.
Something really interesting happens, as the length of the string increase, the time taken by Myers get longer than the one by Wagner-Fischer.

I show that to my teacher, and he underline that the Wagner-Fischer algorithm was faster on a larger group of string of large length than with a small group of small length string.
Something might be wrong with my implementation of the algorithm.

On top of that, I'm not sure that Myers is working properly because the length of the string compared is bigger than the word of a machine.


