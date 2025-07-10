using ContiguousVectors
using Test

@testset "ContiguousVectors.jl" begin
@testset "empty vector" begin
    v = ContiguousVector{Int}()
    @test size(v) == (0,)
    @test length(v) == 0
    @test iterate(v) === nothing
end

@testset "resize" begin
    v = ContiguousVector{Int}()
    resize!(v, 10, -1)
    @test size(v) == (10,)
    @test length(v) == 10
    @test iterate(v) !== nothing
    @test iterate(v) == (-1, 2)
    @test collect(v) == fill(-1, 10)

    append!(v, [1,2,3])
    @test length(v) == 13

    v = ContiguousVector{Int}()
    append!(v, [1,2,3], [4,5,6])
    @test length(v) == 6
    # Test SizeUnknown iterator:
    append!(v, (x for x in 1:10 if isodd(x)))
    @test length(v) == 11
end
@testset "getindex" begin
    v = ContiguousVector{Int}()
    append!(v, [1,2,3,4,5])
    @test v[1] == 1
    @test v[5] == 5
    @test_throws BoundsError v[6]
    @test_throws BoundsError v[0]
    @test_throws BoundsError v[-1]
    @test v[1:2] isa ContiguousVector
    @test v[1:2] == [1, 2]
end
@testset "setindex!" begin
    v = ContiguousVector{Int}()
    append!(v, [1,2,3,4,5])
    v[1] = 10
    @test v[1] == 10
    @test_throws BoundsError (v[6] = 10)
end
@testset "Constructors" begin
    @test ContiguousVector{Int}() == Int[]
    @test ContiguousVector{Float64}([1, 2, 3]) == Float64[1.0, 2.0, 3.0]
    @test ContiguousVector{Float64}((1, 2, 3)) == Float64[1.0, 2.0, 3.0]
    @test ContiguousVector{Int}((x for x in 1:10 if isodd(x))) == [1, 3, 5, 7, 9]

    @test ContiguousVector{Vector{Int}}([]) == Vector{Int}[]
    @test ContiguousVector{Vector{Int}}([[]]) == Vector{Int}[[]]
end

end
