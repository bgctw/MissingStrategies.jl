using MissingStrategies
using Test

@testset "returnmissing" begin
    f(x) = (y = @returnmissing(2*x); @info(y); 1)
    @test f(1) == 1
    @test ismissing(f(missing))
end;

# see also returnmissing_interactive.jl

