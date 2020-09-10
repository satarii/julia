# This file is a part of Julia. License is MIT: https://julialang.org/license

@testset "truncdfhf2" begin
    @test Runtime.__truncdfhf2(NaN) === NaN16
    @test Runtime.__truncdfhf2(Inf) === Inf16
    @test Runtime.__truncdfhf2(-Inf) === -Inf16
    @test Runtime.__truncdfhf2(0.0) === reinterpret(Float16, 0x0000)
    @test Runtime.__truncdfhf2(-0.0) === reinterpret(Float16, 0x8000)
    @test Runtime.__truncdfhf2(3.1415926535) === reinterpret(Float16, 0x4248)
    @test Runtime.__truncdfhf2(-3.1415926535) === reinterpret(Float16, 0xc248)
    @test Runtime.__truncdfhf2(0x1.987124876876324p+1000) === reinterpret(Float16, 0x7c00)
    @test Runtime.__truncdfhf2(0x1.987124876876324p+12) === reinterpret(Float16, 0x6e62)
    @test Runtime.__truncdfhf2(0x1.0p+0) === reinterpret(Float16, 0x3c00)
    @test Runtime.__truncdfhf2(0x1.0p-14) === reinterpret(Float16, 0x0400)
    # denormal
    @test Runtime.__truncdfhf2(0x1.0p-20) === reinterpret(Float16, 0x0010)
    @test Runtime.__truncdfhf2(0x1.0p-24) === reinterpret(Float16, 0x0001)
    @test Runtime.__truncdfhf2(-0x1.0p-24) === reinterpret(Float16, 0x8001)
    @test Runtime.__truncdfhf2(0x1.5p-25) === reinterpret(Float16, 0x0001)
    # and back to zero
    @test Runtime.__truncdfhf2(0x1.0p-25) === reinterpret(Float16, 0x0000)
    @test Runtime.__truncdfhf2(-0x1.0p-25) === reinterpret(Float16, 0x8000)
    # max (precise)
    @test Runtime.__truncdfhf2(65504.0) === reinterpret(Float16, 0x7bff)
    # max (rounded)
    @test Runtime.__truncdfhf2(65519.0) === reinterpret(Float16, 0x7bff)
    # max (to +inf)
    @test Runtime.__truncdfhf2(65520.0) === reinterpret(Float16, 0x7c00)
    @test Runtime.__truncdfhf2(-65520.0) === reinterpret(Float16, 0xfc00)
    @test Runtime.__truncdfhf2(65536.0) === reinterpret(Float16, 0x7c00)
end

@testset "truncsfhf2" begin
    # NaN
    @test Runtime.__truncsfhf2(NaN32) === reinterpret(Float16, 0x7e00)
    # inf
    @test Runtime.__truncsfhf2(Inf32) === reinterpret(Float16, 0x7c00)
    @test Runtime.__truncsfhf2(-Inf32) === reinterpret(Float16, 0xfc00)
    # zero
    @test Runtime.__truncsfhf2(0.0f0) === reinterpret(Float16, 0x0000)
    @test Runtime.__truncsfhf2(-0.0f0) === reinterpret(Float16, 0x8000)
    @test Runtime.__truncsfhf2(3.1415926535f0) === reinterpret(Float16, 0x4248)
    @test Runtime.__truncsfhf2(-3.1415926535f0) === reinterpret(Float16, 0xc248)
    @test Runtime.__truncsfhf2(Float32(0x1.987124876876324p+100)) === reinterpret(Float16, 0x7c00)
    @test Runtime.__truncsfhf2(Float32(0x1.987124876876324p+12)) === reinterpret(Float16, 0x6e62)
    @test Runtime.__truncsfhf2(Float32(0x1.0p+0)) === reinterpret(Float16, 0x3c00)
    @test Runtime.__truncsfhf2(Float32(0x1.0p-14)) === reinterpret(Float16, 0x0400)
    # denormal
    @test Runtime.__truncsfhf2(Float32(0x1.0p-20)) === reinterpret(Float16, 0x0010)
    @test Runtime.__truncsfhf2(Float32(0x1.0p-24)) === reinterpret(Float16, 0x0001)
    @test Runtime.__truncsfhf2(Float32(-0x1.0p-24)) === reinterpret(Float16, 0x8001)
    @test Runtime.__truncsfhf2(Float32(0x1.5p-25)) === reinterpret(Float16, 0x0001)
    # and back to zero
    @test Runtime.__truncsfhf2(Float32(0x1.0p-25)) === reinterpret(Float16, 0x0000)
    @test Runtime.__truncsfhf2(Float32(-0x1.0p-25)) === reinterpret(Float16, 0x8000)
    # max (precise)
    @test Runtime.__truncsfhf2(65504.0f0) === reinterpret(Float16, 0x7bff)
    # max (rounded)
    @test Runtime.__truncsfhf2(65519.0f0) === reinterpret(Float16, 0x7bff)
    # max (to +inf)
    @test Runtime.__truncsfhf2(65520.0f0) === reinterpret(Float16, 0x7c00)
    @test Runtime.__truncsfhf2(65536.0f0) === reinterpret(Float16, 0x7c00)
    @test Runtime.__truncsfhf2(-65520.0f0) === reinterpret(Float16, 0xfc00)
end

@testset "extendhfsf2" begin
    # These tests are taken fromt the compiler-rt testsuite. Were as of 3.9.0
    # the test are done with compareResultH (so with after casting to UInt16)
    # Tests that are marked broken fail as === Float32 comparisons.

    ##
    # NaN
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x7e00)) === NaN32
    # inf
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x7c00)) === Inf32
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0xfc00)) === -Inf32
    # zero
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x0000)) === 0.0f0
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x8000)) === -0.0f0
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x4248)) ≈ Float32(π)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0xc248)) ≈ Float32(-π)
    # @test Runtime.__extendhfsf2(reinterpret(Float16, 0x7c00)) === Float32(0x1.987124876876324p+100)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x6e62)) === Float32(0x1.988p+12)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x3c00)) === Float32(0x1.0p+0)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x0400)) === Float32(0x1.0p-14)
    # denormal
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x0010)) === Float32(0x1.0p-20)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x0001)) === Float32(0x1.0p-24)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x8001)) === Float32(-0x1.0p-24)
    @test_broken Runtime.__extendhfsf2(reinterpret(Float16, 0x0001)) === Float32(0x1.5p-25)
    # and back to zero
    # @test Runtime.__extendhfsf2(reinterpret(Float16, 0x0000)) === Float32(0x1.0p-25)
    # @test Runtime.__extendhfsf2(reinterpret(Float16, 0x8000)) === Float32(-0x1.0p-25)
    # max (precise)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x7bff)) === 65504.0f0
    # max (rounded)
    @test Runtime.__extendhfsf2(reinterpret(Float16, 0x7bff)) === 65504.0f0
end
