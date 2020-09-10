# This file is a part of Julia. License is MIT: https://julialang.org/license

module Runtime

using Base: @ccallable


## Float16 intrinsics

# Float32 -> Float16 algorithm from:
#   "Fast Half Float Conversion" by Jeroen van der Zijp
#   ftp://ftp.fox-toolkit.org/pub/fasthalffloatconversion.pdf
#
# With adjustments for round-to-nearest, ties to even.
#
let _basetable = Vector{UInt16}(undef, 512),
    _shifttable = Vector{UInt8}(undef, 512)
    for i = 0:255
        e = i - 127
        if e < -25  # Very small numbers map to zero
            _basetable[i|0x000+1] = 0x0000
            _basetable[i|0x100+1] = 0x8000
            _shifttable[i|0x000+1] = 25
            _shifttable[i|0x100+1] = 25
        elseif e < -14  # Small numbers map to denorms
            _basetable[i|0x000+1] = 0x0000
            _basetable[i|0x100+1] = 0x8000
            _shifttable[i|0x000+1] = -e-1
            _shifttable[i|0x100+1] = -e-1
        elseif e <= 15  # Normal numbers just lose precision
            _basetable[i|0x000+1] = ((e+15)<<10)
            _basetable[i|0x100+1] = ((e+15)<<10) | 0x8000
            _shifttable[i|0x000+1] = 13
            _shifttable[i|0x100+1] = 13
        elseif e < 128  # Large numbers map to Infinity
            _basetable[i|0x000+1] = 0x7C00
            _basetable[i|0x100+1] = 0xFC00
            _shifttable[i|0x000+1] = 24
            _shifttable[i|0x100+1] = 24
        else  # Infinity and NaN's stay Infinity and NaN's
            _basetable[i|0x000+1] = 0x7C00
            _basetable[i|0x100+1] = 0xFC00
            _shifttable[i|0x000+1] = 13
            _shifttable[i|0x100+1] = 13
        end
    end
    global const shifttable = (_shifttable...,)
    global const basetable = (_basetable...,)
end

# truncation
function truncsfhf2(val::Float32)
    f = reinterpret(UInt32, val)
    if isnan(val)
        t = 0x8000 ⊻ (0x8000 & ((f >> 0x10) % UInt16))
        return reinterpret(Float16, t ⊻ ((f >> 0xd) % UInt16))
    end
    i = ((f & ~Base.significand_mask(Float32)) >> Base.significand_bits(Float32)) + 1
    @inbounds sh = shifttable[i]
    f &= Base.significand_mask(Float32)
    # If `val` is subnormal, the tables are set up to force the
    # result to 0, so the significand has an implicit `1` in the
    # cases we care about.
    f |= Base.significand_mask(Float32) + 0x1
    @inbounds h = (basetable[i] + (f >> sh) & Base.significand_mask(Float16)) % UInt16
    # round
    # NOTE: we maybe should ignore NaNs here, but the payload is
    # getting truncated anyway so "rounding" it might not matter
    nextbit = (f >> (sh-1)) & 1
    if nextbit != 0 && (h & 0x7C00) != 0x7C00
        # Round halfway to even or check lower  bits
        if h&1 == 1 || (f & ((1<<(sh-1))-1)) != 0
            h += UInt16(1)
        end
    end
    reinterpret(Float16, h)
end
@ccallable Float16 __truncsfhf2(val::Float32) = truncsfhf2(val)
@ccallable Float16 __gnu_f2h_ieee(val::Float32) = truncsfhf2(val)
@ccallable Float16 __truncdfhf2(x::Float64) = truncsfhf2(Float32(x))

# extension
function extendhfsf2(val::Float16)
    local ival::UInt32 = reinterpret(UInt16, val)
    local sign::UInt32 = (ival & 0x8000) >> 15
    local exp::UInt32  = (ival & 0x7c00) >> 10
    local sig::UInt32  = (ival & 0x3ff) >> 0
    local ret::UInt32

    if exp == 0
        if sig == 0
            sign = sign << 31
            ret = sign | exp | sig
        else
            n_bit = 1
            bit = 0x0200
            while (bit & sig) == 0
                n_bit = n_bit + 1
                bit = bit >> 1
            end
            sign = sign << 31
            exp = ((-14 - n_bit + 127) << 23) % UInt32
            sig = ((sig & (~bit)) << n_bit) << (23 - 10)
            ret = sign | exp | sig
        end
    elseif exp == 0x1f
        if sig == 0  # Inf
            if sign == 0
                ret = 0x7f800000
            else
                ret = 0xff800000
            end
        else  # NaN
            ret = 0x7fc00000 | (sign<<31) | (sig<<(23-10))
        end
    else
        sign = sign << 31
        exp  = ((exp - 15 + 127) << 23) % UInt32
        sig  = sig << (23 - 10)
        ret = sign | exp | sig
    end
    return reinterpret(Float32, ret)
end
@ccallable Float32 __extendhfsf2(val::Float16) = extendhfsf2(val)
@ccallable Float32 __gnu_h2f_ieee(val::Float16) = extendhfsf2(val)
@ccallable Float64 __extendhfdf2(x::Float16) = Float64(extendhfdf2(x))

end
