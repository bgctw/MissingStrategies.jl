"""
    typediter(::Type{ET},iter::IT)
    TypedIterator{IT,ET}

Construct a thin wrapper around iterator `IT` returning eltype `ET`.

# Examples
```jldoctest; output=false
using SimpleTraits
x = [1,2,missing]
@traitfn fm(x::::IsEltypeSuperOfMissing)  = count(ismissing.(x))

gen = (2*xi for xi in x)  
eltype(gen) == Any
#fm(gen)  # MethodError

gent = typediter(eltype(x), 2*xi for xi in x)
eltype(gent) == eltype(x)
fm(gent) == 1
# output
true
```
"""    
function typediter(::Type{ET},iter::IT) where {IT,ET} 
  TypedIterator{IT,ET}(iter)
end,
struct TypedIterator{IT,ET}
  iter::IT
end
Base.eltype(::Type{TypedIterator{IT,ET}}) where {IT,ET} = ET
Base.IteratorSize(::Type{TypedIterator{IT}}) where IT = IteratorSize(IT)
Base.IteratorEltype(::Type{TypedIterator{IT}}) where {IT} = IteratorEltype(IT)

Base.iterate(iter::TypedIterator, state...) = iterate(iter.iter, state...)
Base.length(iter::TypedIterator{IT}) where {IT} = length(iter.iter)
Base.size(iter::TypedIterator{IT}, dims...) where {IT} = size(iter.iter, dims...)

