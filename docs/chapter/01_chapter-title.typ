= Titre du chapitre

#lorem(10)

#lorem(30)

Here is a example of cite @shore.

== Titre de niveau 2
#lorem(50)

#figure(
  image("../figure/hepia_logo.png", width: 75%),
  caption: "Hepia logo"
)

=== Titre de niveau 3
#lorem(50)

=== Titre de niveau 3
#lorem(50)

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    [hahaha], [hahaha], [hahaha],
    [hahaha], [hahaha], [hahaha],
    [hahaha], [hahaha], [hahaha],
  ),

  caption: "it's a table !",
)

== Titre de niveau 2
#lorem(50)

=== Titre de niveau 3
#lorem(50)

=== Titre de niveau 3
#lorem(50)

== Titre de niveau 2
#lorem(30)


=== Titre de niveau 3
#lorem(30)

#figure(
  ```c
#include <stdio.h>

  int main() {
      int number1, number2, sum;

      printf("Enter two integers: ");
      scanf("%d %d", &number1, &number2);

      // calculate the sum
      sum = number1 + number2;

      printf("%d + %d = %d", number1, number2, sum);
      return 0;
  }
  ```,

  caption: "Example de code"
)

#lorem(20)

#lorem(30)

=== Titre de niveau 3
#lorem(50)
