###############################################################################
###############################################################################
### Definition and constructors
###############################################################################
###############################################################################

#TODO: have cone accept exterior description and reserve positive  hull for
#interior description?

@doc Markdown.doc"""
    Cone(R::Union{Oscar.MatElem, AbstractMatrix, SubObjectIterator} [, L::Union{Oscar.MatElem, AbstractMatrix, SubObjectIterator}])

A polyhedral cone, not necessarily pointed, defined by the positive hull of the
rays `R`, with lineality given by `L`.

`R` is given row-wise as representative vectors, with lineality generated by the
rows of `L`.

# Examples
To construct the positive orthant as a `Cone`, you can write:
```jldoctest
julia> R = [1 0; 0 1];

julia> PO = Cone(R)
A polyhedral cone in ambient dimension 2
```

To obtain the upper half-space of the plane:
```jldoctest
julia> R = [0 1];

julia> L = [1 0];

julia> HS = Cone(R, L)
A polyhedral cone in ambient dimension 2
```
"""
function Cone(R::Union{SubObjectIterator{<:RayVector}, Oscar.MatElem, AbstractMatrix}, L::Union{SubObjectIterator{<:RayVector}, Oscar.MatElem, AbstractMatrix, Nothing} = nothing; non_redundant::Bool = false)
    if isnothing(L) || isempty(L)
        L = Polymake.Matrix{Polymake.Rational}(undef, 0, size(R, 2))
    end

    if non_redundant
        return Cone(Polymake.polytope.Cone{Polymake.Rational}(RAYS = R, LINEALITY_SPACE = L,))
    else
        return Cone(Polymake.polytope.Cone{Polymake.Rational}(INPUT_RAYS = R, INPUT_LINEALITY = L,))
    end
end

function ==(C0::Cone, C1::Cone)
    # TODO: Remove the following 3 lines, see #758
    for pair in Iterators.product([C0, C1], ["RAYS", "FACETS"])
        Polymake.give(pm_object(pair[1]),pair[2])
    end
    return Polymake.polytope.equal_polyhedra(pm_object(C0), pm_object(C1))
end


@doc Markdown.doc"""
    positive_hull(R::Union{Oscar.MatElem, AbstractMatrix, SubObjectIterator})

A polyhedral cone, not necessarily pointed, defined by the positive hull of the
rows of the matrix `R`. This means the cone consists of all positive linear
combinations of the rows of `R`. This is an interior description, analogous to
the $V$-representation of a polytope.

Redundant rays are allowed.

# Examples
```jldoctest
julia> R = [1 0; 0 1];

julia> PO = positive_hull(R)
A polyhedral cone in ambient dimension 2
```
"""
function positive_hull(R::Union{SubObjectIterator{<:RayVector}, Oscar.MatElem, AbstractMatrix})
    C=Polymake.polytope.Cone{Polymake.Rational}(INPUT_RAYS =
      remove_zero_rows(R))
    Cone(C)
end

@doc Markdown.doc"""

    cone_from_inequalities(I::Union{Oscar.MatElem, AbstractMatrix, SubObjectIterator} [, E::Union{Oscar.MatElem, AbstractMatrix, SubObjectIterator}]; non_redundant::Bool = false)

The (convex) cone defined by

$$\{ x |  Ix ≤ 0, Ex = 0 \}.$$

Use `non_redundant = true` if the given description contains no redundant rows to
avoid unnecessary redundancy checks.

# Examples
```jldoctest
julia> C = cone_from_inequalities([0 -1; -1 1])
A polyhedral cone in ambient dimension 2

julia> rays(C)
2-element SubObjectIterator{RayVector{Polymake.Rational}}:
 [1, 0]
 [1, 1]
```
"""
function cone_from_inequalities(I::Union{SubObjectIterator{<:Halfspace}, Oscar.MatElem, AbstractMatrix}, E::Union{Nothing, SubObjectIterator{<:Hyperplane}, Oscar.MatElem, AbstractMatrix} = nothing; non_redundant::Bool = false)
    IM = -linear_matrix_for_polymake(I)
    EM = isnothing(E) || isempty(E) ? Polymake.Matrix{Polymake.Rational}(undef, 0, size(IM, 2)) : linear_matrix_for_polymake(E)

    if non_redundant
        return Cone(Polymake.polytope.Cone{Polymake.Rational}(FACETS = IM, LINEAR_SPAN = EM))
    else
        return Cone(Polymake.polytope.Cone{Polymake.Rational}(INEQUALITIES = IM, EQUATIONS = EM))
    end
end

"""
    pm_object(C::Cone)

Get the underlying polymake `Cone`.
"""
pm_object(C::Cone) = C.pm_cone


###############################################################################
###############################################################################
### Display
###############################################################################
###############################################################################

function Base.show(io::IO, C::Cone)
    print(io,"A polyhedral cone in ambient dimension $(ambient_dim(C))")
end

Polymake.visual(C::Cone; opts...) = Polymake.visual(pm_object(C); opts...)
