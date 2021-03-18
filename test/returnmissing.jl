using MissingStrategies
using Test

@testset "returnonmissing" begin
    f(x) = (y = @returnmissing(2*x); @info(y); 1)
    @test f(1) == 1
    @test ismissing(f(missing))
end;

