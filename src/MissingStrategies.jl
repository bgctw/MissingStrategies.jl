"""
Types supporting methods to deal with presence of missing values
in their inputs.
ted lognormal random variables
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
include("missingstrategy.jl")
include("handlemissings.jl")
    
end # module
