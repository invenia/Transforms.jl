
"""
    Transform

Abstract supertype for all Transforms.
"""
abstract type Transform end

# Make Transforms callable types
(t::Transform)(x; kwargs...) = apply(x, t; kwargs...)


"""
    transform!(::T, data)

Defines the feature engineering pipeline for some type `T`, which comprises a collection of
[`Transform`](@ref)s to be peformed on the `data`.

`transform!` should be overloaded for custom types `T` that require feature engineering.
"""
function transform! end

"""
    transform(::T, data)

Non-mutating version of [`transform!`](@ref).
"""
function transform end

"""
    apply(data::T, ::Transform; kwargs...)

Applies the [`Transform`](@ref) to the data. New transforms should usually only extend
`_apply` which this method delegates to.

Where necessary, this should be extended for new data types `T`.
"""
function apply end

"""
    apply!(data::T, ::Transform; kwargs...) -> T

Applies the [`Transform`](@ref) mutating the input `data`. New transforms should usually
only extend `_apply!` which this method delegates to.

Where necessary, this should be extended for new data types `T`.
"""
function apply! end


"""
    apply(A::AbstractArray, ::Transform; dims=:, inds=:, kwargs...)

Applies the [`Transform`](@ref) to the elements of `A`.
Provide the `dims` keyword to apply the [`Transform`](@ref) along a certain dimension.
Provide the `inds` keyword to apply the [`Transform`](@ref) to certain indices along the
`dims` specified.

Note: if `dims === :` (all dimensions), then `inds` will be the global indices of the array,
instead of being relative to a certain dimension.

This method does not guarantee the data type of what is returned. It will try to conserve
type but the returned type depends on what the original `A` was, and the `dims` and `inds`
specified.
"""
function apply(A::AbstractArray, t::Transform; dims=:, inds=:, kwargs...)
    if dims === Colon()
        if inds === Colon()
            return _apply(A, t; kwargs...)
        else
            return _apply(A[:][inds], t; kwargs...)
        end
    end

    return mapslices(x -> _apply(x[inds], t; kwargs...), A, dims=dims)
end

"""
    apply(table, ::Transform; cols=nothing, kwargs...) -> Vector

Applies the [`Transform`](@ref) to each of the specified columns in the `table`.
If no `cols` are specified, then the [`Transform`](@ref) is applied to all columns.

Returns an array containing each transformed column, in the same order as `cols`.
"""
function apply(table, t::Transform; cols=nothing, kwargs...)
    Tables.istable(table) || throw(MethodError(apply, (table, t)))

    # Extract a columns iterator that we should be able to use to mutate the data.
    # NOTE: Mutation is not guaranteed for all table types, but it avoid copying the data
    columntable = Tables.columns(table)

    cnames = cols === nothing ? propertynames(columntable) : cols
    return [_apply(getproperty(columntable, cname), t; kwargs...)  for cname in cnames]
end

_apply(x, t::Transform; kwargs...) = _apply!(_try_copy(x), t; kwargs...)


"""
    apply!(A::AbstractArray, ::Transform; dims=:, kwargs...)

Applies the [`Transform`](@ref) to each element of `A`.
Optionally specify the `dims` to apply the [`Transform`](@ref) along certain dimensions.
"""
function apply!(A::AbstractArray, t::Transform; dims=:, kwargs...)
    dims == Colon() && return _apply!(A, t; kwargs...)

    for x in eachslice(A; dims=dims)
        _apply!(x, t; kwargs...)
    end

    return A
end

"""
    apply!(table::T, ::Transform; cols=nothing)::T where T

Applies the [`Transform`](@ref) to each of the specified columns in the `table`.
If no `cols` are specified, then the [`Transform`](@ref) is applied to all columns.
"""
function apply!(table::T, t::Transform; cols=nothing)::T where T
    # TODO: We could probably handle iterators of tables here
    Tables.istable(table) || throw(MethodError(apply!, (table, t)))

    # Extract a columns iterator that we should be able to use to mutate the data.
    # NOTE: Mutation is not guaranteed for all table types, but it avoid copying the data
    columntable = Tables.columns(table)

    cnames = cols === nothing ? propertynames(columntable) : cols
    for cname in cnames
        apply!(getproperty(columntable, cname), t)
    end

    return table
end
