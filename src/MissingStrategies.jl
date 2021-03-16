"""
Support handling of missing values by
- a typed hierarchy of strategies of dealing with missings
- a trait that helps dispatching on eltype that allows missing
- a macro allowingn to easily extend functions by methods that deal with missings
"""
module MissingStrategies
using SimpleTraits

export 
    MissingStrategy, HandleMissingStrategy, PassMissing, SkipMissing, ExactMissing,
    TypedIterator, typediter,
    IsSuperOfMissing, IsEltypeSuperOfMissing,
    @handlemissings


# MissingStrategy
include("typediterator.jl")
include("iseltypesuperofmissing.jl")
include("missingstrategy.jl")
include("handlemissings.jl")
    
end # module
