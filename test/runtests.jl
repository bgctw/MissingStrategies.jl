using Test
using MissingStrategies 

# the warning cannot be suppressed, because the macros need to run at top-level

@testset "typediterator" begin
    include("typediterator.jl")
end

@testset "handlemissings" begin
    include("handlemissings.jl")
end


