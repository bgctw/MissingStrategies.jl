using MissingStrategies
using Test, Missings, SimpleTraits

# defining SimpleTraits inside @testset seems not to work
# need to define all before the first testset



xm = [1,2,missing]
x = [1,2]
xa = allowmissing(x)

f1real_do(x::AbstractVector{<:Real}) = x
f1real_do_withdefault(x::AbstractVector{<:Real}) = x
@handlemissings1(f1real_do, true, false)
@handlemissings1(f1real_do_withdefault, true, true)

@testset "hm1 - handlemissings definedefault" begin
    @test f1real_do(x) == x
    @test f1real_do(PassMissing(), xa) == x
    @test_throws MethodError f1real_do(xa)
    @test f1real_do_withdefault(xa) == x
end    

f1real_itr1(x::AbstractVector{<:Real}) = x
f1any_itr1(x) = x 
@handlemissings1(f1any_itr1) # do not collect or define default method
@handlemissings1(f1real_itr1, true, true)

@testset "hm1 - vectors 1" begin
    # cannot be executed twice: methods are defined afterwards
    @test f1real_itr1(x) == x
    # original method returns eltype missing
    @test @inferred(f1any_itr1(xa)) == xa
    @test isequal(@inferred(f1any_itr1(xm)), xm)
    # calling with MissingStrategy returns nonmissing eltype
    @test @inferred f1any_itr1(PassMissing(), xa) == x
    @test ismissing(@inferred(Vector{Int}, f1any_itr1(PassMissing(), xm)))
    @test @inferred collect(f1any_itr1(SkipMissing(), xm)) == x
    @test @inferred collect(f1any_itr1(ExactMissing(), xm)) == x
    # for freal need to collect and can define default method
    @test @inferred f1real_itr1(xa) == x
    @test ismissing(@inferred(Vector{Int}, f1real_itr1(PassMissing(), xm)))
    @test ismissing(@inferred(Vector{Int}, f1real_itr1(xm)))
    @test @inferred f1real_itr1(SkipMissing(), xm) == x
    @test @inferred f1real_itr1(ExactMissing(), xm) == x
end;

if !(@isdefined StrangeMissing)
    struct StrangeMissing <: HandleMissingStrategy end
end

@testset "hm1 - additional strategy" begin
    @test @inferred f1real_itr1(StrangeMissing(), xm) == x
end;

f1real_gen1(x::AbstractVector{<:Real}) = x
f1any_gen1(x) = x
@handlemissings1(f1any_gen1)
@handlemissings1(f1real_gen1, true, true)

@testset "hm1 - generator 1" begin
    # cannot be executed twice: methods are defined afterwards
    #xg = typediter(eltype(x), 2*xi for xi in x)
    xg = (2*xi for xi in x)
    xgm = (2*xi for xi in xm)
    #does not work with xg directly, because eltype is Any
    xg = typediter(eltype(x), 2*xi for xi in x)
    xgm = typediter(eltype(xm), 2*xi for xi in xm)
    @test collect(f1any_gen1(xg)) == 2*x
    @test isequal(collect(f1any_gen1(xgm)), 2*xm)
    # calling with MissingStrategy returns nonmissing eltype
    @test ismissing(@inferred(Vector{Int}, f1any_gen1(PassMissing(), xgm)))
    @test @inferred collect(f1any_gen1(SkipMissing(), xgm)) == 2*x
    # realvector function
    @test ismissing(@inferred(Vector{Int}, f1real_gen1(PassMissing(), xgm)))
    @test ismissing(@inferred(Vector{Int}, f1real_gen1(xgm)))
    @test @inferred(f1real_gen1(SkipMissing(), xgm)) == 2*x
end;

f1any_gen2(x) = x
@handlemissings1(f1any_gen2, false, true) # default method

@testset "hm1 - generator 2" begin
    xg = (2*xi for xi in x)
    xgm = (2*xi for xi in xm)
    #does not work with xg directly, because eltype is Any
    xg = typediter(eltype(x), 2*xi for xi in x)
    xgm = typediter(eltype(xm), 2*xi for xi in xm)
    @test collect(f1any_gen2(xg)) == 2*x
    @test isequal(collect(f1any_gen2(xgm)), 2*xm) # still calls original method
    # calling with MissingStrategy returns nonmissing eltype
    @test ismissing(@inferred(Vector{Int}, f1any_gen2(PassMissing(), xgm)))
    @test !ismissing(@inferred(Vector{Int}, f1any_gen2(xgm))) # calls original method
end;


