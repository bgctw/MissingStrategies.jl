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
    #@handlemissings2, @handlemissings1, @handlemissings_pos,
    @returnmissing,
    @handlemissings, @handlemissings_any, @handlemissings_typed,
    mgen


# MissingStrategy
include("typediterator.jl")
include("iseltypesuperofmissing.jl")
include("missingstrategy.jl")
include("mgen.jl")
include("handlemissings.jl")
#include("handlemissings2.jl")
include("returnmissing.jl")
    
end # module
