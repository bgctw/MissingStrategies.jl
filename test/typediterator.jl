using Test
using MissingStrategies
using Statistics

@testset "typediterator" begin

x = [1,2,missing]    
T = nonmissingtype(eltype(x))
itr = (coalesce(xi, zero(T)) for xi in x)
ti = MissingStrategies.typed_itr(itr,T)

end;

