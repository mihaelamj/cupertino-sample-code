/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Function to determine whether a specified matrix is positive definite.
*/


import Accelerate

/// Returns a Boolean value that indicates whether the specified matrix is positive definite and, if the
/// matrix is positive definite, the Cholesky factorization.
func isPositiveDefinite(_ matrix: [Float],
                        dimension: Int) -> (isPositiveDefinite: Bool,
                                            factorization: [Float]) {
    
    var info = __LAPACK_int(0)
    var a = matrix
    
    /// Call `spotrf_` to compute the Cholesky factorization of the specified matrix.
    withUnsafePointer(to: Int8("U".utf8.first!)) { uplo in
        withUnsafePointer(to: __LAPACK_int(dimension)) { n in
            spotrf_(uplo,
                    n,
                    &a,
                    n,
                    &info)
        }
    }
    
    /// If `info` is greater than 0, the specified matrix isn't positive definite.
    return (isPositiveDefinite: info <= 0,
            factorization: a)
}
