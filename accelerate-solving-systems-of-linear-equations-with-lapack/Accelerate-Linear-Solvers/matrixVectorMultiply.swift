/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Function to return the result of multiplying a matrix by a vector.
*/

import Accelerate

/// Returns the result of `matrix * vector`.
func matrixVectorMultiply(matrix: [Float],
                          dimension: (m: Int, n: Int),
                          vector: [Float]) -> [Float] {
    
    let result = [Float](unsafeUninitializedCapacity: dimension.m) {
        buffer, initializedCount in
        
        cblas_sgemv(CblasColMajor, CblasNoTrans,
                    __LAPACK_int(dimension.m),
                    __LAPACK_int(dimension.n),
                    1, matrix, __LAPACK_int(dimension.m),
                    vector, 1, 0,
                    buffer.baseAddress, 1)
        
        initializedCount = dimension.m
    }
    
    return result
}
