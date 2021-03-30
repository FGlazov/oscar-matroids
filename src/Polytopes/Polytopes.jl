
import Markdown
import Base: ==

const AnyVecOrMat = Union{MatElem, AbstractVecOrMat}

export Cone,
    Points,
    PolyhedralFan,
    Polyhedra,
    Polyhedron,
    Halfspaces,
    IncidenceMatrix,
    LinearProgram,
    archimedean_solid,
    ambient_dim,
    codim,
    combinatorial_symmetries,
    convex_hull,
    cross,
    cube,
    dim,
    faces,
    facets,
    facets_as_halfspace_matrix_pair,
    facets_as_point_matrix,
    face_fan,
    feasible_region,
    f_vector,
    hilbert_basis,
    intersect,
    isbounded,
    iscomplete,
    isfeasible,
    isfulldimensional,
    isnormal,
    ispointed,
    isregular,
    issmooth,
    lattice_points,
    lineality_space,
    linear_symmetries,
    load_cone,
    load_polyhedralfan,
    load_polyhedron,
    maximal_cones,
    maximal_cones_as_incidence_matrix,
    maximal_value,
    maximal_vertex,
    minimal_value,
    minimal_vertex,
    minkowski_sum,
    newton_polytope,
    normalized_volume,
    normal_fan,
    nfacets,
    nmaximal_cones,
    nrays,
    nvertices,
    objective_function,
    orbit_polytope,
    recession_cone,
    save_cone,
    save_polyhedralfan,
    save_polyhedron,
    simplex,
    solve_lp,
    support_function,
    positive_hull,
    rays,
    rays_as_point_matrix,
    vertices,
    vertices_as_point_matrix,
    vf_group,
    visual,
    volume

include("helpers.jl")
include("Cone/constructors.jl")
include("Cone/properties.jl")
include("Polyhedron/constructors.jl")
include("Polyhedron/properties.jl")
include("Polyhedron/standard_constructions.jl")
include("LinearProgram.jl")
include("PolyhedralFan.jl")
include("Groups.jl")
include("Serialization.jl")
