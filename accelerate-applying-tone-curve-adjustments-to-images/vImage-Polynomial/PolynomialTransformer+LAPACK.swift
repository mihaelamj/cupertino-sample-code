/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The polynomial transformer LAPACK extension.
*/


import Accelerate

// LAPACK Linear Solver wrapper.
extension PolynomialTransformer {
    
    /// Overwrites the parameter `b` with the _x_ in _Ax = b_.
    static func solveLinearSystem(matrixA: inout [Float],
                                  matrixB: inout [Float],
                                  count: Int) throws {
        
        /// By default, LAPACK expects matrices in column-major format. Specify transpose to support
        /// the row-major Vandermonde matrix.
        let trans = Int8("T".utf8.first!)
        
        /// Pass `-1` to the `lwork` parameter of `sgels_` to calculate the optimal size for the
        /// workspace array. The function writes the optimal size to the `workDimension` variable.
        var workspaceCount = Float(0)
        let err = sgels(transpose: trans,
                        rowCount: count,
                        columnCount: count,
                        rightHandSideCount: 1,
                        matrixA: &matrixA, leadingDimensionA: count,
                        matrixB: &matrixB, leadingDimensionB: count,
                        workspace: &workspaceCount,
                        workspaceCount: -1)
        
        if err != 0 {
            throw LAPACKError.internalError
        }
        
        ///  Create the workspace array based on the workspace query result.
        let workspace = UnsafeMutablePointer<Float>.allocate(
            capacity: Int(workspaceCount))
        defer {
            workspace.deallocate()
        }
        
        /// Perform the solve by passing the workspace array size to the `lwork` parameter of `sgels_`.
        let info = sgels(transpose: trans,
                         rowCount: count,
                         columnCount: count,
                         rightHandSideCount: 1,
                         matrixA: &matrixA, leadingDimensionA: count,
                         matrixB: &matrixB, leadingDimensionB: count,
                         workspace: workspace,
                         workspaceCount: Int(workspaceCount))
        
        if info < 0 {
            throw LAPACKError.parameterHasIllegalValue(parameterIndex: abs(Int(info)))
        } else if info > 0 {
            throw LAPACKError.diagonalElementOfTriangularFactorIsZero(index: Int(info))
        }
    }
    
    public enum LAPACKError: Swift.Error {
        case internalError
        case parameterHasIllegalValue(parameterIndex: Int)
        case diagonalElementOfTriangularFactorIsZero(index: Int)
    }
    
    /// A wrapper around `sgels_` that accepts values rather than pointers to values.
    static func sgels(transpose trans: CChar,
                      rowCount m: Int,
                      columnCount n: Int,
                      rightHandSideCount nrhs: Int,
                      matrixA a: UnsafeMutablePointer<Float>,
                      leadingDimensionA lda: Int,
                      matrixB b: UnsafeMutablePointer<Float>,
                      leadingDimensionB ldb: Int,
                      workspace work: UnsafeMutablePointer<Float>,
                      workspaceCount lwork: Int) -> Int32 {
        
        var info = Int32(0)
        
        withUnsafePointer(to: trans) { trans in
            withUnsafePointer(to: __LAPACK_int(m)) { m in
                withUnsafePointer(to: __LAPACK_int(n)) { n in
                    withUnsafePointer(to: __LAPACK_int(nrhs)) { nrhs in
                        withUnsafePointer(to: __LAPACK_int(lda)) { lda in
                            withUnsafePointer(to: __LAPACK_int(ldb)) { ldb in
                                withUnsafePointer(to: __LAPACK_int(lwork)) { lwork in
                                    sgels_(trans, m, n,
                                           nrhs,
                                           a, lda,
                                           b, ldb,
                                           work, lwork,
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
}
