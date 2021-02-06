# Macro experiments

macro annotate2(x...)
    ps, ts, cs = string.(x)
    @show ps, ts, cs
end

macro title(x)
    return :()
end

macro varadd(x)
    return :( $(string(x)), $x )
end


macro xisx(x)
    return :( '"' $(string(x)), $x )
end

macro zerox2(x)
    show(x)
    return :($x = 0)
end

macro zerox()
    return esc(:(x = 0))
end