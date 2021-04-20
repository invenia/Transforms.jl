@testset "scaling" begin

    @testset "IdentityScaling" begin
        scaling = IdentityScaling()
        @test scaling isa Transform
        @test cardinality(scaling) == OneToOne()

        @testset "Arguments do nothing" begin
            @test IdentityScaling(123) == IdentityScaling()
            @test IdentityScaling([1, 2, 3]) == IdentityScaling()
        end

        @testset "Matrix" begin
            M = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            M_expected = [0.0 -0.5 0.5; 0.0 1.0 2.0]

           @test FeatureTransforms.apply(M, scaling) == M_expected

            @testset "Mutating" begin
                _M = copy(M)
                FeatureTransforms.apply!(_M, scaling)
                @test _M == M_expected
            end

            @testset "dims = $d" for d in (Colon(), 1, 2)
                @test FeatureTransforms.apply(M, scaling; dims=d) == M_expected
            end

            @testset "inds" begin
                @test FeatureTransforms.apply(M, scaling; inds=[2, 3]) == [0.0, -0.5]
                @test FeatureTransforms.apply(M, scaling; dims=:, inds=[2, 3]) == [0.0, -0.5]
                @test FeatureTransforms.apply(M, scaling; dims=1, inds=[2]) == [0.0 1.0 2.0]
                @test FeatureTransforms.apply(M, scaling; dims=2, inds=[2]) == reshape([-0.5; 1.0], 2, 1)
            end

            @testset "Inverse" begin
                @test FeatureTransforms.apply(M, scaling; inverse=true) == M_expected
            end

            @testset "apply_append" begin
                exp1 = cat(M, M_expected, dims=1)
                @test FeatureTransforms.apply_append(M, scaling, append_dim=1) == exp1
                exp2 = cat(M, M_expected, dims=2)
                @test FeatureTransforms.apply_append(M, scaling, append_dim=2) == exp2
                exp3 = cat(M, M_expected, dims=3)
                @test FeatureTransforms.apply_append(M, scaling, append_dim=3) == exp3
            end
        end

        @testset "AxisArray" begin
            M = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            A = AxisArray(M; foo=["a", "b"], bar=["x", "y", "z"])
            M_expected = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            A_expected = AxisArray(M_expected; foo=["a", "b"], bar=["x", "y", "z"])

            @test FeatureTransforms.apply(A, scaling) == A_expected

            @testset "Mutating" begin
                _A = copy(A)
                FeatureTransforms.apply!(_A, scaling)
                @test _A isa AxisArray
                @test _A == A_expected
            end

            @testset "dims = $d" for d in (Colon(), 1, 2)
                @test FeatureTransforms.apply(M, scaling; dims=d) == A_expected
            end

            @testset "inds" begin
                @test FeatureTransforms.apply(A, scaling; inds=[2, 3]) == [0.0, -0.5]
                @test FeatureTransforms.apply(A, scaling; dims=:, inds=[2, 3]) == [0.0, -0.5]
                @test FeatureTransforms.apply(A, scaling; dims=1, inds=[2]) == [0.0 1.0 2.0]
                @test FeatureTransforms.apply(A, scaling; dims=2, inds=[2]) == reshape([-0.5; 1.0], 2, 1)
            end

            @testset "Inverse" begin
                @test FeatureTransforms.apply(A, scaling; inverse=true) == A_expected
            end

            @testset "apply_append" begin
                # dims = 1, 2 give ArgumentError: Categorical axes must be unique
                exp3 = cat(M_expected, M_expected, dims=3)
                @test FeatureTransforms.apply_append(A, scaling, append_dim=3) == exp3
            end
        end

        @testset "AxisKey" begin
            M = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            A = KeyedArray(M; foo=["a", "b"], bar=["x", "y", "z"])
            M_expected = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            A_expected = KeyedArray(M_expected; foo=["a", "b"], bar=["x", "y", "z"])

            @test FeatureTransforms.apply(A, scaling) == A_expected

            @testset "Mutating" begin
                _A = copy(A)
                FeatureTransforms.apply!(_A, scaling)
                @test _A isa KeyedArray
                @test _A == A_expected
            end

            @testset "dims = $d" for d in (Colon(), 1, 2)
                @test FeatureTransforms.apply(M, scaling; dims=d) == A_expected
            end

            @testset "inds" begin
                @test FeatureTransforms.apply(A, scaling; inds=[2, 3]) == [0.0, -0.5]
                @test FeatureTransforms.apply(A, scaling; dims=:, inds=[2, 3]) == [0.0, -0.5]
                @test FeatureTransforms.apply(A, scaling; dims=1, inds=[2]) == [0.0 1.0 2.0]
                @test FeatureTransforms.apply(A, scaling; dims=2, inds=[2]) == reshape([-0.5; 1.0], 2, 1)
            end

            @testset "Inverse" begin
                @test FeatureTransforms.apply(A, scaling; inverse=true) == A_expected
            end

            @testset "apply_append" begin
                expected1 = KeyedArray(
                    vcat(M, M_expected), foo=["a", "b", "a", "b"], bar=["x", "y", "z"],
                )
                @test FeatureTransforms.apply_append(A, scaling, append_dim=:foo) == expected1

                expected2 = KeyedArray(
                    hcat(M, M_expected), foo=["a", "b"], bar=["x", "y", "z", "x", "y", "z"]
                )
                @test FeatureTransforms.apply_append(A, scaling, append_dim=:bar) == expected2
                expected3 = KeyedArray(
                    cat(M, M_expected, dims=3),
                    foo=["a", "b"],
                    bar=["x", "y", "z"],
                    baz=Base.OneTo(2),
                )
                @test FeatureTransforms.apply_append(A, scaling, append_dim=:baz) == expected3
            end
        end
    end

    @testset "MeanStdScaling" begin
        @testset "Constructor" begin
            M = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            nt = (a = [0.0, -0.5, 0.5], b = [1.0, 0.0, 2.0])

            @testset "simple" for x in (M, nt)
                x_copy = deepcopy(x)
                scaling = MeanStdScaling(x)
                @test cardinality(scaling) == OneToOne()
                @test scaling isa Transform
                @test x == x_copy  # data is not mutated
                # constructor uses all data by default
                @test scaling.μ == 0.5
                @test scaling.σ ≈ 0.89443 atol=1e-5
            end

            @testset "use certain slices to compute statistics" begin
                @testset "Array" begin
                    scaling = MeanStdScaling(M; dims=1, inds=[2])
                    @test scaling.μ == 1.0
                    @test scaling.σ == 1.0
                end

                @testset "Table" begin
                    scaling = MeanStdScaling(nt; cols=:a)
                    @test scaling.μ == 0.0
                    @test scaling.σ == 0.5
                end
            end
        end

        @testset "Matrix" begin
            M = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            M_expected = [-0.559017 -1.11803 0.0; -0.559017 0.559017 1.67705]

            @testset "Non-mutating" begin
                scaling = MeanStdScaling(M)
                @test FeatureTransforms.apply(M, scaling) ≈ M_expected atol=1e-5
                @test scaling(M) ≈ M_expected atol=1e-5

                # Test the transform was not mutating
                @test !isapprox(M, M_expected; atol=1e-5)
            end

            @testset "Mutating" begin
                scaling = MeanStdScaling(M)
                _M = copy(M)
                FeatureTransforms.apply!(_M, scaling)
                @test _M ≈ M_expected atol=1e-5
            end

            @testset "dims = :" begin
                scaling = MeanStdScaling(M; dims=:)
                @test FeatureTransforms.apply(M, scaling; dims=:) ≈ M_expected atol=1e-5
            end

            @testset "dims = 1" begin
                scaling = MeanStdScaling(M; dims=1)
                @test FeatureTransforms.apply(M, scaling; dims=1) ≈ M_expected atol=1e-5
            end

            @testset "dims = 2" begin
                scaling = MeanStdScaling(M; dims=2)
                @test FeatureTransforms.apply(M, scaling; dims=2) ≈ M_expected atol=1e-5
            end

            @testset "inds" begin
                scaling = MeanStdScaling(M)
                @test FeatureTransforms.apply(M, scaling; inds=[2, 3]) ≈ [-0.559017, -1.11803] atol=1e-5
                @test FeatureTransforms.apply(M, scaling; dims=:, inds=[2, 3]) ≈ [-0.559017, -1.11803] atol=1e-5

                scaling = MeanStdScaling(M; dims=1, inds=[2])
                @test FeatureTransforms.apply(M, scaling; dims=1, inds=[2]) ≈ [-1.0 0.0 1.0] atol=1e-5

                scaling = MeanStdScaling(M; dims=2, inds=[2])
                @test FeatureTransforms.apply(M, scaling; dims=2, inds=[2]) ≈ [-0.70711 0.70711]' atol=1e-5
            end

            @testset "Re-apply" begin
                scaling = MeanStdScaling(M; dims=2)
                new_M = [1.0 -2.0 -1.0; 0.5 0.0 0.5]
                @test M !== new_M
                # Expect scaling parameters to be fixed to the first data applied to
                expected_reapply = [0.559017 -2.79508 -1.67705; 0.0 -0.55901 0.0]
                @test FeatureTransforms.apply(new_M, scaling; dims=2) ≈ expected_reapply atol=1e-5
            end

            @testset "Inverse" begin
                scaling = MeanStdScaling(M)
                transformed = FeatureTransforms.apply(M, scaling)

                @test transformed ≈ M_expected atol=1e-5
                @test FeatureTransforms.apply(transformed, scaling; inverse=true) ≈ M atol=1e-5
            end

            @testset "apply_append" begin
                scaling = MeanStdScaling(M)
                exp1 = cat(M, M_expected, dims=1)
                @test FeatureTransforms.apply_append(M, scaling, append_dim=1) ≈ exp1 atol=1e-5
                exp2 = cat(M, M_expected, dims=2)
                @test FeatureTransforms.apply_append(M, scaling, append_dim=2) ≈ exp2 atol=1e-5
                exp3 = cat(M, M_expected, dims=3)
                @test FeatureTransforms.apply_append(M, scaling, append_dim=3) ≈ exp3 atol=1e-5
            end
        end

        @testset "AxisArray" begin
            M = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            A = AxisArray(M; foo=["a", "b"], bar=["x", "y", "z"])
            M_expected = [-0.559017 -1.11803 0.0; -0.559017 0.559017 1.67705]
            A_expected = AxisArray(M_expected; foo=["a", "b"], bar=["x", "y", "z"])

            @testset "Non-mutating" begin
                scaling = MeanStdScaling(A)
                @test FeatureTransforms.apply(A, scaling) ≈ A_expected atol=1e-5
                @test scaling(A) ≈ A_expected atol=1e-5

                # Test the transform was not mutating
                @test !isapprox(A, A_expected; atol=1e-5)
            end

            @testset "Mutating" begin
                scaling = MeanStdScaling(A)
                _A = copy(A)
                FeatureTransforms.apply!(_A, scaling)
                @test _A isa AxisArray
                @test _A ≈ A_expected atol=1e-5
            end

            @testset "dims = :" begin
                scaling = MeanStdScaling(A, dims=:)
                @test FeatureTransforms.apply(A, scaling; dims=:) ≈ A_expected atol=1e-5
            end

            @testset "dims = 1" begin
                scaling = MeanStdScaling(A; dims=1)
                @test FeatureTransforms.apply(A, scaling; dims=1) ≈ A_expected atol=1e-5
            end

            @testset "dims = 2" begin
                scaling = MeanStdScaling(A; dims=2)
                @test FeatureTransforms.apply(A, scaling; dims=2) ≈ A_expected atol=1e-5
            end

            @testset "inds" begin
                scaling = MeanStdScaling(A)
                @test FeatureTransforms.apply(A, scaling; inds=[2, 3]) ≈ [-0.559017, -1.11803] atol=1e-5
                @test FeatureTransforms.apply(A, scaling; dims=:, inds=[2, 3]) ≈ [-0.559017, -1.11803] atol=1e-5

                scaling = MeanStdScaling(A; dims=1, inds=[2])
                @test FeatureTransforms.apply(A, scaling; dims=1, inds=[2]) ≈ [-1.0 0.0 1.0] atol=1e-5

                scaling = MeanStdScaling(A; dims=2, inds=[2])
                @test FeatureTransforms.apply(A, scaling; dims=2, inds=[2]) ≈ [-0.70711 0.70711]' atol=1e-5
            end

            @testset "Re-apply" begin
                scaling = MeanStdScaling(A)
                FeatureTransforms.apply(A, scaling)

                M_new = [1.0 -2.0 -1.0; 0.5 0.0 0.5]
                A_new = AxisArray(M_new; foo=["a", "b"], bar=["x", "y", "z"])
                @test A_new != A

                # Expect scaling parameters to be fixed to the first data applied to
                expected_reapply = [0.559017 -2.79508 -1.67705; 0.0 -0.55901 0.0]
                @test FeatureTransforms.apply(A_new, scaling) ≈ expected_reapply atol=1e-5
            end

            @testset "Inverse" begin
                scaling = MeanStdScaling(A)
                transformed = FeatureTransforms.apply(A, scaling)

                @test transformed ≈ A_expected atol=1e-5
                @test FeatureTransforms.apply(transformed, scaling; inverse=true) ≈ A atol=1e-5
            end

            @testset "apply_append" begin
                scaling = MeanStdScaling(A)
                exp1 = cat(M, M_expected, dims=1)
                @test FeatureTransforms.apply_append(A, scaling, append_dim=1) ≈ exp1 atol=1e-5
                exp2 = cat(M, M_expected, dims=2)
                @test FeatureTransforms.apply_append(A, scaling, append_dim=2) ≈ exp2 atol=1e-5
                exp3 = cat(M, M_expected, dims=3)
                @test FeatureTransforms.apply_append(A, scaling, append_dim=3) ≈ exp3 atol=1e-5
            end
        end

        @testset "AxisKey" begin
            M = [0.0 -0.5 0.5; 0.0 1.0 2.0]
            A = KeyedArray(M; foo=["a", "b"], bar=["x", "y", "z"])
            M_expected = [-0.559017 -1.11803 0.0; -0.559017 0.559017 1.67705]
            A_expected = KeyedArray(M_expected; foo=["a", "b"], bar=["x", "y", "z"])

            @testset "Non-mutating" begin
                scaling = MeanStdScaling(A)
                @test FeatureTransforms.apply(A, scaling) ≈ A_expected atol=1e-5
                @test scaling(A) ≈ A_expected atol=1e-5

                # Test the transform was not mutating
                @test !isapprox(A, A_expected; atol=1e-5)
            end

            @testset "Mutating" begin
                scaling = MeanStdScaling(A)
                _A = copy(A)
                FeatureTransforms.apply!(_A, scaling)
                @test _A isa KeyedArray
                @test _A ≈ A_expected atol=1e-5
            end

            @testset "dims = $d" for d in (Colon(), 1, 2, :foo, :bar)
                scaling = MeanStdScaling(A, dims=d)
                @test FeatureTransforms.apply(A, scaling; dims=d) ≈ A_expected atol=1e-5
            end

            @testset "inds" begin
                scaling = MeanStdScaling(A)
                @test FeatureTransforms.apply(A, scaling; inds=[2, 3]) ≈ [-0.559017, -1.11803] atol=1e-5
                @test FeatureTransforms.apply(A, scaling; dims=:, inds=[2, 3]) ≈ [-0.559017, -1.11803] atol=1e-5

                @testset "dims=$d" for d in (1, :foo)
                    scaling = MeanStdScaling(A; dims=d, inds=[2])
                    @test isapprox(
                        FeatureTransforms.apply(A, scaling; dims=d, inds=[2]),
                        [-1.0 0.0 1.0],
                        atol=1e-5
                    )
                end

                @testset "dims=$d" for d in (2, :bar)
                    scaling = MeanStdScaling(A; dims=2, inds=[2])
                    @test isapprox(
                        FeatureTransforms.apply(A, scaling; dims=2, inds=[2]),
                        [-0.70711 0.70711]',
                        atol=1e-5
                    )
                end
            end

            @testset "Re-apply" begin
                scaling = MeanStdScaling(A; dims=2)
                FeatureTransforms.apply(A, scaling; dims=2)

                M_new = [1.0 -2.0 -1.0; 0.5 0.0 0.5]
                A_new = KeyedArray(M_new; foo=["a", "b"], bar=["x", "y", "z"])
                @test A_new != A

                # Expect scaling parameters to be fixed to the first data applied to
                expected_reapply = [0.559017 -2.79508 -1.67705; 0.0 -0.55901 0.0]
                @test FeatureTransforms.apply(A_new, scaling; dims=2) ≈ expected_reapply atol=1e-5
            end

            @testset "Inverse" begin
                scaling = MeanStdScaling(A)
                transformed = FeatureTransforms.apply(A, scaling)

                @test transformed ≈ A_expected atol=1e-5
                @test FeatureTransforms.apply(transformed, scaling; inverse=true) ≈ A atol=1e-5
            end

            @testset "apply_append" begin
                scaling = MeanStdScaling(A)
                exp1 = KeyedArray(
                    vcat(M, M_expected), foo=["a", "b", "a", "b"], bar=["x", "y", "z"],
                )
                @test FeatureTransforms.apply_append(A, scaling, append_dim=:foo) ≈ exp1 atol=1e-5

                exp2 = KeyedArray(
                    hcat(M, M_expected), foo=["a", "b"], bar=["x", "y", "z", "x", "y", "z"]
                )
                @test FeatureTransforms.apply_append(A, scaling, append_dim=:bar) ≈ exp2 atol=1e-5

                exp3 = KeyedArray(
                    cat(M, M_expected, dims=3),
                    foo=["a", "b"],
                    bar=["x", "y", "z"],
                    baz=Base.OneTo(2),
                )
                @test FeatureTransforms.apply_append(A, scaling, append_dim=:baz) ≈ exp3 atol=1e-5
            end
        end

        @testset "Zero std" begin
            x = ones(Float64, 3)
            expected = zeros(Float64, 3)

            scaling = MeanStdScaling(x)

            @test FeatureTransforms.apply(x, scaling) == expected  # default `eps`
            @test FeatureTransforms.apply(x, scaling; eps=1) == expected
            @test all(isnan.(FeatureTransforms.apply(x, scaling; eps=0)))  # 0/0
        end
    end
end
