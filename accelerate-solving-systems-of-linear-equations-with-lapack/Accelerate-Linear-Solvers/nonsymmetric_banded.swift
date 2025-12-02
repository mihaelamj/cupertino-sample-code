/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Solver function for nonsymmetric banded matrices.
*/


import Accelerate

/// Returns the _x_ in _Ax = b_ for a nonsymmetric, banded coefficient matrix using `sgbsv_`.
///
/// - Parameter aBanded: Matrix _A_ in band storage.
/// - Parameter dimension: The order of matrix _A_.
/// - Parameter subdiagonalCount: The number of subdiagonals of _A_.
/// - Parameter superdiagonalCount: The number of superdiagonals of _A_.
/// - Parameter b: The matrix _b_ in _Ax = b_ that contains `dimension * rightHandSideCount`
/// elements.
/// - Parameter rightHandSideCount: The number of columns in _b_.
///
/// The following example illustrates the band storage scheme when `M = N = 6`, `KL = 2`,
/// `KU = 1`:
///
///     On entry:                        On exit:
///
///
///     *     *    *    +    +    +       *    *    *   u14  u25  u36
///     *     *    +    +    +    +       *    *   u13  u24  u35  u46
///     *    a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
///     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
///     a21  a32  a43  a54  a65   *      m21  m32  m43  m54  m65   *
///     a31  a42  a53  a64   *    *      m31  m42  m53  m64   *    *
///
/// The routine doesn’t use array elements with `*` marks. You don’t need to set elements with `+` marks
/// on entry, but the routine requires them to store elements of `U`.
///
/// The function specifies the leading dimension (the increment between successive columns of a matrix)
/// of matrices as their number of rows.

/// - Tag: nonsymmetric_banded
func nonsymmetric_banded(aBanded: [Float],
                         dimension: Int,
                         subdiagonalCount: Int,
                         superdiagonalCount: Int,
                         b: [Float],
                         rightHandSideCount: Int) -> [Float]? {
    
    var info: __LAPACK_int = 0
    
    /// Create a mutable copy of the right hand side matrix _b_ that the function returns as the solution matrix _x_.
    var x = b
    
    /// Create a mutable copy of `aBanded` to pass to the LAPACK routine. The routine
    /// overwrites `ab` with details of the factorization.
    var ab = aBanded
    
    var ipiv = [__LAPACK_int](repeating: 0, count: dimension)
    
    let abLeadingDimension = 2 * subdiagonalCount + superdiagonalCount + 1
    
    /// Call `sgbsv_` to compute the solution.
    withUnsafePointer(to: __LAPACK_int(dimension)) { n in
        withUnsafePointer(to: __LAPACK_int(subdiagonalCount)) { kl in
            withUnsafePointer(to: __LAPACK_int(superdiagonalCount)) { ku in
                withUnsafePointer(to: __LAPACK_int(rightHandSideCount)) { nrhs in
                    withUnsafePointer(to: __LAPACK_int(abLeadingDimension)) { ldab in
                        sgbsv_(n,
                               kl,
                               ku,
                               nrhs,
                               &ab,
                               ldab,
                               &ipiv,
                               &x,
                               n,
                               &info)
                    }
                }
            }
        }
    }
    
    if info != 0 {
        NSLog("nonsymmetric_banded error \(info)")
        return nil
    }
    return x
}
