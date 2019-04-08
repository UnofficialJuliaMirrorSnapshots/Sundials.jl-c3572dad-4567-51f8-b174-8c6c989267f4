abstract type AbstactFunJac{J2} end
mutable struct FunJac{F, F2, J, P, M, J2, uType, uType2} <: AbstactFunJac{J2}
    fun::F
    fun2::F2
    jac::J
    p::P
    mass_matrix::M
    jac_prototype::J2
    u::uType
    du::uType
    resid::uType2
end
FunJac(fun,jac,p,m,jac_prototype,u,du) = FunJac(fun,nothing,jac,p,m,jac_prototype,u,du,nothing)
FunJac(fun,jac,p,m,jac_prototype,u,du,resid) = FunJac(fun,nothing,jac,p,m,jac_prototype,u,du,resid)

function cvodefunjac(t::Float64,
                     u::N_Vector,
                     du::N_Vector,
                     funjac::FunJac)
    if !(pointer(funjac.u) === __N_VGetArrayPointer_Serial(u))
      #@warn "Pointer is broken to FunJac.u"
      funjac.u = convert(Vector, u)
    end
    _u = funjac.u

    if !(pointer(funjac.du) === __N_VGetArrayPointer_Serial(du))
      #@warn "Pointer is broken to FunJac.du"
      funjac.du = convert(Vector, du)
    end
    _du = funjac.du

    funjac.fun(_du, _u, funjac.p, t)
    return CV_SUCCESS
end

function cvodefunjac2(t::Float64,
                     u::N_Vector,
                     du::N_Vector,
                     funjac::FunJac)
    if !(pointer(funjac.u) === __N_VGetArrayPointer_Serial(u))
      #@warn "Pointer is broken to FunJac.u"
      funjac.u = convert(Vector, u)
    end
    _u = funjac.u

    if !(pointer(funjac.du) === __N_VGetArrayPointer_Serial(du))
      #@warn "Pointer is broken to FunJac.du"
      funjac.du = convert(Vector, du)
    end
    _du = funjac.du

    funjac.fun2(_du, _u, funjac.p, t)
    return CV_SUCCESS
end

function cvodejac(t::realtype,
                  u::N_Vector,
                  du::N_Vector,
                  J::SUNMatrix,
                  funjac::AbstactFunJac{Nothing},
                  tmp1::N_Vector,
                  tmp2::N_Vector,
                  tmp3::N_Vector)

    if !(pointer(funjac.u) === __N_VGetArrayPointer_Serial(u))
      #@warn "Pointer is broken to FunJac.u"
      funjac.u = convert(Vector, u)
    end
    _u = funjac.u

    #=
    if !(pointer(funjac.du) === __N_VGetArrayPointer_Serial(du))
      #@warn "Pointer is broken to FunJac.du"
      _du = convert(Vector, du)
    end
    =#

    funjac.jac(convert(Matrix, J), _u, funjac.p, t)
    return CV_SUCCESS
end

function cvodejac(t::realtype,
                  u::N_Vector,
                  du::N_Vector,
                  _J::SUNMatrix,
                  funjac::AbstactFunJac{<:SparseMatrixCSC},
                  tmp1::N_Vector,
                  tmp2::N_Vector,
                  tmp3::N_Vector)
    jac_prototype = funjac.jac_prototype
    J = convert(SparseMatrixCSC,_J)

    if !(pointer(funjac.u) === __N_VGetArrayPointer_Serial(u))
      #@warn "Pointer is broken to FunJac.u"
      funjac.u = convert(Vector, u)
    end
    _u = funjac.u

    funjac.jac(jac_prototype, _u, funjac.p, t)
    J.nzval .= jac_prototype.nzval
    # Sundials resets the value pointers each time, so reset it too
    @. J.rowval = jac_prototype.rowval - 1
    @. J.colptr = jac_prototype.colptr - 1
    return CV_SUCCESS
end

function idasolfun(t::Float64, u::N_Vector, du::N_Vector, resid::N_Vector, funjac::FunJac)
    if !(pointer(funjac.u) === __N_VGetArrayPointer_Serial(u))
      #@warn "Pointer is broken to FunJac.u"
      _u = convert(Vector, u)
    else
      _u = funjac.u
    end

    if !(pointer(funjac.du) === __N_VGetArrayPointer_Serial(du))
      #@warn "Pointer is broken to FunJac.du"
      _du = convert(Vector, du)
    else
      _du = funjac.du
    end

    funjac.fun(funjac.resid, _du, _u, funjac.p, t)

    unsafe_copyto!(Sundials.__N_VGetArrayPointer_Serial(resid),
                   pointer(funjac.resid),
                   length(funjac.resid))

    return IDA_SUCCESS
end

function idajac(t::realtype,
                cj::realtype,
                u::N_Vector,
                du::N_Vector,
                res::N_Vector,
                J::SUNMatrix,
                funjac::AbstactFunJac{Nothing},
                tmp1::N_Vector,
                tmp2::N_Vector,
                tmp3::N_Vector)


    if !(pointer(funjac.u) === __N_VGetArrayPointer_Serial(u))
      #@warn "Pointer is broken to FunJac.u"
      _u = convert(Vector, u)
    else
      _u = funjac.u
    end

    if !(pointer(funjac.du) === __N_VGetArrayPointer_Serial(du))
      #@warn "Pointer is broken to FunJac.du"
      _du = convert(Vector, du)
    else
      _du = funjac.du
    end

    funjac.jac(convert(Matrix, J), _du,
               _u, funjac.p, cj, t)
    return IDA_SUCCESS
end

function idajac(t::realtype,
                cj::realtype,
                u::N_Vector,
                du::N_Vector,
                res::N_Vector,
                _J::SUNMatrix,
                funjac::AbstactFunJac{<:SparseMatrixCSC},
                tmp1::N_Vector,
                tmp2::N_Vector,
                tmp3::N_Vector)

  jac_prototype = funjac.jac_prototype
  J = convert(SparseMatrixCSC,_J)

  if !(pointer(funjac.u) === __N_VGetArrayPointer_Serial(u))
    #@warn "Pointer is broken to FunJac.u"
    _u = convert(Vector, u)
  else
    _u = funjac.u
  end

  if !(pointer(funjac.du) === __N_VGetArrayPointer_Serial(du))
    #@warn "Pointer is broken to FunJac.du"
    _du = convert(Vector, du)
  else
    _du = funjac.du
  end

  funjac.jac(jac_prototype, _du, convert(Vector, _u), funjac.p, cj, t)
  J.nzval .= jac_prototype.nzval
  # Sundials resets the value pointers each time, so reset it too
  @. J.rowval = jac_prototype.rowval - 1
  @. J.colptr = jac_prototype.colptr - 1

  return IDA_SUCCESS
end

function massmat(t::Float64,
                 _M::SUNMatrix,
                 mmf::AbstactFunJac,
                 tmp1::N_Vector,
                 tmp2::N_Vector,
                 tmp3::N_Vector)
  if typeof(mmf.mass_matrix) <: Array
    M = convert(Matrix, _M)
  else
    M = convert(SparseMatrixCSC, _M)
  end
  M .= mmf.mass_matrix

  return IDA_SUCCESS
end
