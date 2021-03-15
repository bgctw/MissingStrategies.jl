using MissingStrategies
using Test, Missings, SimpleTraits

# defining SimpleTraits inside @testset seems not to work
# need to define all before the first testset



xm = [1,2,missing]
x = [1,2]
xa = allowmissing(x)

function fident(x)
    @show x, typeof(x)
    x
end

freal_do(x::AbstractVector{<:Real}) = x
freal_do_withdefault(x::AbstractVector{<:Real}) = x
@handlemissings(freal_do, true, false)
@handlemissings(freal_do_withdefault, true, true)

@testset "handlemissings definedefault option" begin
    # cannot be executed twice: methods are defined afterwards
    @test freal_do(x) == x
    @test freal_do(xa, PassMissing()) == x
    @test_throws MethodError freal_do(xa)
    @test freal_do_withdefault(xa) == x
end    

freal_itr1(x::AbstractVector{<:Real}) = x
fany_itr1(x) = x 
@handlemissings(fany_itr1) # do not collect or define default method
@handlemissings(freal_itr1, true, true)

@testset "vectors 1" begin
    # cannot be executed twice: methods are defined afterwards
    @test freal_itr1(x) == x
    # original method returns eltype missing
    @test @inferred(fany_itr1(xa)) == xa
    @test isequal(@inferred(fany_itr1(xm)), xm)
    # calling with MissingStrategy returns nonmissing eltype
    @test @inferred fany_itr1(xa, PassMissing()) == x
    @test ismissing(@inferred(Vector{Int}, fany_itr1(xm, PassMissing())))
    @test @inferred collect(fany_itr1(xm, SkipMissing())) == x
    @test @inferred collect(fany_itr1(xm, ExactMissing())) == x
    # for freal need to collect and can define default method
    @test @inferred freal_itr1(xa) == x
    @test ismissing(@inferred(Vector{Int}, freal_itr1(xm, PassMissing())))
    @test ismissing(@inferred(Vector{Int}, freal_itr1(xm)))
    @test @inferred freal_itr1(xm, SkipMissing()) == x
    @test @inferred freal_itr1(xm, ExactMissing()) == x
end;

if !(@isdefined StrangeMissing)
    struct StrangeMissing <: HandleMissingStrategy end
end

@testset "additional strategy" begin
    @test @inferred freal_itr1(xm, StrangeMissing()) == x
end;

freal_gen1(x::AbstractVector{<:Real}) = x
fany_gen1(x) = x
@handlemissings(fany_gen1)
@handlemissings(freal_gen1, true, true)

@testset "generator 1" begin
    # cannot be executed twice: methods are defined afterwards
    #xg = typediter(eltype(x), 2*xi for xi in x)
    xg = (2*xi for xi in x)
    xgm = (2*xi for xi in xm)
    #does not work with xg directly, because eltype is Any
    xg = typediter(eltype(x), 2*xi for xi in x)
    xgm = typediter(eltype(xm), 2*xi for xi in xm)
    @test collect(fany_gen1(xg)) == 2*x
    @test isequal(collect(fany_gen1(xgm)), 2*xm)
    # calling with MissingStrategy returns nonmissing eltype
    @test ismissing(@inferred(Vector{Int}, fany_gen1(xgm, PassMissing())))
    @test @inferred collect(fany_gen1(xgm, SkipMissing())) == 2*x
    # realvector function
    @test ismissing(@inferred(Vector{Int}, freal_gen1(xgm, PassMissing())))
    @test ismissing(@inferred(Vector{Int}, freal_gen1(xgm)))
    @test @inferred(freal_gen1(xgm, SkipMissing())) == 2*x
end;

