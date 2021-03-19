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
#@handlemissings(autocor)
@handlemissings(autocor, true, false)
autocor(xm) # not defined 
x1 = autocor([1,2])
@handlemissings(autocor, true)
autocor(xm)

using MacroTools
x = x = 1.0:0.5:2.0

@expand @m2(
    f1(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    1
)

@m2(
    f1(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    1
)
f1(x, PassMissing())
