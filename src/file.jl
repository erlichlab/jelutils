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