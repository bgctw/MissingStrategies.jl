using MissingStrategies

function effective_n_cor(x, acf::AbstractVector, ms::MissingStrategy=PassMissing())
    ms === PassMissing() && Missing <: eltype(x) && any(ismissing.(x)) && return(missing)
    n = length(x)
    k = Base.OneTo(min(n,length(acf))-1) # acf starts with lag 0
    if ms === ExactMissing() && (Missing <: eltype(x))
        # count the number of pairs with missings for each lag
        mk = count_forlags((x_i,x_iplusk)->ismissing(x_i) || ismissing(x_iplusk), x, k)
        nf = n - count(ismissing.(x))
        neff = nf/(1 + 2/nf*sum((n .- k .-mk) .* acf[k.+1]))  
    else
        neff = n/(1 + 2/n*sum((n .- k) .* acf[k.+1]))  
    end
end

autocor(xm, SkipMissing())
autocor(xm, ExactMissing())
autocor(xm, PassMissing())
autocor(allowmissing(x))
autocor(x)
autocor(xm)
StatsBase.autocor(xm) # overwritten


xm = [1,2,missing]
x = [1,2]
using Missings, MissingStrategies, StatsBase
import StatsBase: autocor
#@handlemissings2(autocor)
@handlemissings2(autocor, true, false)
autocor(xm) # not defined 
x1 = autocor([1,2])
@handlemissings2(autocor, true)
autocor(xm)

using MacroTools
x = [1.0,2.0,missing]

function f10(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true)
    @info "original method with Vector(Real)"
    @show x,typeof(x),lags,demean
    x
end

@expand @handlemissings(
    f10(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    #f10(x::AbstractVector{<:Real}; demean=true) = 1,
    1,2,AbstractVector{<:Union{Missing,Real}},
    (mgen.missingstrategy_nonsuperofeltype, mgen.passmissing_convert, mgen.handlemissing_collect_skip),
    PassMissing(),
)


@handlemissings(
    f10(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    #f10(x::AbstractVector{<:Real}; demean=true) = 1,
    1,2,AbstractVector{<:Union{Missing,Real}},
    (mgen.passmissing_convert, mgen.handlemissing_collect_skip),
    PassMissing(),
)



#methods(f10_hm100)
f10_hm100(PassMissing(), x)
f10(x, PassMissing())
f10(x[1:2], PassMissing())
f10_hm100(SkipMissing(), x)
f10(x, SkipMissing(); demean=false)
f10([1.,2], PassMissing())
f10(x; demean=false)

args = [1,2,3]
pos_strategy = 1
args[1:(pos_strategy-1)],args[(pos_strategy+1):end]
pos_strategy = 2
args[1:(pos_strategy-1)],args[(pos_strategy+1):end]
pos_strategy = 3
args[1:(pos_strategy-1)],args[(pos_strategy+1):end]


using Test
macro retestset1(fdisp1)
    :(@testset$(Expr(fdisp1.head,esc.(fdisp1.args)...)))
end
@retestset1 begin
    @test 1 == 1.0
end

ftemp(x) = x
macro m2(sym=:asymbol)
    quote
        # ftemp($(esc(sym))) # prevents only from hygene substitution
        ftemp($(QuoteNode(sym)))
    end
end
@m2


  
  

