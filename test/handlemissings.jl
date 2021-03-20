using MissingStrategies
using Test, Missings, SimpleTraits

# defining SimpleTraits inside @testset seems not to work
# need to define all before the first testset



xm = [1,2,missing]
x = [1,2]
xa = allowmissing(x)

freal_do(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0) = x
freal_do_withdefault(x::AbstractVector{<:Real}) = x
fany_do(x, opt::AbstractVector{<:Real}=0.0:0.5:1.0) = x
fany_do_withdefault(x, opt::AbstractVector{<:Real}=0.0:0.5:1.0) = x

@handlemissings_typed(
    freal_do(x::AbstractVector{<:Real}, opt::AbstractVector{<:Real}=0.0:0.5:1.0) = x,
    1,1,AbstractVector{<:Union{Missing,Real}}
)


