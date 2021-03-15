
typediter(::Type{ET},iter::IT) where {IT,ET} = TypedIterator{IT,ET}(iter)
struct TypedIterator{IT,ET}
  iter::IT
end
Base.eltype(::Type{TypedIterator{IT,ET}}) where {IT,ET} = ET
Base.IteratorSize(::Type{TypedIterator{IT}}) where IT = IteratorSize(IT)
Base.IteratorEltype(::Type{TypedIterator{IT}}) where {IT} = IteratorEltype(IT)

Base.iterate(iter::TypedIterator, state...) = iterate(iter.iter, state...)
Base.length(iter::TypedIterator{IT}) where {IT} = length(iter.iter)
Base.size(iter::TypedIterator{IT}, dims...) where {IT} = size(iter.iter, dims...)

