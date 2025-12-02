/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Solver function for nonsymmetric nonsquare matrices.
*/


import Accelerate

/// Returns the _x_ in _Ax = b_ for a nonsquare coefficient matrix using `sgels_`.
///
/// - Parameter a: The matrix _A_ in _Ax = b_ that contains `dimension.m * dimension.n`
/// elements.
/// - Parameter dimension: The number of rows and columns of matrix _A_.
/// - Parameter b: The matrix _b_ in _Ax = b_ that contains `dimension * rightHandSideCount`
/// elements.
/// - Parameter rightHandSideCount: The number of columns in _b_.
///
/// If the system is overdeterrmined (that is, there are more rows than columns in the coefficient matrix), the
/// sum of squares of the returned elements in rows `n ..< m`is the residual sum of squares
/// for the solution.
///
/// The function specifies the leading dimension (the increment between successive columns of a matrix)
/// of matrices as their number of rows.

/// - Tag: nonsymmetric_nonsquare
func nonsymmetric_nonsquare(a: [Float],
                            dimension: (m: Int,
                                        n: Int),
                            b: [Float],
                            rightHandSideCount: Int) -> [Float]? {
    
    let leadingDimensionB = max(dimension.m, dimension.n)
    
    /// Call `slacpy_` to copy the values of `m * nrhs` matrix `b` into the `ldb * nrhs`
    /// result matrix `x`.
    let xCount = Int(leadingDimensionB * rightHandSideCount)
    var x = [Float](unsafeUninitializedCapacity: xCount) {
        buffer, initializedCount in
        
        var mutableB = b
        
        withUnsafePointer(to: Int8("A".utf8.first!)) { uplo in
            withUnsafePointer(to: __LAPACK_int(dimension.m)) { m in
                withUnsafePointer(to: __LAPACK_int(rightHandSideCount)) { nrhs in
                    withUnsafePointer(to: __LAPACK_int(leadingDimensionB)) { ldb in
                        slacpy_(uplo,
                                m,
                                nrhs,
                                &mutableB,
                                m,
                                buffer.baseAddress,
                                ldb)
                    }
                }
            }
        }
        
        initializedCount = xCount
    }
    
    /// Create a mutable copy of `a` to pass to the LAPACK routine. The routine overwrites `mutableA`
    /// with details of its QR or LQ factorization.
    var mutableA = a
    
    /// Pass `lwork = -1` to `sgels_` to perform a workspace query that calculates the optimal
    /// size of the `work` array.
    var work = Float(0)
    sgels(trans: Int8("N".utf8.first!),
          m: __LAPACK_int(dimension.m),
          n: __LAPACK_int(dimension.n),
          nrhs: __LAPACK_int(rightHandSideCount),
          a: &mutableA,
          lda: __LAPACK_int(dimension.m),
          b: &x,
          ldb: __LAPACK_int(leadingDimensionB),
          work: &work,
          lwork: -1)
    
    let workspace = UnsafeMutablePointer<Float>.allocate(capacity: Int(work))
    defer {
        workspace.deallocate()
    }
    
    /// Call `sgels_` to compute the solution.
    let info = sgels(trans: Int8("N".utf8.first!),
                     m: __LAPACK_int(dimension.m),
                     n: __LAPACK_int(dimension.n),
                     nrhs: __LAPACK_int(rightHandSideCount),
                     a: &mutableA,
                     lda: __LAPACK_int(dimension.m),
                     b: &x,
                     ldb: __LAPACK_int(leadingDimensionB),
                     work: workspace,
                     lwork: __LAPACK_int(work))
    
    if info != 0 {
        NSLog("nonsymmetric_nonsquare error \(info)")
        return nil
    }
    
    return x
}

/// A wrapper around `sgels_` that accepts values rather than pointers to values.
@discardableResult
func sgels(trans: CChar,
           m: __LAPACK_int,
           n: __LAPACK_int,
           nrhs: __LAPACK_int,
           a: UnsafeMutablePointer<Float>,
           lda: __LAPACK_int,
           b: UnsafeMutablePointer<Float>,
           ldb: __LAPACK_int,
           work: UnsafeMutablePointer<Float>,
           lwork: __LAPACK_int) -> __LAPACK_int {
    
    var info: __LAPACK_int = 0
    
    withUnsafePointer(to: trans) { trans in
        withUnsafePointer(to: m) { m in
            withUnsafePointer(to: n) { n in
                withUnsafePointer(to: nrhs) { nrhs in
                    withUnsafePointer(to: lda) { lda in
                        withUnsafePointer(to: ldb) { ldb in
                            withUnsafePointer(to: lwork) { lwork in
                                sgels_(trans,
                                       m,
                                       n,
                                       nrhs,
                                       a,
                                       lda,
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
    }
    
    return info
}
