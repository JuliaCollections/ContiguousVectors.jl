module ContiguousVectors

export ContiguousVector

"""
    ContiguousVector{T}()
    ContiguousVector{T}(collection)

A `ContiguousVector` is a Vector that guarantees that all elements are defined.

This has performance advantages for non-isbits eltypes, since julia doesn't need
to check for undefined values when indexing into the vector.
For isbits types, it guarantees against accidentally accessing uninitialized memory.

Otherwise, it matches a normal `Vector{T}`.
"""
struct ContiguousVector{T} <: AbstractVector{T}
    # Maintain the invariant that every element is defined
    v::Vector{T}
    ContiguousVector{T}() where T = new{T}(T[])
end

Base.size(v::ContiguousVector) = size(v.v)
Base.length(v::ContiguousVector) = length(v.v)
Base.push!(v::ContiguousVector, val) = push!(v.v, val)
Base.pop!(v::ContiguousVector) = pop!(v.v)
Base.@propagate_inbounds function Base.getindex(v::ContiguousVector{T}, i) where T
    @boundscheck checkbounds(v.v, i)
    return unsafe_load(reinterpret(Ptr{isbitstype(T) ? T : Any}, pointer(v.v)), i)
end
Base.@propagate_inbounds function Base.setindex!(v::ContiguousVector, val, i)
    return setindex!(v.v, val, i)
end
function Base.resize!(v::ContiguousVector, n::Integer, default)
    old_size = length(v)
    resize!(v.v, n)
    if n > old_size
        for i in old_size+1:n
            @inbounds v.v[i] = default
        end
    end
    v
end
function Base.iterate(v::ContiguousVector, i = 1)
    if i > length(v)
        return nothing
    end
    return (@inbounds(v[i]), i + 1)
end

# ---- Helper constructors ----

function ContiguousVector{T}(collection) where T
    out = ContiguousVector{T}()
    if Base.IteratorSize(collection) isa Base.SizeUnknown
        # We don't know how many elements there are, so we just push them on
        for x in collection
            push!(out.v, x)
        end
        return out
    else
        resize!(out.v, length(collection))
        for (i,x) in enumerate(collection)
            @inbounds out[i] = x
        end
        return out
    end
end

end  # module ContiguousVectors
