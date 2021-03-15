using Test
using MissingStrategies
using Statistics
using SimpleTraits
using Missings

@testset "IsEltypeSuperOfMissing trait" begin
    xm = [1,2,missing]    
    x = [1,2]
    @traitfn f1(x::::IsEltypeSuperOfMissing) = true
    @traitfn f1(x::::!(IsEltypeSuperOfMissing)) = false
    @test @inferred f1(xm)
    @test @inferred !f1(skipmissing(xm))
    x = [1.0,0.5,3.0]
    @test !f1(x)
    @test f1(allowmissing(x))
    xgm = (2*xi for xi in xm)
    xg = (2*xi for xi in x)
    @test f1(xg) # eltype Generator is any
end;

@testset "typediterator" begin
    xm = [1,2,missing]    
    T = nonmissingtype(eltype(x))
    itr = (coalesce(xi, zero(T)) for xi in xm)
    ti = MissingStrategies.typediter(itr,T)
    @test eltype(ti) === T
end;

