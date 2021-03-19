using MissingStrategies
using SimpleTraits

# @check_fast_traitdispatch erris with code coverage, hence do not include in Test suite
SimpleTraits.istrait(IsEltypeSuperOfMissing{typeof([1,2,missing])})
@check_fast_traitdispatch IsEltypeSuperOfMissing typeof([1,2,missing])
SimpleTraits.istrait(IsEltypeSuperOfMissing{typeof([1,2])})
@check_fast_traitdispatch IsEltypeSuperOfMissing typeof([1,2])
SimpleTraits.istrait(IsEltypeSuperOfMissing{Integer})
@check_fast_traitdispatch IsEltypeSuperOfMissing Int
x = [1,2,missing]
ti = typediter(eltype(x), (xi for xi in x))
SimpleTraits.istrait(IsEltypeSuperOfMissing{typeof(ti)})
@check_fast_traitdispatch IsEltypeSuperOfMissing typeof(ti)


