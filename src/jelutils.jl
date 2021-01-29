module jelutils

    using MAT
    using DataFrames
	using Distributions
	using StatsBase


    git_root() = strip(read(`git rev-parse --show-toplevel`, String))
    git_root(x) = git_root() * x
	read2df(csv) = begin
		
				CSV.read(git_root() * csv, DataFrame)
		end

    matfiles = filter(x->(endswith(x,".mat")),readdir(git_root("/../data/features/")))
	load_mat(x) = MAT.matread(x)
    load_file_by_index(x) = MAT.matread(git_root("/../data/features/") * matfiles[x])
	load_file_by_sessid(x) = begin
		this_file = filter(z->(startswith(z,"$(x)")), matfiles)
		MAT.matread(git_root("/../data/features/") * this_file[1])
		end
	restructure(feature_dict) = begin
        sessinfo = Dict(
					Symbol(k)=>v for (k,v) in feature_dict["meta"] if length(v) == 1
				)
        meta = DataFrame(Dict(
					Symbol(k)=>v[:] for (k,v) in feature_dict["meta"] if length(v) > 1
				))
        data = Dict(
					Symbol(k)=>v for (k,v) in feature_dict["data"] if k != "PSTH"
				)
		return (sessinfo, meta, data)
	end
	abslog(x) = sign(x)*log(abs(x))
	std(x) = std(x, mean(x))
	std(x,μ) = √sum((x.-μ).^2)

	nanstd(x) = (z -> std(z, mean(z)))(filter(isfinite, skipmissing(x)))
	stderr(x) = std(x)/√length(x)
	nanstderr(x) = stderr(filter(isfinite, skipmissing(x)))
	
	nanmean(x) = mean(filter(isfinite, skipmissing(x)))
	
	binoci(x, α) = begin
		n = length(x)
		map(z -> invlogcdf(Binomial(n, sum(x)/n), log(z)), [α/2, 1-α/2])./n
	end
	binoci(x) = begin
		binoci(x, 0.05)
	end
	nanbinoci(x) = binoci(filter(isfinite, skipmissing(x)))
	nanbinoci(x, α) = binoci(filter(isfinite, skipmissing(x)), α)
	nanzscore(x) = begin
		out = copy(x)
		good = isfinite.(x)
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
end # module
