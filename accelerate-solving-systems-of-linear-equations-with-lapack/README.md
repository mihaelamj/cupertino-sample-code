# Solving systems of linear equations with LAPACK

Select the optimal LAPACK routine to solve a system of linear equations.

## Overview

The Accelerate framework provides the LAPACK library for numerical linear algebra. A basic technique of linear algebra is to solve systems of simultaneous equations. For example, the following shows three equations that contain the unknowns _x_, _y_, and _z_:

![Set of three simultaneous equations.](Documentation/simultaneous-equations_2x.png)

You can solve this system by rewriting the simultaneous equations as a matrix equation with the following form:

![Mathematical formula that describes the matrix equation, A x equals b. A three-by-three matrix multiplied by a three-element column matrix equals a three-element column matrix.](Documentation/simulataneous-ax=b_2x.png)

This form is an _Ax = b_ form, where _A_ is the coefficient matrix, _x_ is a column vector that contains the unknown values, and _b_ is a column vector that contains the constant values. The number of elements in _x_ is equal to the number of columns of _A_, and the number of elements in _b_ is equal to the number of rows of _A_.  

The process of solving this system computes the values for _x_, _y_, and _z_ as `-2`, `24`, and `8`, respectively.

![Mathematical formula that describes the matrix equation, A x equals b with the computed unknowns on the left, and the same system as a set of simultaneous equations on the right.](Documentation/simultaneous-solution_2x.png)

For an example of solving a linear system, see [Finding an Interpolating Polynomial Using the Vandermonde Method](https://developer.apple.com/documentation/accelerate/finding_an_interpolating_polynomial_using_the_vandermonde_method).

 LAPACK includes routines for solving systems of linear equations as _Ax = b_. This sample code project includes wrapper functions that simplify calling the LAPACK routines, for example, by encapsulating multiple-step workflows into a single function call. 
 
 Run the sample code app to see the results of each routine solve different example systems. 
 
 ## Determine the properties of the coefficient matrix
 
 LAPACK provides different solving routines depending on the properties of the coefficient matrix, _A_:
 
 * Is the coefficient matrix _symmetric_? A symmetric matrix is one that's equal to its transpose, that is, a matrix that's identical when swapping its row and column indices. A symmetric matrix is necessarily square. The following is an example of a symmetric matrix:
 
 ![Matrix that consists of five rows and five columns of numbers. The numbers in the first row are the same as those in the first column. The numbers in the second row are the same as in the second column, and so forth.](Documentation/symmetric_2x.png)
 
 * Is the coefficient matrix _positive definite_? A matrix is positive definite if all of its [eigenvalues](https://mathworld.wolfram.com/Eigenvalue.html) are positive. Confirm whether a matrix is positive definite by calling `spotrf_(_:_:_:_:_:)` to try a [Cholesky factorization](https://mathworld.wolfram.com/CholeskyDecomposition.html). If the factorization fails and returns a positive value, the matrix isn't positive definite. This sample code project includes the function `isPositiveDefinite(_:dimension:)` to determine whether a matrix is positive definite.
 * Is the coefficient matrix _banded_? A banded matrix has all of its nonzero entries on its main diagonal and an arbitrary number of superdiagonals (above the main diagonal) and subdiagonals (below the main diagonal). The following is an example of a nonsymmetric, banded matrix with two superdiagonals and one subdiagonal:
 
 ![Matrix that consists of five rows and five columns of numbers representing a nonsymmetric, banded matrix.](Documentation/banded_2x.png)
 
 * Is the coefficient matrix _tridiagonal_? A tridiagonal matrix has all of its nonzero entries on its main diagonal, its first superdiagonal, and its first subdiagonal. The following is an example of a nonsymmetric, tridiagonal matrix:
 
 ![Matrix that consists of five rows and five columns of numbers representing a nonsymmetric, tridiagonal matrix.](Documentation/tridiagonal_2x.png)
 
 If the coefficient matrix is _sparse_, that is, most of the entries in the coefficient matrix are zero, Accelerate provides the [Sparse Solvers](https://developer.apple.com/documentation/accelerate/sparse_solvers) library to help solve such systems.
 
## Select LAPACK variants for data types 

The LAPACK routines in this sample code project are all for real, single-precision matrices. All of the routines are available in single- and double-precision for real and complex values. The first character of a routine name defines the type of data the routine works on. For example:

* `sgels_(_:_:_:_:_:_:_:_:_:_:_:)` — single-precision, real values
* `dgels_(_:_:_:_:_:_:_:_:_:_:_:)` — double-precision, real values
* `cgels_(_:_:_:_:_:_:_:_:_:_:_:)` — single-precision, complex values
* `zgels_(_:_:_:_:_:_:_:_:_:_:_:)` — double-precision, complex values

For complex matrices, the LAPACK routine variant for real symmetric matrices requires [Hermitian matrices](https://mathworld.wolfram.com/HermitianMatrix.html). For example, the `cptsv_()` routine computes the solution to _Ax = b_ for a complex single-precision, Hermitian, tridiagonal coefficient matrix; and `sptsv_()`  computes the solution for a real single-precision, symmetric, tridiagonal coefficient matrix.

The routines in this sample code project are suitable for solving full rank systems, that is, they have a unique and exact solution.

## Define values in column-major layout

The LAPACK routines in this article require the matrix data in column-major layout, which means specifying all the terms in the first column, then all of the terms in the second column, the third column, and so on. For example, if there are two columns with three row values each, the routine specifies the three row values for column one, then the three row values for column two, as the following example illustrates:

![Matrix that consists of three rows and two columns of numbers. The first column has the values 80, 180, and 160. The second column has the values 800, 1800, and 1600.](Documentation/b-matrix_2x.png)

``` swift
let bValues: [Float] = [80, 180, 160,
                        800, 1800, 1600]
```

The routines return the result as column-major, for example, an array that contains `[10.0, 20.0, 30.0, 100.0, 200.0, 300.0]` represents the following matrix: 

![Matrix that consists of three rows and two columns of numbers. The first column has the values 10, 20, and 30. The second column has the values 100, 200, and 300.](Documentation/x-matrix_2x.png)

## Select the solving routine for the coefficient matrix type 

This sample code project provides Swift wrapper functions to each single-precision LAPACK solving routine. Select the routine that most closely matches the coefficient matrix for the highest performance. The following shows the Swift wrapper functions and the underlying LAPACK routines to solve systems with different coefficient matrices:

* Symmetric
    * Positive definite
        * Tridiagonal
            * Swift wrapper function: [ `symmetric_positiveDefinite_tridiagonal()`](x-source-tag://symmetric_positiveDefinite_tridiagonal)
            * Underlying LAPACK routine: `sptsv_()`
        * Other banded
            * Swift wrapper function: [`symmetric_positiveDefinite_banded()`](x-source-tag://symmetric_positiveDefinite_banded)
            * Underlying LAPACK routine: `spbsv_()`
        * General
            * Swift wrapper function: [`symmetric_positiveDefinite_general()` ](x-source-tag://symmetric_positiveDefinite_general)
            * Underlying LAPACK routine: `sposv_()`
    * Indefinite
        * General
            * Swift wrapper function: [`symmetric_indefinite_general()` ](x-source-tag://symmetric_indefinite_general)
            * Underlying LAPACK routine:  `ssysv_()`
* Nonsymmetric
    * Square
        * Tridiagonal
            * Swift wrapper function: [`nonsymmetric_tridiagonal()`](x-source-tag://nonsymmetric_tridiagonal)
            * Underlying LAPACK routine: `sgtsv_()`
        * Other banded
            * Swift wrapper function: [`nonsymmetric_banded()`](x-source-tag://nonsymmetric_banded)
            * Underlying LAPACK routine: `sgbsv_()`
        * General
            * Swift wrapper function: [`nonsymmetric_general()`](x-source-tag://nonsymmetric_general)
            * Underlying LAPACK routine: `sgesv_()`
    * Nonsquare
        * QR factorization
            * Swift wrapper function: [`nonsymmetric_nonsquare()`](x-source-tag://nonsymmetric_nonsquare)
            * Underlying LAPACK routine: `sgels_()`
        * Cholesky factorization
            * Swift wrapper function: [`leastSquares_nonsquare()`](x-source-tag://leastSquares_nonsquare)
            * Underlying LAPACK routines: `sposv_()` and `ssysv_()`

## Solve for a nonsquare matrix using QR factorization

A system of linear equations with a nonsquare coefficient matrix is either:

* Overdetermined — there are more equations than unknowns, that is, the coefficient matrix has more rows than columns. In this case, the system may not have a solution.
* Underdetermined — there are more unknowns than equations, that is, the coefficient matrix has more columns than rows. In this case, the system may have infinitely many solutions.

In these cases, the solution is either not exact (unless the overdetermined system is actually consistent) or not unique. In the case where LAPACK is unable to solve the system, the Swift wrapper functions return `nil`.

The Swift wrapper function `nonsymmetric_nonsquare(a:dimension:b:rightHandSideCount:)` wraps the LAPACK routine `sgels_(_:_:_:_:_:_:_:_:_:_:_:)`. This routine takes one of two approaches, depending on the system:

* When the coefficient matrix, _A_, has more rows than columns (overdetermined), the routine minimizes the error in _Ax - b_ by solving the least squares problem _‖ b-Ax ‖₂_. The following image shows the graph of an overdetermined system with two unknowns and three equations.  `nonsymmetric_nonsquare(a:dimension:b:rightHandSideCount:)`  returns `[1.4615387, 0.7692307, -1.1766968]`, indicating the _x_ in _Ax=b_ equals  `[1.4615387, 0.7692307]`, and the sum of the residuals squared (that is, `r0² + r1² + r2²` equals `-1.1766968²`). Selecting any other point in the triangle of the three intercepts yields a larger sum of residuals squared.

![A line chart that contains three lines with the slope intercepts of y equals minus x plus 2, y equals 2 x minus 4, and y equals x plus 0. The three lines form a triangle and a marked point within the triangle represents the result of minimizing A x minus b.](Documentation/accelerate-solving-systems-linear-equations-1_2x.png)

![A series of equations that show the slope intercepts as A x equals b with the constants on the right.](Documentation/overdetermined_graph_2x.png)

* When the coefficient matrix, _A_, has more columns than rows (underdetermined), the routine finds the smallest _x_ that solves the equation _min ‖ x ‖₂_ such that _Ax = b_.  The following image shows the graph of _y=x+1_, which is the set of solutions to the illustrated system. The closest point on the line to the origin is at x = -0.5, y = 0.5.

![A line chart that contains a single line with the slope intercept of y equals x plus 1, and a marked point that’s nearest to the chart origin.](Documentation/accelerate-solving-systems-linear-equations-2_2x.png)

![A series of equations that show the slope intercept as A x equals b with the constants on the right.](Documentation/underdetermined_graph_2x.png)

The `sgels_(_:_:_:_:_:_:_:_:_:_:_:)` routine uses [QR factorization](https://mathworld.wolfram.com/QRDecomposition.html) for overdetermined systems, and [LQ factorization](https://mathworld.wolfram.com/LQDecomposition.html) for underdetermined systems.

The following is an example of an underdetermined system with a coefficient matrix that's nonsquare:

![Mathematical formula that describes the matrix equation, A x equals b. A three-by-five matrix multiplied by a five-element column matrix equals a three-element column matrix.](Documentation/nonsymmetric-nonsquare_2x.png)

The following code calls `nonsymmetric_nonsquare(a:dimension:b:rightHandSideCount:)` to compute the values of _x_:

``` swift
let aValues: [Float] = [1, 6, 11,
                        2, 7, 12,
                        3, 8, 13,
                        4, 9, 14,
                        5, 10, 15]

let dimension = (m: 3, n: 5)

/// The _b_ in _Ax = b_.
let bValues: [Float] = [355, 930, 1505]

/// Call `nonsymmetric_nonsquare` to compute the _x_ in _Ax = b_.
let x = nonsymmetric_nonsquare(a: aValues,
                               dimension: dimension,
                               b: bValues,
                               rightHandSideCount: 1)

/// Calculate _b_ using the computed _x_.
if let x = x {
    let b = matrixVectorMultiply(matrix: aValues,
                                 dimension: dimension,
                                 vector: x)
    
    /// Prints _b_ in _Ax = b_ using the computed _x_: `~[355, 930, 1505]`.
    print("\nnonsymmetric_nonsquare: ([355, 930, 1505]) b =", b)
}
```

## Solve for a nonsquare matrix using Cholesky factorization

Where speed is more important than numerical accuracy, the sample code project provides an alternative to `sgels_(_:_:_:_:_:_:_:_:_:_:_:)`. The `leastSquares_nonsquare(a:dimension:b:)` function exploits the fact that the _x_ in _AᵀAx = Aᵀb_ equals the _x_ in _Ax = b_. This technique creates the square coefficient matrix _AᵀA_ and solves with either `symmetric_positiveDefinite_general(a:dimension:b:rightHandSideCount:)` or `symmetric_indefinite_general(a:dimension:b:rightHandSideCount:)`.

The `leastSquares_nonsquare(a:dimension:b:)` function uses the same problem as   `nonsymmetric_nonsquare(a:dimension:b:rightHandSideCount:)`, but uses [Cholesky factorization](https://mathworld.wolfram.com/CholeskyDecomposition.html) when _AᵀA_ is positive definite.

The following is an example of an overdetermined system with a coefficient matrix that's nonsquare:

![Mathematical formula that describes the matrix equation, A x equals b. A four-by-three matrix multiplied by a three-element column matrix equals a four-element column matrix.](Documentation/leastsquares-nonsquare_2x.png)

The following code calls `leastSquares_nonsquare(a:dimension:b:)` to compute the values of _x_:

``` swift
let aValues: [Float] = [1, 4, 7, 10,
                        2, 5, 8, 11,
                        3, 6, 9, 12]
let dimension = (m: 4, n: 3)
let bValues: [Float] = [194, 455, 716, 977]

/// Call `leastSquares_nonsquare` to compute the _x_ in _Ax = b_.
let x = leastSquares_nonsquare(a: aValues,
                               dimension: dimension,
                               b: bValues)

/// Calculate _b_ using the computed _x_.
if let x = x {
    let b = matrixVectorMultiply(matrix: aValues,
                                 dimension: dimension,
                                 vector: Array(x[0..<3]))
    
    /// Prints _b_ in _Ax = b_ using the computed _x_: `~[194, 455, 716, 977]`.
    print("\nleastSquares_nonsquare: b =", b)
}
```

## Solve for a rank-deficient matrix

Systems with a symmetric matrix that’s not full rank, _rank-deficient matrices_, don’t have a single unique solution. For example, the following two multiplications contain different _x_ matrices, but yield the same result in _b_:

![Two stacked mathematical formulas that describe the matrix equation, A x equals b. Each formula is a three-by-three matrix multiplied by a three-element column matrix that equals a three-element column matrix. In both cases, matrices A and b contain the same values, but matrix x has different values.](Documentation/symmetric-indefinite-general_2x.png)

In this case, passing matrix _A_ to its most suitable function, `symmetric_indefinite_general(a:dimension:b:rightHandSideCount:)`, returns an error indicating that the routine can’t compute the solution.

One option to deal with rank-deficiency is to instead solve a nearby problem of full rank by adding a small epsilon value to the matrix to regularize it. The following code adds such an epsilon to diagonal elements in matrix _A_:

``` swift
var aValues: [Float] = [1, 2, 1,
                        2, 1, 2,
                        1, 2, 1]

let dimension = 3
let epsilon = sqrt(Float.ulpOfOne)
for i in 0 ..< dimension {
    aValues[i * dimension + i] += epsilon
}

let bValues: [Float] = [80, 100, 80]

/// Call `symmetric_indefinite_general` to compute the _x_ in _Ax = b_.
let x = symmetric_indefinite_general(a: aValues,
                                     dimension: dimension,
                                     b: bValues,
                                     rightHandSideCount: 1)

/// Calculate _b_ using the computed _x_.
if let x = x {
    let b = matrixVectorMultiply(matrix: aValues,
                                 dimension: (m: dimension, n: dimension),
                                 vector: x)
    
    /// Prints _b_ in _Ax = b_ using the computed _x_: `~[80, 100, 80]`.
    print("\nRank-Deficient: b =", b)
}
```

On return, _x_ contains the values `[0.0, 20.0, 40.0]`:

![Mathematical formula that describes the matrix equation, A x equals b. A three-by-three matrix multiplied by a three-element column matrix equals a three-element column matrix.](Documentation/symmetric-indefinite-general-2_2x.png)
