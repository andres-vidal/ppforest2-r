# ppforest2: Projection Pursuit Oblique Decision Trees and Random Forests

Builds decision trees by splitting on linear combinations of randomly
chosen variables. Projection pursuit is used to choose a projection of
the variables that best separates the groups. Using linear combinations
of variables to separate groups takes the correlation between variables
into account, which allows the model to outperform a traditional
decision tree when the separation between groups occurs in combinations
of variables. Single trees can be assembled into random forests for
improved accuracy. Implements projection pursuit classification trees
(Lee, Cook, Park and Lee (2013)
[doi:10.1214/13-EJS810](https://doi.org/10.1214/13-EJS810) ) and
projection pursuit forests (da Silva, Cook and Lee (2021)
[doi:10.1080/10618600.2020.1870480](https://doi.org/10.1080/10618600.2020.1870480)
), following the earlier 'PPforest' package.

## See also

Useful links:

- <https://andres-vidal.github.io/ppforest2-r/>

- <https://github.com/andres-vidal/ppforest2-r>

- Report bugs at <https://github.com/andres-vidal/ppforest2-r/issues>

## Author

**Maintainer**: Andrés Vidal <andres@andresvidal.dev> \[copyright
holder\]

Authors:

- Natalia da Silva

Other contributors:

- Niels Lohmann (Author of the bundled nlohmann/json library)
  \[copyright holder\]

- Melissa O'Neill (Author of the bundled PCG random number generator)
  \[copyright holder\]
