/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Solver function for symmetric indefinite tridiagonal matrices.
*/


import Accelerate

/// Returns the _x_ in _Ax = b_ for a nonsquare coefficient matrix using `ssysv_`.
///
/// - Parameter a: The matrix _A_ in _Ax = b_ that contains `dimension * dimension`
/// elements. The function references the upper triangle of _A_.
/// - Parameter dimension: The order of matrix _A_.
/// - Parameter b: The matrix _b_ in _Ax = b_ that contains `dimension * rightHandSideCount`
/// elements.
/// - Parameter rightHandSideCount: The number of columns in _b_.
///
/// The function specifies the leading dimension (the increment between successive columns of a matrix)
/// of matrices as their number of rows.

/// - Tag: symmetric_indefinite_general
func symmetric_indefinite_general(a: [Float],
                                  dimension: Int,
                                  b: [Float],
                                  rightHandSideCount: Int) -> [Float]? {
    
    /// Create a mutable copy of the right hand side matrix _b_ that the function returns as the solution matrix _x_.
    var x = b
    
    /// Create a mutable copy of `a` to pass to the LAPACK routine. The routine overwrites `mutableA`
    /// with the block diagonal matrix `D` and the multipliers that obtain the factor `U`.
    var mutableA = a
    
    var ipiv = [__LAPACK_int](repeating: 0, count: dimension)
    
    /// Pass `lwork = -1` to `ssysv_` to perform a workspace query that calculates the
    /// optimal size of the `work` array.
    var work = Float(0)
    ssysv(uplo: Int8("U".utf8.first!),
          n: __LAPACK_int(dimension),
          nrhs: __LAPACK_int(rightHandSideCount),
          a: &mutableA,
          lda: __LAPACK_int(dimension),
          ipiv: &ipiv,
          b: &x,
          ldb: __LAPACK_int(dimension),
          work: &work,
          lwork: -1)
    
    let workspace = UnsafeMutablePointer<Float>.allocate(capacity: Int(work))
    defer {
        workspace.deallocate()
    }
    
    /// Call `ssysv_` to compute the solution.
    let info = ssysv(uplo: Int8("U".utf8.first!),
                     n: __LAPACK_int(dimension),
                     nrhs: __LAPACK_int(rightHandSideCount),
                     a: &mutableA,
                     lda: __LAPACK_int(dimension),
                     ipiv: &ipiv,
                     b: &x,
                     ldb: __LAPACK_int(dimension),
                     work: workspace,
                     lwork: __LAPACK_int(work))
    
    if info != 0 {
        NSLog("symmetric_indefinite_general error \(info)")
        return nil
    }
    return x
}

/// A wrapper around `ssysv_` that accepts values rather than pointers to values.
@discardableResult
func ssysv(uplo: CChar,
           n: __LAPACK_int,
           nrhs: __LAPACK_int,
           a: UnsafeMutablePointer<Float>,
           lda: __LAPACK_int,
           ipiv: UnsafeMutablePointer<__LAPACK_int>,
           b: UnsafeMutablePointer<Float>,
           ldb: __LAPACK_int,
           work: UnsafeMutablePointer<Float>,
           lwork: __LAPACK_int) -> __LAPACK_int {
    
    var info: __LAPACK_int = 0
    
    withUnsafePointer(to: uplo) { uplo in
        withUnsafePointer(to: n) { n in
            withUnsafePointer(to: nrhs) { nrhs in
                withUnsafePointer(to: lda) { lda in
                    withUnsafePointer(to: ldb) { ldb in
                        withUnsafePointer(to: lwork) { lwork in
                            ssysv_(uplo,
                                   n,
                                   nrhs,
                                   a,
                                   lda,
                                   ipiv,
                                   b,
                                   ldb,
                                   work,
                                   lwork,
                                   &info)
                        }
                    }
                }
            }
        }
    }
    
    return info
}
