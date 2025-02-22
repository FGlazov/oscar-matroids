###############################################################################
###############################################################################
### Standard constructions
###############################################################################
###############################################################################
@doc Markdown.doc"""
    birkhoff(n::Integer, even::Bool = false)

Construct the Birkhoff polytope of dimension $n^2$.

This is the polytope of $n \times n$ stochastic matrices (encoded as row vectors of
length $n^2$), i.e., the matrices with non-negative real entries whose row and column
entries sum up to one. Its vertices are the permutation matrices.

Use `even = true` to get the vertices only for the even permutation matrices.

# Example
```jldoctest
julia> b = birkhoff(3)
A polyhedron in ambient dimension 9

julia> vertices(b)
6-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [1, 0, 0, 0, 1, 0, 0, 0, 1]
 [0, 1, 0, 1, 0, 0, 0, 0, 1]
 [0, 0, 1, 1, 0, 0, 0, 1, 0]
 [1, 0, 0, 0, 0, 1, 0, 1, 0]
 [0, 1, 0, 0, 0, 1, 1, 0, 0]
 [0, 0, 1, 0, 1, 0, 1, 0, 0]
```
"""
birkhoff(n::Integer; even::Bool = false) = Polyhedron(Polymake.polytope.birkhoff(n, Int(even), group=true))



@doc Markdown.doc"""
    pyramid(P::Polyhedron, z::Number = 1)

Make a pyramid over the given polyhedron `P`.

The pyramid is the convex hull of the input polyhedron `P` and a point `v`
outside the affine span of `P`. For bounded polyhedra, the projection of `v` to
the affine span of `P` coincides with the vertex barycenter of `P`. The scalar `z`
is the distance between the vertex barycenter and `v`.


# Example
```jldoctest
julia> c = cube(2)
A polyhedron in ambient dimension 2

julia> vertices(pyramid(c,5))
5-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [-1, -1, 0]
 [1, -1, 0]
 [-1, 1, 0]
 [1, 1, 0]
 [0, 0, 5]
```
"""
function pyramid(P::Polyhedron, z::Number=1)
   pm_in = pm_object(P)
   has_group = Polymake.exists(pm_in, "GROUP")
   return Polyhedron(Polymake.polytope.pyramid(pm_in, z, group=has_group))
end



@doc Markdown.doc"""
    bipyramid(P::Polyhedron, z::Number = 1, z_prime::Number = -z)

Make a bipyramid over a pointed polyhedron `P`.

The bipyramid is the convex hull of the input polyhedron `P` and two apexes
(`v`, `z`), (`v`, `z_prime`) on both sides of the affine span of `P`. For bounded
polyhedra, the projections of the apexes `v` to the affine span of `P` is the
vertex barycenter of `P`.

# Example
```jldoctest
julia> c = cube(2)
A polyhedron in ambient dimension 2

julia> vertices(bipyramid(c,2))
6-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [-1, -1, 0]
 [1, -1, 0]
 [-1, 1, 0]
 [1, 1, 0]
 [0, 0, 2]
 [0, 0, -2]

```
"""
function bipyramid(P::Polyhedron, z::Number=1, z_prime::Number=-z)
   pm_in = pm_object(P)
   has_group = Polymake.exists(pm_in, "GROUP")
   return Polyhedron(Polymake.polytope.bipyramid(pm_in, z, z_prime, group=has_group))
end



@doc Markdown.doc"""
    normal_cone(P::Polyhedron, i::Int64)

Construct the normal cone to `P` at the `i`-th vertex of `P`.

The normal cone at a face is generated by all the inner normals of `P` that
attain their minimum at the `i`-th vertex.

# Example
Build the normal cones at the first vertex of the square (in this case [-1,-1]).
```jldoctest
julia> square = cube(2)
A polyhedron in ambient dimension 2

julia> vertices(square)
4-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [-1, -1]
 [1, -1]
 [-1, 1]
 [1, 1]

julia> nc = normal_cone(square, 1)
A polyhedral cone in ambient dimension 2

julia> rays(nc)
2-element SubObjectIterator{RayVector{Polymake.Rational}}:
 [1, 0]
 [0, 1]
```
"""
function normal_cone(P::Polyhedron, i::Int64)
    if(i<1 || i>nvertices(P))
       throw(ArgumentError("Vertex index out of range"))
    end
    bigobject = Polymake.polytope.normal_cone(pm_object(P), Set{Int64}([i-1]))
    return Cone(bigobject)
end


@doc Markdown.doc"""
    orbit_polytope(V::AbstractVecOrMat, G::PermGroup)

Construct the convex hull of the orbit of one or several points (given row-wise
in `V`) under the action of `G`.

# Examples
This will construct the $3$-dimensional permutahedron:
```jldoctest
julia> V = [1 2 3];

julia> G = symmetric_group(3);

julia> P = orbit_polytope(V, G)
A polyhedron in ambient dimension 3

julia> vertices(P)
6-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [1, 2, 3]
 [1, 3, 2]
 [2, 1, 3]
 [2, 3, 1]
 [3, 1, 2]
 [3, 2, 1]
```
"""
function orbit_polytope(V::AbstractMatrix, G::PermGroup)
   if size(V)[2] != degree(G)
      throw(ArgumentError("Dimension of points and group degree need to be the same."))
   end
   generators = PermGroup_to_polymake_array(G)
   pmGroup = Polymake.group.PermutationAction(GENERATORS=generators)
   pmPolytope = Polymake.polytope.orbit_polytope(homogenize(V,1), pmGroup)
   return Polyhedron(pmPolytope)
end
function orbit_polytope(V::AbstractVector, G::PermGroup)
   return orbit_polytope(Matrix(reshape(V,(1,length(V)))), G)
end

@doc Markdown.doc"""
    cube(d::Int , [l::Rational = -1, u::Rational = 1])

Construct the $[l,u]$-cube in dimension $d$.

# Examples
In this example the 5-dimensional unit cube is constructed to ask for one of its
properties:
```jldoctest
julia> C = cube(5,0,1);

julia> normalized_volume(C)
120
```
"""
cube(d) = Polyhedron(Polymake.polytope.cube(d))
cube(d, l, u) = Polyhedron(Polymake.polytope.cube(d, u, l))



"""
    newton_polytope(poly::Polynomial)

Compute the Newton polytope of the multivariate polynomial `poly`.

# Examples
```jldoctest
julia> S, (x, y) = PolynomialRing(ZZ, ["x", "y"])
(Multivariate Polynomial Ring in x, y over Integer Ring, fmpz_mpoly[x, y])

julia> f = x^3*y + 3x*y^2 + 1
x^3*y + 3*x*y^2 + 1

julia> NP = newton_polytope(f)
A polyhedron in ambient dimension 2

julia> vertices(NP)
3-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [3, 1]
 [1, 2]
 [0, 0]
```
"""
function newton_polytope(f)
    exponents = reduce(hcat, Oscar.exponent_vectors(f))'
    convex_hull(exponents)
end




@doc Markdown.doc"""
    intersect(P::Polyhedron, Q::Polyhedron)

Return the intersection $P \cap Q$ of `P` and `Q`.

# Examples
The positive orthant of the plane is the intersection of the two halfspaces with
$x≥0$ and $y≥0$ respectively.
```jldoctest
julia> UH1 = convex_hull([0 0],[1 0],[0 1]);

julia> UH2 = convex_hull([0 0],[0 1],[1 0]);

julia> PO = intersect(UH1, UH2)
A polyhedron in ambient dimension 2

julia> rays(PO)
2-element SubObjectIterator{RayVector{Polymake.Rational}}:
 [1, 0]
 [0, 1]
```
"""
function intersect(P::Polyhedron, Q::Polyhedron)
   return Polyhedron(Polymake.polytope.intersection(pm_object(P), pm_object(Q)))
end


@doc Markdown.doc"""
    minkowski_sum(P::Polyhedron, Q::Polyhedron)

Return the Minkowski sum $P + Q = \{ x+y\ |\ x∈P, y∈Q\}$ of `P` and `Q`.

# Examples
The Minkowski sum of a square and the 2-dimensional cross-polytope is an
octagon:
```jldoctest
julia> P = cube(2);

julia> Q = cross(2);

julia> M = minkowski_sum(P, Q)
A polyhedron in ambient dimension 2

julia> nvertices(M)
8
```
"""
function minkowski_sum(P::Polyhedron, Q::Polyhedron; algorithm::Symbol=:standard)
   if algorithm == :standard
      return Polyhedron(Polymake.polytope.minkowski_sum(pm_object(P), pm_object(Q)))
   elseif algorithm == :fukuda
      return Polyhedron(Polymake.polytope.minkowski_sum_fukuda(pm_object(P), pm_object(Q)))
   else
      throw(ArgumentError("Unknown minkowski sum `algorithm` argument: $algorithm"))
   end
end





@doc Markdown.doc"""
    product(P::Polyhedron, Q::Polyhedron)

Return the Cartesian product of `P` and `Q`.

# Examples
The Cartesian product of a triangle and a line segment is a triangular prism.
```jldoctest
julia> T=simplex(2)
A polyhedron in ambient dimension 2

julia> S=cube(1)
A polyhedron in ambient dimension 1

julia> length(vertices(product(T,S)))
6
```
"""
product(P::Polyhedron, Q::Polyhedron) = Polyhedron(Polymake.polytope.product(pm_object(P), pm_object(Q)))

@doc Markdown.doc"""
    *(P::Polyhedron, Q::Polyhedron)

Return the Cartesian product of `P` and `Q` (see also `product`).

# Examples
The Cartesian product of a triangle and a line segment is a triangular prism.
```jldoctest
julia> T=simplex(2)
A polyhedron in ambient dimension 2

julia> S=cube(1)
A polyhedron in ambient dimension 1

julia> length(vertices(T*S))
6
```
"""
*(P::Polyhedron, Q::Polyhedron) = product(P,Q)

@doc Markdown.doc"""
    convex_hull(P::Polyhedron, Q::Polyhedron)

Return the convex_hull of `P` and `Q`.

# Examples
The convex hull of the following two line segments in $R^3$ is a tetrahedron.
```jldoctest
julia> L₁ = convex_hull([-1 0 0; 1 0 0])
A polyhedron in ambient dimension 3

julia> L₂ = convex_hull([0 -1 0; 0 1 0])
A polyhedron in ambient dimension 3

julia> T=convex_hull(L₁,L₂);

julia> f_vector(T)
2-element Vector{Int64}:
 4
 4
```
"""
convex_hull(P::Polyhedron,Q::Polyhedron) = Polyhedron(Polymake.polytope.conv(pm_object(P),pm_object(Q)))



#TODO: documentation  + extend to different fields.

@doc Markdown.doc"""
    +(P::Polyhedron, Q::Polyhedron)

Return the Minkowski sum $P + Q = \{ x+y\ |\ x∈P, y∈Q\}$ of `P` and `Q` (see also `minkowski_sum`).

# Examples
The Minkowski sum of a square and the 2-dimensional cross-polytope is an
octagon:
```jldoctest
julia> P = cube(2);

julia> Q = cross(2);

julia> M = minkowski_sum(P, Q)
A polyhedron in ambient dimension 2

julia> nvertices(M)
8
```
"""
+(P::Polyhedron, Q::Polyhedron) = minkowski_sum(P,Q)


#TODO: extend to different fields

@doc Markdown.doc"""
    *(k::Int, Q::Polyhedron)

Return the scaled polyhedron $kQ = \{ kx\ |\ x∈Q\}$.

Note that `k*Q = Q*k`.

# Examples
Scaling an $n$-dimensional bounded polyhedron by the factor $k$ results in the
volume being scaled by $k^n$.
This example confirms the statement for the 6-dimensional cube and $k = 2$.
```jldoctest
julia> C = cube(6);

julia> SC = 2*C
A polyhedron in ambient dimension 6

julia> volume(SC)//volume(C)
64
```
"""
*(k::Int, P::Polyhedron) = Polyhedron(Polymake.polytope.scale(pm_object(P),k))


@doc Markdown.doc"""
    *(P::Polyhedron, k::Int)

Return the scaled polyhedron $kP = \{ kx\ |\ x∈P\}$.

Note that `k*P = P*k`.

# Examples
Scaling an $n$-dimensional bounded polyhedron by the factor $k$ results in the
volume being scaled by $k^n$.
This example confirms the statement for the 6-dimensional cube and $k = 2$.
```jldoctest
julia> C = cube(6);

julia> SC = C*2
A polyhedron in ambient dimension 6

julia> volume(SC)//volume(C)
64
```
"""
*(P::Polyhedron,k::Int) = k*P


@doc Markdown.doc"""
    +(P::Polyhedron, v::AbstractVector)

Return the translation $P+v = \{ x+v\ |\ x∈P\}$ of `P` by `v`.

Note that `P+v = v+P`.

# Examples
We construct a polyhedron from its $V$-description. Shifting it by the right
vector reveals that its inner geometry corresponds to that of the 3-simplex.
```jldoctest
julia> P = convex_hull([100 200 300; 101 200 300; 100 201 300; 100 200 301]);

julia> v = [-100, -200, -300];

julia> S = P + v
A polyhedron in ambient dimension 3

julia> vertices(S)
4-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [0, 0, 0]
 [1, 0, 0]
 [0, 1, 0]
 [0, 0, 1]
```
"""
function +(P::Polyhedron,v::AbstractVector)
    if ambient_dim(P) != length(v)
        throw(ArgumentError("Translation vector not correct dimension"))
    else
        return Polyhedron(Polymake.polytope.translate(pm_object(P),Polymake.Vector{Polymake.Rational}(v)))
    end
end


@doc Markdown.doc"""
    +(v::AbstractVector, P::Polyhedron)

Return the translation $P+v = \{ x+v\ |\ x∈P\}$ of `P` by `v`.

Note that `P+v = v+P`.

# Examples
We construct a polyhedron from its $V$-description. Shifting it by the right
vector reveals that its inner geometry corresponds to that of the 3-simplex.
```jldoctest
julia> P = convex_hull([100 200 300; 101 200 300; 100 201 300; 100 200 301]);

julia> v = [-100, -200, -300];

julia> S = v + P
A polyhedron in ambient dimension 3

julia> vertices(S)
4-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [0, 0, 0]
 [1, 0, 0]
 [0, 1, 0]
 [0, 0, 1]
```
"""
+(v::AbstractVector,P::Polyhedron) = P+v

@doc Markdown.doc"""

    simplex(d::Int [,n::Rational])

Construct the simplex which is the convex hull of the standard basis vectors
along with the origin in $\mathbb{R}^d$, scaled by $n$.

# Examples
Here we take a look at the facets of the 7-simplex and a scaled 7-simplex:
```jldoctest
julia> s = simplex(7)
A polyhedron in ambient dimension 7

julia> facets(s)
8-element SubObjectIterator{AffineHalfspace}:
 The Halfspace of R^7 described by
1: -x₁ ≦ 0

 The Halfspace of R^7 described by
1: -x₂ ≦ 0

 The Halfspace of R^7 described by
1: -x₃ ≦ 0

 The Halfspace of R^7 described by
1: -x₄ ≦ 0

 The Halfspace of R^7 described by
1: -x₅ ≦ 0

 The Halfspace of R^7 described by
1: -x₆ ≦ 0

 The Halfspace of R^7 described by
1: -x₇ ≦ 0

 The Halfspace of R^7 described by
1: x₁ + x₂ + x₃ + x₄ + x₅ + x₆ + x₇ ≦ 1

julia> t = simplex(7, 5)
A polyhedron in ambient dimension 7

julia> facets(t)
8-element SubObjectIterator{AffineHalfspace}:
 The Halfspace of R^7 described by
1: -x₁ ≦ 0

 The Halfspace of R^7 described by
1: -x₂ ≦ 0

 The Halfspace of R^7 described by
1: -x₃ ≦ 0

 The Halfspace of R^7 described by
1: -x₄ ≦ 0

 The Halfspace of R^7 described by
1: -x₅ ≦ 0

 The Halfspace of R^7 described by
1: -x₆ ≦ 0

 The Halfspace of R^7 described by
1: -x₇ ≦ 0

 The Halfspace of R^7 described by
1: x₁ + x₂ + x₃ + x₄ + x₅ + x₆ + x₇ ≦ 5
```
"""
simplex(d::Int64,n) = Polyhedron(Polymake.polytope.simplex(d,n))
simplex(d::Int64) = Polyhedron(Polymake.polytope.simplex(d))


@doc Markdown.doc"""

    cross(d::Int [,n::Rational])

Construct a $d$-dimensional cross polytope around origin with vertices located
at $\pm e_i$ for each unit vector $e_i$ of $R^d$, scaled by $n$.

# Examples
Here we print the facets of a non-scaled and a scaled 3-dimensional cross
polytope:
```jldoctest
julia> C = cross(3)
A polyhedron in ambient dimension 3

julia> facets(C)
8-element SubObjectIterator{AffineHalfspace}:
 The Halfspace of R^3 described by
1: x₁ + x₂ + x₃ ≦ 1

 The Halfspace of R^3 described by
1: -x₁ + x₂ + x₃ ≦ 1

 The Halfspace of R^3 described by
1: x₁ - x₂ + x₃ ≦ 1

 The Halfspace of R^3 described by
1: -x₁ - x₂ + x₃ ≦ 1

 The Halfspace of R^3 described by
1: x₁ + x₂ - x₃ ≦ 1

 The Halfspace of R^3 described by
1: -x₁ + x₂ - x₃ ≦ 1

 The Halfspace of R^3 described by
1: x₁ - x₂ - x₃ ≦ 1

 The Halfspace of R^3 described by
1: -x₁ - x₂ - x₃ ≦ 1

julia> D = cross(3, 2)
A polyhedron in ambient dimension 3

julia> facets(D)
8-element SubObjectIterator{AffineHalfspace}:
 The Halfspace of R^3 described by
1: x₁ + x₂ + x₃ ≦ 2

 The Halfspace of R^3 described by
1: -x₁ + x₂ + x₃ ≦ 2

 The Halfspace of R^3 described by
1: x₁ - x₂ + x₃ ≦ 2

 The Halfspace of R^3 described by
1: -x₁ - x₂ + x₃ ≦ 2

 The Halfspace of R^3 described by
1: x₁ + x₂ - x₃ ≦ 2

 The Halfspace of R^3 described by
1: -x₁ + x₂ - x₃ ≦ 2

 The Halfspace of R^3 described by
1: x₁ - x₂ - x₃ ≦ 2

 The Halfspace of R^3 described by
1: -x₁ - x₂ - x₃ ≦ 2
```
"""
cross(d::Int64,n) = Polyhedron(Polymake.polytope.cross(d,n))
cross(d::Int64) = Polyhedron(Polymake.polytope.cross(d))

@doc Markdown.doc"""

    archimedean_solid(s)

Construct an Archimedean solid with the name given by String `s` from the list
below.  The polytopes are realized with floating point numbers and thus not
exact; Vertex-facet-incidences are correct in all cases.

# Arguments
- `s::String`: The name of the desired Archimedean solid.
    Possible values:
    - "truncated_tetrahedron" : Truncated tetrahedron.
          Regular polytope with four triangular and four hexagonal facets.
    - "cuboctahedron" : Cuboctahedron.
          Regular polytope with eight triangular and six square facets.
    - "truncated_cube" : Truncated cube.
          Regular polytope with eight triangular and six octagonal facets.
    - "truncated_octahedron" : Truncated Octahedron.
          Regular polytope with six square and eight hexagonal facets.
    - "rhombicuboctahedron" : Rhombicuboctahedron.
          Regular polytope with eight triangular and 18 square facets.
    - "truncated_cuboctahedron" : Truncated Cuboctahedron.
          Regular polytope with 12 square, eight hexagonal and six octagonal
          facets.
    - "snub_cube" : Snub Cube.
          Regular polytope with 32 triangular and six square facets.
          The vertices are realized as floating point numbers.
          This is a chiral polytope.
    - "icosidodecahedron" : Icosidodecahedon.
          Regular polytope with 20 triangular and 12 pentagonal facets.
    - "truncated_dodecahedron" : Truncated Dodecahedron.
          Regular polytope with 20 triangular and 12 decagonal facets.
    - "truncated_icosahedron" : Truncated Icosahedron.
          Regular polytope with 12 pentagonal and 20 hexagonal facets.
    - "rhombicosidodecahedron" : Rhombicosidodecahedron.
          Regular polytope with 20 triangular, 30 square and 12 pentagonal
          facets.
    - "truncated_icosidodecahedron" : Truncated Icosidodecahedron.
          Regular polytope with 30 square, 20 hexagonal and 12 decagonal
          facets.
    - "snub_dodecahedron" : Snub Dodecahedron.
          Regular polytope with 80 triangular and 12 pentagonal facets.
          The vertices are realized as floating point numbers.
          This is a chiral polytope.

# Examples
```jldoctest
julia> T = archimedean_solid("cuboctahedron")
A polyhedron in ambient dimension 3

julia> sum([nvertices(F) for F in faces(T, 2)] .== 3)
8

julia> sum([nvertices(F) for F in faces(T, 2)] .== 4)
6

julia> nfacets(T)
14
```
"""
archimedean_solid(s::String) = Polyhedron(Polymake.polytope.archimedean_solid(s))


@doc Markdown.doc"""

    catalan_solid(s::String)

Construct a Catalan solid with the name `s` from the list
below.  The polytopes are realized with floating point coordinates and thus are not
exact. However, vertex-facet-incidences are correct in all cases.

# Arguments
- `s::String`: The name of the desired Archimedean solid.
    Possible values:
    - "triakis_tetrahedron" : Triakis Tetrahedron.
          Dual polytope to the Truncated Tetrahedron, made of 12 isosceles
          triangular facets.
    - "triakis_octahedron" : Triakis Octahedron.
          Dual polytope to the Truncated Cube, made of 24 isosceles triangular
          facets.
    - "rhombic_dodecahedron" : Rhombic dodecahedron.
          Dual polytope to the cuboctahedron, made of 12 rhombic facets.
    - "tetrakis_hexahedron" : Tetrakis hexahedron.
          Dual polytope to the truncated octahedron, made of 24 isosceles
          triangluar facets.
    - "disdyakis_dodecahedron" : Disdyakis dodecahedron.
          Dual polytope to the truncated cuboctahedron, made of 48 scalene
          triangular facets.
    - "pentagonal_icositetrahedron" : Pentagonal Icositetrahedron.
          Dual polytope to the snub cube, made of 24 irregular pentagonal facets.
          The vertices are realized as floating point numbers.
    - "pentagonal_hexecontahedron" : Pentagonal Hexecontahedron.
          Dual polytope to the snub dodecahedron, made of 60 irregular pentagonal
          facets. The vertices are realized as floating point numbers.
    - "rhombic_triacontahedron" : Rhombic triacontahedron.
          Dual polytope to the icosidodecahedron, made of 30 rhombic facets.
    - "triakis_icosahedron" : Triakis icosahedron.
          Dual polytope to the icosidodecahedron, made of 30 rhombic facets.
    - "deltoidal_icositetrahedron" : Deltoidal Icositetrahedron.
          Dual polytope to the rhombicubaoctahedron, made of 24 kite facets.
    - "pentakis_dodecahedron" : Pentakis dodecahedron.
          Dual polytope to the truncated icosahedron, made of 60 isosceles
          triangular facets.
    - "deltoidal_hexecontahedron" : Deltoidal hexecontahedron.
          Dual polytope to the rhombicosidodecahedron, made of 60 kite facets.
    - "disdyakis_triacontahedron" : Disdyakis triacontahedron.
          Dual polytope to the truncated icosidodecahedron, made of 120 scalene
          triangular facets.


# Examples
```jldoctest
julia> T = catalan_solid("triakis_tetrahedron");

julia> count(F -> nvertices(F) == 3, faces(T, 2))
12

julia> nfacets(T)
12
```
"""
catalan_solid(s::String) = Polyhedron(Polymake.polytope.catalan_solid(s))


@doc Markdown.doc"""

    upper_bound_f_vector(d::Int, n::Int)

Return the maximal f-vector of a `d`-polytope with `n` vertices;
this is given by McMullen's Upper-Bound-Theorem.
"""
upper_bound_f_vector(d::Int,n::Int) = Vector{Int}(Polymake.polytope.upper_bound_theorem(d,n).F_VECTOR)

@doc Markdown.doc"""

    upper_bound_g_vector(d::Int, n::Int)

Return the maximal g-vector of a `d`-polytope with `n` vertices;
this is given by McMullen's Upper-Bound-Theorem.
"""
upper_bound_g_vector(d::Int,n::Int) = Vector{Int}(Polymake.polytope.upper_bound_theorem(d,n).G_VECTOR)

@doc Markdown.doc"""

    upper_bound_h_vector(d::Int, n::Int)

Return the maximal h-vector of a `d`-polytope with `n` vertices;
this is given by McMullen's Upper-Bound-Theorem.
"""
upper_bound_h_vector(d::Int,n::Int) = Vector{Int}(Polymake.polytope.upper_bound_theorem(d,n).H_VECTOR)


@doc Markdown.doc"""
    polarize(P::Polyhedron)

Return the polar dual of the polyhedron `P`, consisting of all linear functions
whose evaluation on `P` does not exceed 1.

# Examples
```jldoctest
julia> square = cube(2)
A polyhedron in ambient dimension 2

julia> P = polarize(square)
A polyhedron in ambient dimension 2

julia> vertices(P)
4-element SubObjectIterator{PointVector{Polymake.Rational}}:
 [1, 0]
 [-1, 0]
 [0, 1]
 [0, -1]
```
"""
function polarize(P::Polyhedron)
    return Polyhedron(Polymake.polytope.polarize(pm_object(P)))
end


@doc Markdown.doc"""

    project_full(P::Polyhedron)

Project the polyhedron down such that it becomes full dimensional in the new
ambient space.

```jldoctest
julia> P = convex_hull([1 0 0; 0 0 0])
A polyhedron in ambient dimension 3

julia> isfulldimensional(P)
false

julia> p = project_full(P)
A polyhedron in ambient dimension 1

julia> isfulldimensional(p)
true
```
"""
project_full(P::Polyhedron) = Polyhedron(Polymake.polytope.project_full(pm_object(P)))



@doc Markdown.doc"""

    gelfand_tsetlin(lambda::AbstractVector)

Construct the Gelfand Tsetlin polytope indexed by a weakly decreasing vector `lambda`.

```jldoctest
julia> P = gelfand_tsetlin([5,3,2])
A polyhedron in ambient dimension 6

julia> isfulldimensional(P)
false

julia> p = project_full(P)
A polyhedron in ambient dimension 3

julia> isfulldimensional(p)
true

julia> volume(p)
3
```
"""
gelfand_tsetlin(lambda::AbstractVector) = Polyhedron(Polymake.polytope.gelfand_tsetlin(Vector{Rational}(lambda),projected=false))
