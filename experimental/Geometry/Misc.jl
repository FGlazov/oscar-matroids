module Misc

using Oscar

export add_variables, coeffs_in_radical

####################################################################
#  
#  Miscellaneous routines used in the above 
#
####################################################################


function add_variables( R::MPolyRing, new_vars::Vector{String} )
  k = base_ring(R)
  old_vars = String.( symbols(R) )
  n = length( old_vars )
  vars = vcat( old_vars, new_vars )
  S, v = PolynomialRing( k, vars )
  phi = AlgebraHomomorphism( R, S, gens(S)[1:n] )
  y = v[n+1:length(v)]
  return S, phi, y
end

##################################################################
#
# Checks whether some power of u is contained in the principal ideal 
# generated by g and returns a solution (k,a) of the equation 
#    u^k = a*g
# If no such solution exists, it returns `nothing`.
function coeffs_in_radical( g::MPolyElem, u::MPolyElem )
  k = Int(0);
  R = parent(g)
  parent(g) == parent(u) || error( "elements are not contained in the same ring!" )
  if !radical_membership( u, ideal( parent(g), g ) )
    return nothing
  end
  success=true
  a=zero(R)
  for k in (1:100) # Todo: replace by some infinite range eventually
    (success, a) = divides( g, u )
    if success
      break
    end
    u = u*u
  end
  return (2^k, a)
end

end # of module
