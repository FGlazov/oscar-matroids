export
    centralizer,
    center, hascenter, setcenter,
    characteristic_subgroups, hascharacteristic_subgroups, setcharacteristic_subgroups,
    derived_series, hasderived_series, setderived_series,
    derived_subgroup, hasderived_subgroup, setderived_subgroup,
    embedding,
    index,
    ischaracteristic,
    isnilpotent, hasisnilpotent, setisnilpotent,
    issolvable, hasissolvable, setissolvable,
    issupersolvable, hasissupersolvable, setissupersolvable,
    maximal_abelian_quotient, hasmaximal_abelian_quotient, setmaximal_abelian_quotient,
    maximal_normal_subgroups, hasmaximal_normal_subgroups, setmaximal_normal_subgroups,
    maximal_subgroups, hasmaximal_subgroups, setmaximal_subgroups,
    minimal_normal_subgroups, hasminimal_normal_subgroups, setminimal_normal_subgroups,
    normal_subgroups, hasnormal_subgroups, setnormal_subgroups,
    quo,
    sub,
    trivial_subgroup, hastrivial_subgroup, settrivial_subgroup

################################################################################
#
#  Subgroup function
#
################################################################################

function _as_subgroup_bare(G::T, H::GapObj) where T <: GAPGroup
  return _oscar_group(H, G)
end

function _as_subgroup(G::GAPGroup, H::GapObj)
  H1 = _as_subgroup_bare(G, H)
  return H1, hom(H1, G, x -> group_element(G, x.X))
end

"""
    sub(G::GAPGroup, gens::AbstractVector{<:GAPGroupElem})
    sub(gens::GAPGroupElem...)

This function returns two objects: a group `H`, that is the subgroup of `G`
generated by the elements `x,y,...`, and the embedding homomorphism of `H`
into `G`. The object `H` has the same type of `G`, and it has no memory of the
"parent" group `G`: it is an independent group.

# Examples
```jldoctest
julia> G = symmetric_group(4); H, _ = sub(G,[cperm([1,2,3]),cperm([2,3,4])]);

julia> H == alternating_group(4)
true
```
"""
function sub(G::GAPGroup, gens::AbstractVector{S}) where S <: GAPGroupElem
  @assert elem_type(G) == S
  elems_in_GAP = GapObj([x.X for x in gens])
  H = GAP.Globals.Subgroup(G.X,elems_in_GAP)
  return _as_subgroup(G, H)
end

function sub(gens::GAPGroupElem...)
   length(gens) > 0 || throw(ArgumentError("Empty list"))
   l = collect(gens)
   @assert all(x -> parent(x) == parent(l[1]), l)
   return sub(parent(l[1]),l)
end

"""
    issubgroup(G::T, H::T) where T <: GAPGroup

Return (`true`,`f`) if `H` is a subgroup of `G`, where `f` is the embedding
homomorphism of `H` into `G`, otherwise return (`false`,`nothing`).
"""
function issubgroup(G::T, H::T) where T <: GAPGroup
   if !all(h -> h in G, gens(H))
      return (false, nothing)
   else
      return (true, _as_subgroup(G, H.X)[2])
   end
end

"""
    embedding(G::T, H::T) where T <: GAPGroup

Return the embedding morphism of `H` into `G`.
An exception is thrown if `H` is not a subgroup of `G`.
"""
function embedding(G::T, H::T) where T <: GAPGroup
   a,f = issubgroup(G,H)
   if !a
      throw(ArgumentError("H is not a subgroup of G"))
   else
      return f
   end
end

@gapattribute trivial_subgroup(G::GAPGroup) =_as_subgroup(G, GAP.Globals.TrivialSubgroup(G.X))
@doc """
    trivial_subgroup(G::GAPGroup)

Return the trivial subgroup of `G`,
together with its embedding morphism into `G`.
""" trivial_subgroup


###############################################################################
#
#  Index
#
###############################################################################

"""
    index(::Type{I} = fmpz, G::T, H::T) where I <: IntegerUnion where T <: GAPGroup

Return the index of `H` in `G`, as an instance of `I`.
"""
index(G::T, H::T) where T <: GAPGroup = index(fmpz, G, H)

function index(::Type{I}, G::T, H::T) where I <: IntegerUnion where T <: GAPGroup
   i = GAP.Globals.Index(G.X, H.X)
   if i === GAP.Globals.infinity
      error("index() not supported for subgroup of infinite index, use isfinite()")
   end
   return I(i)
end

###############################################################################
#
#  subgroups computation
#
###############################################################################

# convert a GAP list of subgroups into a vector of Julia groups objects
function _as_subgroups(G::T, subs::GapObj) where T <: GAPGroup
  res = Vector{T}(undef, length(subs))
  for i = 1:length(res)
    res[i] = _as_subgroup_bare(G, subs[i])
  end
  return res
end


"""
    normal_subgroups(G::Group)

Return the vector of normal subgroups of `G` (see [`isnormal`](@ref)).
"""
@gapattribute normal_subgroups(G::GAPGroup) =
  _as_subgroups(G, GAP.Globals.NormalSubgroups(G.X))

"""
    subgroups(G::Group)

Return the vector of all subgroups of `G`.
"""
function subgroups(G::GAPGroup)
  return _as_subgroups(G, GAP.Globals.AllSubgroups(G.X))
end

"""
    maximal_subgroups(G::Group)

Return the vector of maximal subgroups of `G`.
"""
@gapattribute maximal_subgroups(G::GAPGroup) =
  _as_subgroups(G, GAP.Globals.MaximalSubgroups(G.X))

"""
    maximal_normal_subgroups(G::Group)

Return the vector of maximal normal subgroups of `G`,
i. e., of those proper normal subgroups of `G` that are maximal
among the proper normal subgroups.
"""
@gapattribute maximal_normal_subgroups(G::GAPGroup) =
  _as_subgroups(G, GAP.Globals.MaximalNormalSubgroups(G.X))

"""
    minimal_normal_subgroups(G::Group)

Return the vector of minimal normal subgroups of `G`,
i. e., of those nontrivial normal subgroups of `G` that are minimal
among the nontrivial normal subgroups.
"""
@gapattribute minimal_normal_subgroups(G::GAPGroup) =
  _as_subgroups(G, GAP.Globals.MinimalNormalSubgroups(G.X))

"""
    characteristic_subgroups(G::Group)

Return the list of characteristic subgroups of `G`,
i.e., those subgroups that are invariant under all automorphisms of `G`.
"""
@gapattribute characteristic_subgroups(G::GAPGroup) =
  _as_subgroups(G, GAP.Globals.CharacteristicSubgroups(G.X))

@doc Markdown.doc"""
    center(G::Group)

Return the center of `G`, i.e.,
the subgroup of all $x$ in `G` such that $x y$ equals $y x$ for every $y$
in `G`, together with its embedding morphism into `G`.
"""
@gapattribute center(G::GAPGroup) = _as_subgroup(G, GAP.Globals.Centre(G.X))

@doc Markdown.doc"""
    centralizer(G::Group, H::Group)

Return the centralizer of `H` in `G`, i.e.,
the subgroup of all $g$ in `G` such that $g h$ equals $h g$ for every $h$
in `H`, together with its embedding morphism into `G`.
"""
function centralizer(G::T, H::T) where T <: GAPGroup
  return _as_subgroup(G, GAP.Globals.Centralizer(G.X, H.X))
end

@doc Markdown.doc"""
    centralizer(G::Group, x::GroupElem) 

Return the centralizer of `x` in `G`, i.e.,
the subgroup of all $g$ in `G` such that $g$ `x` equals `x` $g$,
together with its embedding morphism into `G`.
"""
function centralizer(G::GAPGroup, x::GAPGroupElem)
  return _as_subgroup(G, GAP.Globals.Centralizer(G.X, x.X))
end

const centraliser = centralizer

################################################################################
#
#  IsNormal, IsCharacteristic, IsSolvable, IsNilpotent
#
################################################################################

"""
    isnormal(G::T, H::T) where T <: GAPGroup

Return whether the subgroup `H` is normal in `G`,
i. e., `H` is invariant under conjugation with elements of `G`.
"""
isnormal(G::T, H::T) where T <: GAPGroup = GAPWrap.IsNormal(G.X, H.X)

"""
    ischaracteristic(G::T, H::T) where T <: GAPGroup

Return whether the subgroup `H` is characteristic in `G`,
i. e., `H` is invariant under all automorphisms of `G`.
"""
function ischaracteristic(G::T, H::T) where T <: GAPGroup
  return GAPWrap.IsCharacteristicSubgroup(G.X, H.X)
end

"""
    issolvable(G::GAPGroup)

Return whether `G` is solvable,
i. e., whether [`derived_series`](@ref)(`G`)
reaches the trivial subgroup in a finite number of steps.
"""
@gapattribute issolvable(G::GAPGroup) = GAP.Globals.IsSolvableGroup(G.X)::Bool

"""
    isnilpotent(G::GAPGroup)

Return whether `G` is nilpotent,
i. e., whether the lower central series of `G` reaches the trivial subgroup
in a finite number of steps.
"""
@gapattribute isnilpotent(G::GAPGroup) = GAP.Globals.IsNilpotentGroup(G.X)::Bool

"""
    issupersolvable(G::GAPGroup)

Return whether `G` is supersolvable,
i. e., `G` is finite and has a normal series with cyclic factors.
"""
@gapattribute issupersolvable(G::GAPGroup) = GAP.Globals.IsSupersolvableGroup(G.X)::Bool

################################################################################
#
#  Quotient functions
#
################################################################################

function quo(G::FPGroup, elements::Vector{S}) where T <: GAPGroup where S <: GAPGroupElem
  @assert elem_type(G) == S
  elems_in_gap = GapObj([x.X for x in elements])
#T better!
  Q=FPGroup((G.X)/elems_in_gap)
  function proj(x::FPGroupElem)
     return group_element(Q,GAP.Globals.MappedWord(x.X,GAP.Globals.GeneratorsOfGroup(G.X), GAP.Globals.GeneratorsOfGroup(Q.X)))
  end
  return Q, hom(G,Q,proj)
end

"""
    quo([::Type{Q}, ]G::T, elements::Vector{elem_type(G)})) where {Q <: GAPGroup, T <: GAPGroup}

Return the quotient group `G/N`, together with the projection `G` -> `G/N`,
where `N` is the normal closure of `elements` in `G`.

See [`quo(G::T, N::T) where T <: GAPGroup`](@ref)
for information about the type of `G/N`.
"""
function quo(G::T, elements::Vector{S}) where T <: GAPGroup where S <: GAPGroupElem
  @assert elem_type(G) == S
  if length(elements) == 0
    H1 = trivial_subgroup(G)[1]
  else
    elems_in_gap = GapObj([x.X for x in elements])
    H = GAP.Globals.NormalClosure(G.X,GAP.Globals.Group(elems_in_gap))
    @assert GAPWrap.IsNormal(G.X, H)
    H1 = _as_subgroup_bare(G, H)
  end
  return quo(G, H1)
end

function quo(::Type{Q}, G::T, elements::Vector{S}) where {Q <: GAPGroup, T <: GAPGroup, S <: GAPGroupElem}
  F, epi = quo(G, elements)
  if !(F isa Q)
    F, map = isomorphic_group(Q, F)
    epi = compose(epi, map)
  end
  return F, epi
end

"""
    quo([::Type{Q}, ]G::T, N::T) where {Q <: GAPGroup, T <: GAPGroup}

Return the quotient group `G/N`, together with the projection `G` -> `G/N`.

If `Q` is given then `G/N` has type `Q` if possible,
and an exception is thrown if not.

If `Q` is not given then the type of `G/N` is not determined by the type of `G`.
- `G/N` may have the same type as `G` (which is reasonable if `N` is trivial),
- `G/N` may have type `PcGroup` (which is reasonable if `G/N` is finite and solvable), or
- `G/N` may have type `PermGroup` (which is reasonable if `G/N` is finite and non-solvable).
- `G/N` may have type `FPGroup` (which is reasonable if `G/N` is infinite).

An exception is thrown if `N` is not a normal subgroup of `G`.

# Examples
```jldoctest
julia> G = symmetric_group(4)
Sym( [ 1 .. 4 ] )

julia> N = pcore(G, 2)[1];

julia> typeof(quo(G, N)[1])
PcGroup

julia> typeof(quo(PermGroup, G, N)[1])
PermGroup
```
"""
function quo(G::T, N::T) where T <: GAPGroup
  mp = GAP.Globals.NaturalHomomorphismByNormalSubgroup(G.X, N.X)
  cod = GAP.Globals.ImagesSource(mp)
  S = elem_type(G)
  S1 = _get_type(cod)
  codom = S1(cod)
  mp_julia = __create_fun(mp, codom, S)
  return codom, hom(G, codom, mp_julia)
end

function quo(::Type{Q}, G::T, N::T) where {Q <: GAPGroup, T <: GAPGroup}
  F, epi = quo(G, N)
  if !(F isa Q)
    F, map = isomorphic_group(Q, F)
    epi = compose(epi, map)
  end
  return F, epi
end

"""
    maximal_abelian_quotient([::Type{Q}, ]G::GAPGroup)

Return `F, epi` such that `F` is the largest abelian factor group of `G`
and `epi` is an epimorphism from `G` to `F`.

If `Q` is given then `F` has type `Q` if possible,
and an exception is thrown if not.

If `Q` is not given then the type of `F` is not determined by the type of `G`.
- `F` may have the same type as `G` (which is reasonable if `G` is abelian),
- `F` may have type `PcGroup` (which is reasonable if `F` is finite), or
- `F` may have type `FPGroup` (which is reasonable if `F` is infinite).

# Examples
```jldoctest
julia> G = symmetric_group(4);

julia> F, epi = maximal_abelian_quotient(G);

julia> order(F)
2

julia> domain(epi) === G && codomain(epi) === F
true

julia> typeof(F)
PcGroup

julia> typeof(maximal_abelian_quotient(free_group(1))[1])
FPGroup

julia> typeof(maximal_abelian_quotient(PermGroup, G)[1])
PermGroup
```
"""
function maximal_abelian_quotient(G::GAPGroup)
  map = GAP.Globals.MaximalAbelianQuotient(G.X)
  F = GAP.Globals.Range(map)
  S1 = _get_type(F)
  F = S1(F)
  return F, GAPGroupHomomorphism(G, F, map)
end

function maximal_abelian_quotient(::Type{Q}, G::GAPGroup) where Q <: GAPGroup
  F, epi = maximal_abelian_quotient(G)
  if !(F isa Q)
    F, map = isomorphic_group(Q, F)
    epi = compose(epi, map)
  end
  return F, epi
end

@gapwrap hasmaximal_abelian_quotient(G::GAPGroup) = GAP.Globals.HasMaximalAbelianQuotient(G.X)::Bool
@gapwrap setmaximal_abelian_quotient(G::T, val::Tuple{GAPGroup, GAPGroupHomomorphism{T,S}}) where T <: GAPGroup where S = GAP.Globals.SetMaximalAbelianQuotient(G.X, val[2].map)::Nothing


function __create_fun(mp, codom, ::Type{S}) where S
  function mp_julia(x::S)
    el = GAP.Globals.Image(mp, x.X)
    return group_element(codom, el)
  end
  return mp_julia
end

################################################################################
#
#  Derived subgroup and derived series
#  
################################################################################

"""
    derived_subgroup(G::GAPGroup)

Return the derived subgroup of `G`, i.e.,
the subgroup generated by all commutators of `G`.
"""
@gapattribute derived_subgroup(G::GAPGroup) =
  _as_subgroup(G, GAP.Globals.DerivedSubgroup(G.X))

@doc Markdown.doc"""
    derived_series(G::GAPGroup)

Return the vector $[ G_1, G_2, \ldots ]$,
where $G_1 =$ `G` and $G_{i+1} =$ `derived_subgroup`$(G_i)$.
"""
@gapattribute derived_series(G::GAPGroup) = _as_subgroups(G, GAP.Globals.DerivedSeries(G.X))


################################################################################
#
#  Intersection
#
################################################################################

@doc Markdown.doc"""
    intersect(V::T...) where T <: Group
    intersect(V::AbstractVector{T}) where T <: Group

If `V` is $[ G_1, G_2, \ldots, G_n ]$,
return the intersection $K$ of the groups $G_1, G_2, \ldots, G_n$,
together with the embeddings of $K into $G_i$.
"""
function intersect(V::T...) where T<:GAPGroup
   L = GapObj([G.X for G in V])
   K = GAP.Globals.Intersection(L)
   Embds = [_as_subgroup(G, K)[2] for G in V]
   K = _as_subgroup(V[1], K)[1]
   Arr = Tuple(vcat([K],Embds))
   return Arr
end

function intersect(V::AbstractVector{T}) where T<:GAPGroup
   L = GapObj([G.X for G in V])
   K = GAP.Globals.Intersection(L)
   Embds = [_as_subgroup(G, K)[2] for G in V]
   K = _as_subgroup(V[1], K)[1]
   Arr = Tuple(vcat([K],Embds))
   return Arr
end
#T why duplicate this code?


################################################################################
#
#  Conversions between types
#
################################################################################

_get_iso_function(::Type{PermGroup}) = GAP.Globals.IsomorphismPermGroup
_get_iso_function(::Type{FPGroup}) = GAP.Globals.IsomorphismFpGroup
_get_iso_function(::Type{PcGroup}) = GAP.Globals.IsomorphismPcGroup

function isomorphic_group(::Type{T}, G::GAPGroup) where T <: GAPGroup
  f = _get_iso_function(T)
  mp = f(G.X)
  G1 = T(GAP.Globals.ImagesSource(mp))
  fmap = GAPGroupHomomorphism(G, G1, mp)
  return G1, fmap
end
