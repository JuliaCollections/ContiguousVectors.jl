module ContiguousVectors

export ContiguousVector
@static if VERSION >= v"1.11.0-DEV.469"
    eval(Meta.parse("public unsafe_resize!"))
end

# ----- API Functions ------

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

"""
    resize!(v::ContiguousVector, n::Integer, default) -> v

Resize a ContiguousVector to `n` elements, initializing any new elements to `default`.

If `n` is smaller than the current size, the vector is truncated.
If it is larger, all the new elements will be set to `default`.
"""
function Base.resize!(v::ContiguousVector, n::Integer, default)
    old_size = length(v)
    unsafe_resize!(v, n)
    if n > old_size
        for i in old_size+1:n
            @inbounds v.v[i] = default
        end
    end
    v
end

"""
    ContiguousVectors.unsafe_resize!(v::ContiguousVector, n::Integer) -> v

UNSAFE: resize the vector's underlying storage to `n` elements, without a default.

This is **unsafe** because it breaks the invariant that all elements are defined. If you
access a field that hasn't been initialized, you will get undefined behavior, and quite
likely segfaults. (The same as an out-of-bounds access in C/C++.)

You are strongly recommended to use `resize!(v, n, default)` instead. This function can
be used if you do not want to pay the cost of initializing the elements, and you will
immediately initiatilize them all to defined values.

# Example
```
    unsafe_resize!(v, 10)
    for i in 1:10
        v[i] = i
    end
```
"""
unsafe_resize!(v::ContiguousVector, n::Integer) = resize!(v.v, n)

# ----- Implementation --------

Base.size(v::ContiguousVector) = size(v.v)
Base.length(v::ContiguousVector) = length(v.v)
Base.push!(v::ContiguousVector, val) = push!(v.v, val)
Base.pop!(v::ContiguousVector) = pop!(v.v)
Base.@propagate_inbounds function Base.getindex(v::ContiguousVector{T}, i) where T
    @boundscheck checkbounds(v.v, i)
    return unsafe_load(reinterpret(Ptr{isbitstype(T) ? T : Any}, pointer(v.v)), i)
end
Base.@propagate_inbounds function Base.getindex(v::ContiguousVector, range::AbstractRange)
    @boundscheck checkbounds(v.v, range)
    out = ContiguousVector{eltype(v)}()
    unsafe_resize!(out, length(range))
    for (i, j) in enumerate(range)
        @inbounds out[i] = v[j]
    end
    return out
end
Base.@propagate_inbounds function Base.setindex!(v::ContiguousVector, val, i)
    return setindex!(v.v, val, i)
end
function Base.iterate(v::ContiguousVector, i = 1)
    if i > length(v)
        return nothing
    end
    return (@inbounds(v[i]), i + 1)
end
function Base.append!(v::ContiguousVector, collection)
    if Base.IteratorSize(collection) isa Base.SizeUnknown
        for x in collection
            push!(v.v, x)
        end
    else
        old_size = length(v)
        resize!(v.v, old_size + length(collection))
        for (i,x) in enumerate(collection)
            @inbounds v[old_size + i] = x
        end
    end
    return v
end

# ---- Helper constructors ----

function ContiguousVector{T}(collection) where T
    out = ContiguousVector{T}()
    return @inline append!(out, collection)
end

end  # module ContiguousVectors
