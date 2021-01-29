
ϕ(x) = filter(isfinite, skipmissing(x))

abslog(x) = sign(x)*log(abs(x))
std(x) = std(x, mean(x))
std(x,μ) = √sum((x.-μ).^2)
nanstd(x) = (z -> std(z, mean(z)))(ϕ(x))

stderr(x) = std(x)/√length(x)
nanstderr(x) = stderr(ϕ(x))

nanmean(x) = mean(ϕ(x))

binoci(x, α) = begin
    n = length(x)
    map(z -> invlogcdf(Binomial(n, sum(x)/n), log(z)), [α/2, 1-α/2])./n
end
binoci(x) = binoci(x, 0.05)
nanbinoci(x) = binoci(ϕ(x))
nanbinoci(x, α) = binoci(ϕ(x), α)

nanzscore(x) = begin
    out = copy(x)
    good = isfinite.(x) .& .!ismissing.(x)
    xg = x[good]
    out[good] = (xg .- mean(xg)) ./ std(xg)
    out
end

binned(x,y, bins, μ, Ε) = begin
    @show eltype(x), bins
    h = fit(Histogram, x, bins)
    @show h
    ox = (bins[1:end-1] + bins[2:end])/2
    xmap = StatsBase.binindex.(Ref(h), x)
    
    oy = [μ(y[z.==xmap]) for z in 1:maximum(xmap)]
    oe = [Ε(y[z.==xmap]) for z in 1:maximum(xmap)]
    (ox, oy, oe)
end
binned(x,y, bins) = begin
    if (eltype(y) == Bool) || all(in.(y, Ref([0,1])))
        @show "bool"
        binned(x,y .+ 0.0,bins, nanmean, nanbinoci)
    else
        @show "raw"
        binned(x,y,bins, nanmean, nanstderr)
    end
end