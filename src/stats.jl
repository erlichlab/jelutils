
ϕ(x) = filter(isfinite, skipmissing(x))

abslog(x) = sign(x)*log(abs(x))
std(x) = std(x, mean(x))
std(x,μ) = √sum((x.-μ).^2)
nanstd(x) = (z -> std(z, mean(z)))(ϕ(x))

stderr(x) = std(x)/√length(x)
nanstderr(x) = stderr(ϕ(x))

nanmean(x) = mean(ϕ(x))

bootci(x,F;α=0.05, boots=1000) = begin
    out = map(z->F(rand(x,length(x))), 1:boots)
    quantile(out, [α/2, 1-α/2])

end

binoci(x, α) = begin
    n = length(x)
    B = Binomial(n, sum(x)/n)
    map(z -> invlogcdf(B, log(z)), [α/2, 1-α/2])./n
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

binnedbino(x,y, bins, μ, Ε) = begin
    h = fit(Histogram, x, bins)
    #@show h
    ox = (bins[1:end-1] + bins[2:end])/2
    xmap = StatsBase.binindex.(Ref(h), x)
    #@show xmap
    oy = [sum(z.==xmap) > 0 ? μ(y[z.==xmap]) : NaN for z in 1:length(ox)]
    oe = [sum(z.==xmap) > 0 ? Ε(y[z.==xmap]) : [NaN, NaN] for z in 1:length(ox)]
    # This returns a long list of 2-tuples, but we want a 2-tuple of vectors
    (ox, oy, 	(oy .- (x->x[1]).(oe), (x->x[2]).(oe) .- oy))
end

binned(x,y, bins, μ, Ε) = begin
    h = fit(Histogram, x, bins)
    #@show h
    ox = (bins[1:end-1] + bins[2:end])/2
    xmap = StatsBase.binindex.(Ref(h), x)
    #@show xmap
    oy = [sum(z.==xmap) > 0 ? μ(y[z.==xmap]) : NaN for z in 1:length(ox)]
    oe = [sum(z.==xmap) > 0 ? Ε(y[z.==xmap]) : [NaN, NaN] for z in 1:length(ox)]
    # This returns a long list of 2-tuples, but we want a 2-tuple of vectors
    (ox, oy, 	(oy .- (x->x[1]).(oe), (x->x[2]).(oe) .- oy))
end

binned(x,y, bins) = begin
    if (eltype(y) == Bool) || all(in.(y, Ref([0,1])))
        binnedbino(x,y .+ 0.0,bins, nanmean, nanbinoci)
    else
        @show "raw"
        binned(x,y,bins, nanmean, x->(nanmean(x) - nanstderr(x),nanstderr(x)))
    end
end

lrt(m1, m2) = begin
    if dof(m1) > dof(m2)
        redM = m2; M = m1;
    elseif dof(m1) < dof(m2)
        redM = m1; M = m2;
    else
        error("Same dof. These are not nested models")
    end
    λ = -2(loglikelihood(redM)- loglikelihood(M))
    Χ=Distributions.Chisq(dof(M) - dof(redM));
    d = [Symbol(f)=>f(x) for x in [M, redM], f in [loglikelihood, aic, bic, dof]]
    1 - cdf(Χ, λ)
    df = DataFrame(map(Dict, eachrow(d)))
    df.p = [1 - cdf(Χ, λ), NaN]
    df
end
