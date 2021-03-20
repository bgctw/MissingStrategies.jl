using MissingStrategies
using Test, Missings, SimpleTraits
using MacroTools: @expand

# defining SimpleTraits inside @testset seems not to work
# need to define all before the first testset



xm = [1,2,missing]  # wiht missing
x = [1,2]           # type not allowing for missing
xa = allowmissing(x) # type allowing for missing, but no missing present
xacomplex = allowmissing(xa.+0im) # complex argument (otherwise like xa)

freal_do(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0; 
    demean=false) = x

# @test_throws does not handle macro
# @test_throws ErrorException @handlemissings_typed(
#     fany_do(x, opt::AbstractVector{<:Real}=0.0:0.5:1.0) = x,
#     1,2,AbstractVector{<:Union{Missing,Real}},
# )

@handlemissings_typed(
    freal_do(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0; 
        demean=false) = x,
    1,2,AbstractVector{<:Union{Missing,<:Real}},
)

(
@expand @handlemissings_typed(
    freal_do(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0; 
        demean=false) = x,
    1,2,AbstractVector{<:Union{Missing,<:Real}},
    (mgen.passmissing_nonconvert, mgen.handlemissing_skip)
)
);

(
@expand @handlemissings(
    freal_do(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0) = x,
    1,2,AbstractVector{<:Union{Missing,<:Real}},
    (mgen.passmissing_nonconvert, mgen.handlemissing_skip)
)
);

@testset "handlemissings_typed" begin
    # original method
    @test @inferred freal_do(x) == x
    # missing value passmising
    @test ismissing(@inferred(typeof(x),freal_do(xm, PassMissing())))
    # missing type but no missings 
    @test @inferred(Missing, freal_do(xa, PassMissing())) == x
    # missing skipvalue - converted type
    @test @inferred freal_do(xm, SkipMissing(); demean=false) == x
    # nonmissing type with strategy
    @test @inferred(freal_do(x, PassMissing())) == x
    # missing type withoug strategy
    @test ismissing(@inferred(typeof(x), freal_do(xm; demean=false)))
    # not accepting complex numbers
    @test_throws MethodError freal_do(allowmissing(allowmissing([1,2].+0im)), SkipMissing())
end;

freal_do_nodef(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0; 
    demean=false) = x

@handlemissings_typed(
    freal_do_nodef(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0; 
        demean=false) = x,
    1,2,Any, nothing # default missing type set to nothing
)

@testset "handlemissings_typed omit default strategy" begin
    # original method
    @test @inferred freal_do_nodef(x) == x
    # missing value passmising
    @test ismissing(@inferred(typeof(x),freal_do_nodef(xm, PassMissing())))
    # missing type but no missings 
    @test @inferred(Missing, freal_do_nodef(xa, PassMissing())) == x
    # missing skipvalue - converted type
    @test @inferred freal_do_nodef(xm, SkipMissing(); demean=false) == x
    # nonmissing type with strategy
    @test @inferred(freal_do_nodef(x, PassMissing())) == x
    # ---- missing type withoug strategy
    @test_throws MethodError freal_do_nodef(xm; demean=false)
end;

fany_do(x, opt::AbstractVector{<:Real}=0.0:0.5:1.0; demean=false) = x
@handlemissings_any(
    fany_do(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0; 
        demean=false) = x,
)

@testset "handlemissings_any" begin
    # original method
    @test @inferred fany_do(x) == x
    # missing value passmising - here type is not converted
    @test ismissing(@inferred(typeof(xm),fany_do(xm, PassMissing())))
    # missing-type but no missings 
    @test @inferred(Missing, fany_do(xa, PassMissing())) == xa
    # missing skipvalue - not converted type (return type allows missings)
    @test @inferred fany_do(xm, SkipMissing(); demean=false) == skipmissing(xm)
    @test @inferred fany_do(xa, SkipMissing(); demean=false) == skipmissing(xa)
    # nonmissing type with strategy
    @test @inferred(fany_do(x, PassMissing())) == x
    # ---- missing type withoug strategy: matches original method
    @test isequal(fany_do(xm; demean=false), xm)
    # accepting complex numbers, but type converts to include missing
    @test @inferred fany_do(allowmissing(xacomplex), SkipMissing()) == 
        skipmissing(xacomplex)
end;


fany_do_withdefault(x, opt::AbstractVector{<:Real}=0.0:0.5:1.0; demean=false) = x




