"""
Types supporting methods to deal with presence of missing values
in their inputs.
ted lognormal random variables
"""
module MissingStrategies

export 
    MissingStrategy, HandleMissingStrategy, PassMissing, SkipMissing, ExactMissing,
    TypedIterator, typediter


# MissingStrategy
include("typediterator.jl")
include("missingstrategy.jl")
    
end # module
