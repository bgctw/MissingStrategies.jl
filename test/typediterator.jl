using Test
using MissingStrategies
using SimpleTraits
using Missings

# @traitfn does not work inside @testset
@traitfn fiseltypesuperofmissing(x::::IsEltypeSuperOfMissing) = true
@traitfn fiseltypesuperofmissing(x::::!(IsEltypeSuperOfMissing)) = false

@testset "TypedIterator" begin
    
@testset "IsEltypeSuperOfMissing trait" begin
    xm = [1,2,missing]    
    x = [1,2]
    @test @inferred fiseltypesuperofmissing(xm)
    @test @inferred !fiseltypesuperofmissing(skipmissing(xm))
    x = [1.0,0.5,3.0]
    @test !fiseltypesuperofmissing(x)
    @test fiseltypesuperofmissing(allowmissing(x))
    xgm = (2*xi for xi in xm)
    xg = (2*xi for xi in x)
    @test !fiseltypesuperofmissing(xg) # eltype Generator is any
end;

@testset "typediterator" begin
    # unfortunately not itegate (teste by for, IteratorSize and IteratorEltype not
    # recognized by CodeCov
    xm = [1,2,missing]    
    T = nonmissingtype(eltype(xm))
    itr = (coalesce(xi, zero(T)) for xi in xm)
    ti = typediter(T,itr)
    @test eltype(ti) === T
    #@test Base.IteratorSize(typeof(ti)) == Base.IteratorSize(typeof(itr))
    @test Base.IteratorSize(typeof(ti)) ∈ (Base.HasLength(), Base.HasShape{1}())
    @test Base.IteratorEltype(typeof(ti)) === Base.HasEltype()
    @test length(ti) == 3
    @test size(ti) == (3,)
end;

@testset "mgen trait" begin
    x = [1,2]
    xm = [1,2,missing]    
    xgm_nontyped = (2*xi for xi in xm)
    #does not work with xg directly, because eltype is Any
    @test !SimpleTraits.istrait(IsEltypeSuperOfMissing{Any})
    @test !SimpleTraits.istrait(IsEltypeSuperOfMissing{typeof(xgm_nontyped)})
    xg = typediter(eltype(x), 2*xi for xi in x)
    xgm = typediter(eltype(xm), 2*xi for xi in xm)
    @test SimpleTraits.istrait(IsEltypeSuperOfMissing{typeof(xgm)})
    @test !SimpleTraits.istrait(IsEltypeSuperOfMissing{typeof(xg)})
end


end; # TypedIterator

