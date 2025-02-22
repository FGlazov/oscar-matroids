mutable struct PrimaryInvarsCache{T}
  invars::Vector{T}
  ideal::MPolyIdeal{T}

  function PrimaryInvarsCache{T}() where {T <: MPolyElem}
    z = new{T}()
    z.invars = T[]
    return z
  end
end

mutable struct InvRing{FldT, GrpT, PolyElemT, PolyRingT, ActionT, SingularActionT}
  field::FldT
  poly_ring::PolyRingT

  group::GrpT
  action::Vector{ActionT}
  action_singular::Vector{SingularActionT}

  modular::Bool

  primary::PrimaryInvarsCache{PolyElemT}
  secondary::Vector{PolyElemT}
  irreducible_secondary::Vector{PolyElemT}
  fundamental::Vector{PolyElemT}

  reynolds_operator::MapFromFunc{PolyRingT, PolyRingT}

  molien_series::Generic.Frac{fmpq_poly}

  # Cache some stuff on the Singular side
  # (possibly removed at some point)
  reynolds_singular::Singular.smatrix
  molien_singular::Singular.smatrix

  function InvRing(K::FldT, G::GrpT, action::Vector{ActionT}) where {FldT <: Field, GrpT <: AbstractAlgebra.Group, ActionT}
    n = degree(G)
    R, = grade(PolynomialRing(K, "x" => 1:n, cached = false)[1], ones(Int, n))
    R_sing = singular_ring(R)
    action_singular = identity.([change_base_ring(R_sing, g) for g in action])
    PolyRingT = typeof(R)
    PolyElemT = elem_type(R)
    SingularActionT = eltype(action_singular)
    z = new{FldT, GrpT, PolyElemT, PolyRingT, ActionT, SingularActionT}()
    z.field = K
    z.poly_ring = R
    z.group = G
    z.action = action
    z.action_singular = action_singular
    z.modular = true
    if iszero(characteristic(K))
      z.modular = false
    else
      if !iszero(mod(order(G), characteristic(K)))
        z.modular = false
      end
    end
    return z
  end
end

struct AllMonomials{PolyRingT}
  R::PolyRingT
  d::Int

  function AllMonomials{PolyRingT}(R::PolyRingT, d::Int) where PolyRingT
    @assert d >= 0
    return new{PolyRingT}(R, d)
  end
end

struct InvRingBasisIterator{InvRingT, IteratorT, PolyElemT, MatrixT}
  R::InvRingT
  degree::Int
  dim::Int
  reynolds::Bool

  monomials::IteratorT
  monomials_collected::Vector{PolyElemT}
  kernel::MatrixT # used iff reynolds == false
end

abstract type VectorSpaceIterator{FieldT, IteratorT, ElemT} end

# This takes a basis of a vector space as an iterator and then "iterates" the
# space in three "phases":
# 1) iterate the basis using basis_iterator, so return one basis element at
#    a time
# 2) iterate all possible sums of basis elements
# 3) return random linear combinations of the basis elements (with integer
#    coefficients bounded by rand_bound)
#
# We collect the basis while iterating it, so that multiple iteration over the
# same VectorSpaceIterator do not need to recompute it. basis_iterator_state
# must always be a state of basis_iterator, so that
# iterate(basis_iterator, basis_iterator_state) returns the next element in the
# basis coming after basis_collected[end].
mutable struct VectorSpaceIteratorRand{FieldT, IteratorT, ElemT} <: VectorSpaceIterator{FieldT, IteratorT, ElemT}
  field::FieldT
  basis_iterator::IteratorT
  basis_collected::Vector{ElemT}
  basis_iterator_state::Any # I don't know the type of this and I don't think there
                       # is a "type-stable" way of finding it out
  rand_bound::Int

  function VectorSpaceIteratorRand(K::FieldT, basis_iterator::IteratorT, bound::Int = 10^5) where {FieldT, IteratorT}
    VSI = new{FieldT, IteratorT, eltype(basis_iterator)}()
    VSI.field = K
    VSI.basis_iterator = basis_iterator
    VSI.basis_collected = eltype(basis_iterator)[]
    VSI.rand_bound = bound
    return VSI
  end
end

# The same things as for VectorSpaceIteratorRand apply besides that in "phase 3"
# all elements of the vector space are iterated in deterministic order (it is
# supposed to be finite after all).
mutable struct VectorSpaceIteratorFiniteField{FieldT, IteratorT, ElemT} <: VectorSpaceIterator{FieldT, IteratorT, ElemT}
  field::FieldT
  basis_iterator::IteratorT
  basis_collected::Vector{ElemT}
  basis_iterator_state::Any # I don't know the type of this and I don't think there
                       # is a "type-stable" way of finding it out

  function VectorSpaceIteratorFiniteField(K::FieldT, basis_iterator::IteratorT) where {FieldT <: Union{Nemo.GaloisField, Nemo.GaloisFmpzField, FqNmodFiniteField, FqFiniteField}, IteratorT}
    VSI = new{FieldT, IteratorT, eltype(basis_iterator)}()
    VSI.field = K
    VSI.basis_iterator = basis_iterator
    VSI.basis_collected = eltype(basis_iterator)[]
    return VSI
  end
end

struct MSetPartitions{T}
  M::MSet{T}
  num_to_key::Vector{Int}
  key_to_num::Dict{T, Int}

  function MSetPartitions(M::MSet{T}) where T
    num_to_key = collect(keys(M.dict))
    key_to_num = Dict{T, Int}()
    for i = 1:length(num_to_key)
      key_to_num[num_to_key[i]] = i
    end
    return new{T}(M, num_to_key, key_to_num)
  end
end

mutable struct MSetPartitionsState
  f::Vector{Int}
  c::Vector{Int}
  u::Vector{Int}
  v::Vector{Int}
  a::Int
  b::Int
  l::Int

  function MSetPartitionsState(MSP::MSetPartitions)
    m = length(MSP.num_to_key)
    n = length(MSP.M)
    f = zeros(Int, n + 1)
    c = zeros(Int, n*m + 1)
    u = zeros(Int, n*m + 1)
    v = zeros(Int, n*m + 1)

    for j = 1:m
      c[j] = j
      u[j] = MSP.M.dict[MSP.num_to_key[j]]
      v[j] = MSP.M.dict[MSP.num_to_key[j]]
    end
    f[1] = 1
    f[2] = m + 1
    a = 1
    b = m + 1
    l = 1

    return new(f, c, u, v, a, b, l)
  end
end

# Handle vector spaces of multivariate polynomials by writing them in the basis
# of the monomials.
mutable struct BasisOfPolynomials{PolyElemT, PolyRingT, FieldElemT}
  R::PolyRingT

  # Number the basis monomials
  monomial_to_column::Dict{PolyElemT, Int}

  # Write the polynomials coefficient-wise in the rows of a sparse matrix. The
  # column i contains the coefficients corresponding to the monomial m with
  # monomial_to_column[m] == i.
  M::SMat{FieldElemT}

  function BasisOfPolynomials(R::MPolyRing)
    K = coefficient_ring(R)
    B = new{elem_type(R), typeof(R), elem_type(K)}()
    B.R = R
    B.monomial_to_column = Dict{elem_type(R), Int}()
    B.M = sparse_matrix(K)
    return B
  end

  function BasisOfPolynomials(R::PolyRingT, polys::Vector{PolyElemT}) where {PolyRingT <: MPolyRing, PolyElemT <: MPolyElem}
    if isempty(polys)
      return BasisOfPolynomials(R)
    end

    K = coefficient_ring(R)
    B = new{elem_type(R), typeof(R), elem_type(K)}()
    B.R = R

    monomial_to_column = Dict{elem_type(R), Int}()
    c = 0
    for f in polys
      for m in monomials(f)
        if !haskey(monomial_to_column, m)
          c += 1
          monomial_to_column[m] = c
        end
      end
    end
    B.monomial_to_column = monomial_to_column

    M = sparse_matrix(K)
    for i = 1:length(polys)
      srow = sparse_row(K)
      for (a, m) in zip(coefficients(polys[i]), monomials(polys[i]))
        col = monomial_to_column[m]
        k = searchsortedfirst(srow.pos, col)
        insert!(srow.pos, k, col)
        insert!(srow.values, k, deepcopy(a))
      end
      Hecke.push_row!(M, srow)
    end
    rref!(M, truncate = true)
    B.M = M

    return B
  end
end

# Cache power products (= monomials) of elements in `base` of certain degrees.
mutable struct PowerProductCache{RingType, T}
  # The base ring (needed for empty `base`)
  ring::RingType

  base::Vector{T}

  # Store all power products of degree d
  power_products::Dict{Int, Vector{T}}

  # The exponent vector of a power product w.r.t. `base`
  exponent_vectors::Dict{T, Vector{Int}}

  # Whether the exponent vectors for a certain degree were computed
  exponent_vectors_known::Dict{Int, Bool}

  # The last entry of `base` involved in the power product
  last_factor::Dict{T, Int}

  function PowerProductCache(R::S, base::Vector{T}) where {S <: Ring, T <: RingElem}
    power_products = Dict{Int, Vector{T}}()
    exponent_vectors = Dict{T, Vector{Int}}()
    exponent_vectors_known = Dict{Int, Bool}()
    last_factor = Dict{T, Int}()
    return new{typeof(R), T}(R, copy(base), power_products, exponent_vectors, exponent_vectors_known, last_factor)
  end
end
