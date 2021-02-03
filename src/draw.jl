using Plots, StatsPlots
draw_histsig(bins, data, is_sig; 
            normalize=false,
            fillcolor=[:white :black],
            legend=:false,
            size=(300, 150),
            guidefontsize=10, 
            titlefontsize=10,
            options...
            ) = begin
    
    hs = fit(Histogram, data[is_sig], bins, closed=:right)
	hn = fit(Histogram, data[.!is_sig], bins, closed=:right)
    
    total = normalize ? sum(isfinite, is_sig) : 1
    binc = (bins[1:end-1] + bins[2:end]) /2
    groupedbar(binc, hcat(hn.weights,hs.weights)./total, 
        bar_position = :stack;  fillcolor,
        size, legend, guidefontsize, titlefontsize,
        options...
        ) 


end