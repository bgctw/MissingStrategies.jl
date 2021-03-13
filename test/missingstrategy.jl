using Test
using MissingStrategies
using Statistics

@testset "missingstrategy" begin

struct StrangeMissing <: HandleMissingStrategy end

function testmissingstrategy(x)
    mean(x), count(_->true,x)
end
function testmissingstrategy(x, ms::MissingStrategy)
    if Missing <: eltype(x)
        if ms === PassMissing() 
            any(ismissing.(x)) && return(missing)
        elseif ms === SkipMissing()
            xnm = skipmissing(x)
        else 
            #xnm = typediter(coalesce.(x, zero(FT)),FT)
            xnm = typediter((coalesce(xi, zero(nonmissingtype(eltype(x)))) for 
                xi in x),nonmissingtype(eltype(x)))
            #(coalesce(xi,zero(nonmissingtype(eltype(x)))) for xi in x)
        end
        testmissingstrategy(xnm)
    else
        testmissingstrategy(x)
    end
end


@testset "x without missings" begin
    x = [1,2]
    expected = mean(x),length(x)
    @test @inferred testmissingstrategy(x) == expected
    @test @inferred testmissingstrategy(x, PassMissing()) == expected
    @test @inferred testmissingstrategy(x, SkipMissing()) == expected
    @test @inferred testmissingstrategy(x, ExactMissing()) == expected
    @test @inferred testmissingstrategy(x, StrangeMissing()) == expected
end;

@testset "x with missings" begin
    xm = [1,2,missing]
    # @code_warntype testmissingstrategy(xm, PassMissing())
    # @code_warntype testmissingstrategy(xm, SkipMissing())
    # @code_warntype testmissingstrategy(xm, ExactMissing())
    # @code_lowered testmissingstrategy(xm, ExactMissing())
    # @code_typed testmissingstrategy(xm, ExactMissing())
    # @code_llvm testmissingstrategy(xm, ExactMissing())
    @test ismissing(@inferred(testmissingstrategy(xm, PassMissing())))
    @test @inferred testmissingstrategy(xm, SkipMissing()) == (1.5,2)
    @test @inferred testmissingstrategy(xm, ExactMissing()) == (1,3)
    @test @inferred testmissingstrategy(xm, StrangeMissing()) == (1,3)
end;

end;

