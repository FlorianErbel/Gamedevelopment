function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

function lerp(a, b, t)
    return a + (b - a) * t
end
