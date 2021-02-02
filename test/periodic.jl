@testset "periodic" begin
    @testset "$f" for f in (sin, cos)
        p = Periodic(f, 5, 2)

        @test p isa Transform

        @testset "Vector" begin
            x = 0.:10.
            expected = periodic_function.(2π / 5 .* x .+ 2)

            @test Transforms.apply(x, p) ≈ expected atol=1e-15
            @test p(x) ≈ expected atol=1e-15

            _x = copy(x)
            Transforms.apply!(_x, p)
            @test _x ≈ expected atol=1e-5
        end
    end
end
