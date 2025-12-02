/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SVD function.
*/

import Accelerate

extension Matrix {
    
    /// Returns the singular value decomposition (SVD) of matrix _A_.
    ///
    /// The SVD is the factorization of the supplied matrix, _A_, into _U_, _Σ_, and _Vᵀ_:
    ///
    ///     a = u * sigma * vᵀ
    ///
    /// The SVD returns as a tuple that contains `u`, `sigma`, and `vᵀ`.
    public static func svd(a: Matrix,
                           k: Int) -> (u: Matrix,
                                       sigma: Matrix,
                                       vt: Matrix) {
        
        /// The _U_ in _A = U * Σ * Vᵀ_.
        let u = Matrix(rowCount: a.rowCount,
                       columnCount: k)
        
        /// The diagonal values of _Σ_ in _A = U * Σ * Vᵀ_.
        let sigma = Matrix(rowCount: min(a.rowCount, a.columnCount),
                           columnCount: 1)
        
        /// The _Vᵀ_ in _A = U * Σ * Vᵀ_.
        let vt = Matrix(rowCount: k,
                        columnCount: a.columnCount )
        
        var JOBU = Int8("V".utf8.first!)
        var JOBVT = Int8("V".utf8.first!)
        var RANGE = Int8("I".utf8.first!)
        
        var m = __LAPACK_int(a.m)
        var n = __LAPACK_int(a.n)
        var lda = __LAPACK_int(a.m)
        
        var ldu = __LAPACK_int(u.m)
        var ldvt = __LAPACK_int(vt.m)
        
        // The `VL` and `VT` parameters are ignored by `sgesvdx_` when the
        // the range is either `A` or `I`.
        var vl = Float(), vu = Float()
        
        // The `IL` and `IU` parameters specify the first and last indices
        // of the singular values that `sgesvdx_` computes.
        var il = __LAPACK_int(1) // The first index.
        var iu = __LAPACK_int(k) // The last index.
        var ns = __LAPACK_int(0) // On return, the number of singular values.
        
        let iwork = UnsafeMutablePointer<__LAPACK_int>.allocate(capacity: 12 * Int(min(m, n)))
        defer {
            iwork.deallocate()
        }
        
        var info = Int32(0)
        
        // Create a copy of `a` to mitigate that `sgesvdx_` destroys the contents of `a`.
        let aCopy = UnsafeMutableBufferPointer<Float>.allocate(capacity: a.data.count)
        _ = aCopy.initialize(from: a.data)
        defer {
            aCopy.deallocate()
        }
        
        // The workspace query that writes the required size of the workspace
        // to `workspaceDimension`.
        var minusOne = __LAPACK_int(-1)
        var workspaceDimension = Float()
        sgesvdx_(&JOBU,
                 &JOBVT,
                 &RANGE,
                 &m,
                 &n,
                 aCopy.baseAddress,
                 &lda,
                 &vl,
                 &vu,
                 &il,
                 &iu,
                 &ns,
                 sigma.data.baseAddress,
                 u.data.baseAddress,
                 &ldu,
                 vt.data.baseAddress,
                 &ldvt,
                 &workspaceDimension,
                 &minusOne,
                 iwork,
                 &info)
        
        var lwork = __LAPACK_int(workspaceDimension)
         
        let workspace = UnsafeMutablePointer<Float>.allocate(capacity: Int(lwork))
        defer {
            workspace.deallocate()
        }
        
        // Compute `iu - il + 1` singular values.
        sgesvdx_(&JOBU,
                 &JOBVT,
                 &RANGE,
                 &m,
                 &n,
                 aCopy.baseAddress,
                 &lda,
                 &vl,
                 &vu,
                 &il,
                 &iu,
                 &ns,
                 sigma.data.baseAddress,
                 u.data.baseAddress,
                 &ldu,
                 vt.data.baseAddress,
                 &ldvt,
                 workspace,
                 &lwork,
                 iwork,
                 &info)
        
        return(u, sigma, vt)
    }
    
}

