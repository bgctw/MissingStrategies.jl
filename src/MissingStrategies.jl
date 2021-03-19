"""
Support handling of missing values by
- a typed hierarchy of strategies of dealing with missings
- a trait that helps dispatching on eltype that allows missing
- a macro allowing to easily extend functions by methods that deal with missings
"""
module MissingStrategies
using SimpleTraits, MacroTools

export 
    MissingStrategy, HandleMissingStrategy, PassMissing, SkipMissing, ExactMissing,
    TypedIterator, typediter,
    IsSuperOfMissing, IsEltypeSuperOfMissing,
    @handlemissings, @handlemissings1, @handlemissings_pos,
    @returnmissing,
    @m2


# MissingStrategy
include("typediterator.jl")
include("iseltypesuperofmissing.jl")
include("missingstrategy.jl")
include("handlemissings.jl")
include("handlemissings_ext.jl")
include("returnmissing.jl")
    
end # module
