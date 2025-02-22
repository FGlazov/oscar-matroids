###############################################################################
###############################################################################
### Definition and constructors
###############################################################################
###############################################################################

@doc Markdown.doc"""

    Polyhedron(P::Polymake.BigObject)

Construct a `Polyhedron` corresponding to a `Polymake.BigObject` of type `Polytope`.
"""
function Polyhedron(pm_polytope::Polymake.BigObject)
    Polyhedron(pm_polytope, :unknown)
end

@doc Markdown.doc"""

    Polyhedron(A::Union{Oscar.MatElem,AbstractMatrix}, b)

The (convex) polyhedron defined by

$$P(A,b) = \{ x |  Ax ≤ b \}.$$

see Def. 3.35 and Section 4.1. of [JT13](@cite)

# Examples
The following lines define the square $[0,1]^2 \subset \mathbb{R}^2$:
```jldoctest
julia> A = [1 0; 0 1; -1 0 ; 0 -1];

julia> b = [1, 1, 0, 0];

julia> Polyhedron(A,b)
A polyhedron in ambient dimension 2
```

As an example for a polyhedron constructed from both inequalities and
equations, we construct the polytope $[0,1]\times\{0\}\subset\mathbb{R}^2$
```jldoctest
julia> P = Polyhedron(([-1 0; 1 0], [0,1]), ([0 1], [0]))
A polyhedron in ambient dimension 2

julia> isfeasible(P)
true

julia> dim(P)
1

julia> vertices(P)
2-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [1, 0]
 [0, 0]
```
"""
Polyhedron(A::Union{Oscar.MatElem,AbstractMatrix}, b) = Polyhedron((A, b))

function Polyhedron(I::Union{SubObjectIterator, Tuple{<:Union{Oscar.MatElem, AbstractMatrix}, Any}}, E::Union{Nothing, SubObjectIterator, Tuple{<:Union{Oscar.MatElem, AbstractMatrix}, Any}} = nothing)
    IM = -affine_matrix_for_polymake(I)
    EM = isnothing(E) || _isempty_halfspace(E) ? Polymake.Matrix{Polymake.Rational}(undef, 0, size(IM, 2)) : affine_matrix_for_polymake(E)

    return Polyhedron(Polymake.polytope.Polytope{Polymake.Rational}(INEQUALITIES = remove_zero_rows(IM), EQUATIONS = remove_zero_rows(EM)))
end

"""
    pm_object(P::Polyhedron)

Get the underlying polymake `Polytope`.
"""
pm_object(P::Polyhedron) = P.pm_polytope

function ==(P0::Polyhedron, P1::Polyhedron)
    # TODO: Remove the following 3 lines, see #758
    for pair in Iterators.product([P0, P1], ["RAYS", "FACETS"])
        Polymake.give(pm_object(pair[1]),pair[2])
    end
    Polymake.polytope.equal_polyhedra(pm_object(P0), pm_object(P1))
end


### Construct polyhedron from V-data, as the convex hull of points, rays and lineality.
@doc Markdown.doc"""
    convex_hull(V [, R [, L]]; non_redundant::Bool = false)

Construct the convex hull of the vertices `V`, rays `R`, and lineality `L`. If
`R` or `L` are omitted, then they are assumed to be zero.

# Arguments
- `V::Union{Matrix, SubObjectIterator}`: Points whose convex hull is to be computed.
- `R::Union{Matrix, SubObjectIterator}`: Rays completing the set of points.
- `L::Union{Matrix, SubObjectIterator}`: Generators of the Lineality space.

If an argument is given as a matrix, its content has to be encoded row-wise.

`R` can be given as an empty matrix or as `nothing` if the user wants to compute
the convex hull only from `V` and `L`.

If it is known that `V` and `R` only contain extremal points and that the
description of the lineality space is complete, set `non_redundant =
true` to avoid unnecessary redundancy checks.

See Def. 2.11 and Def. 3.1  of [JT13](@cite).

# Examples
The following lines define the square $[0,1]^2 \subset \mathbb{R}^2$:
```jldoctest
julia> Square = convex_hull([0 0; 0 1; 1 0; 1 1])
A polyhedron in ambient dimension 2
```
To construct the positive orthant, rays have to be passed:
```jldoctest
julia> V = [0 0];

julia> R = [1 0; 0 1];

julia> PO = convex_hull(V, R)
A polyhedron in ambient dimension 2
```
The closed-upper half plane can be constructed by passing rays and a lineality space:
```jldoctest
julia> V = [0 0];

julia> R = [0 1];

julia> L = [1 0];

julia> UH = convex_hull(V, R, L)
A polyhedron in ambient dimension 2
```
To obtain the x-axis in $\mathbb{R}^2$:
```jldoctest
julia> V = [0 0];

julia> R = nothing;

julia> L = [1 0];

julia> XA = convex_hull(V, R, L)
A polyhedron in ambient dimension 2
```
"""
function convex_hull(V::Union{SubObjectIterator{PointVector}, AnyVecOrMat, Oscar.MatElem}, R::Union{SubObjectIterator{RayVector}, AnyVecOrMat, Oscar.MatElem, Nothing} = nothing, L::Union{SubObjectIterator{RayVector}, AnyVecOrMat, Oscar.MatElem, Nothing} = nothing; non_redundant::Bool = false)
    # Rays and Points are homogenized and combined and
    # Lineality is homogenized
    points = stack(homogenized_matrix(V, 1), homogenized_matrix(R, 0))
    lineality = isnothing(L) || isempty(L) ? zero_matrix(QQ, 0, size(points,2)) : homogenized_matrix(L, 0)

    # These matrices are in the right format for polymake.
    # given non_redundant can avoid unnecessary redundancy checks
    if non_redundant
        return Polyhedron(Polymake.polytope.Polytope{Polymake.Rational}(VERTICES = points, LINEALITY_SPACE = lineality))
    else
        return Polyhedron(Polymake.polytope.Polytope{Polymake.Rational}(POINTS = remove_zero_rows(points), INPUT_LINEALITY = remove_zero_rows(lineality)))
    end
end

###############################################################################
###############################################################################
### Display
###############################################################################
###############################################################################
function Base.show(io::IO, P::Polyhedron)
    try
        ad = ambient_dim(P)
        print(io, "A polyhedron in ambient dimension $(ad)")
    catch e
        print(io, "A polyhedron without ambient dimension")
    end
end

Polymake.visual(P::Polyhedron; opts...) = Polymake.visual(pm_object(P); opts...)
