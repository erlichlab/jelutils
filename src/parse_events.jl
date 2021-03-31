

	

_c(x::Nothing) = Float32[]
_c(x) = convert(Float32, x)

_empty() = DataFrame(eventname = String[],
						 eventtype=String[],
						 transition=String[],
						 times = Float32[])

_in(n,t) = DataFrame(eventname = n[1:end-2],
						 eventtype="poke",
						 transition="in",
						 times = _c.(t),copycols=false)

_out(n,t) = DataFrame(eventname = n[1:end-3],
						 eventtype="poke",
						 transition="out",
						 times = _c.(t),copycols=false)
_other(n,t) = DataFrame(eventname = n,
						 eventtype="other",
						 transition="",
						 times = _c.(t),copycols=false)
	
_timer(n,t) = DataFrame(eventname = n,
						 eventtype="timer",
						 transition="up",
						 times = _c.(t),copycols=false)

const pokes = ["MidR", "TopR","BotR","MidL", "TopL","BotL","MidC","BotC"]	
	
_name(n) = begin
	    poke_ind = endswith.("WaitForStartPoke_MidL",pokes)
		if any(poke_ind)
			lastindex = n[end-4] == '_' ? 4 : 3
			return n[1:end-lastindex]			
		else
			return n
		end

		
	end
	
process_state(o) = begin
	state_name = convert(String,first(o))
	M = _c.(last(o))
	rows = length(M)
	if rows>0
		return DataFrame(eventname = state_name, 
				   eventtype="state",
					transition=repeat(["in", "out"],inner=Int(rows/2)),
					times = M,copycols=false)
	else
		return _empty()
	end
	
end

process_event(o) = begin
	event_name = convert(String,first(o))
	f = if event_name == "Tup" || contains(event_name,"Timer")
		_timer
	elseif endswith(event_name,"in") 
		_in		
	elseif endswith(event_name,"out")
		_out
	else		
		_other
	end
	f(event_name, last(o))
end


process_trial(pevec) = begin
	io = IOBuffer(pevec[2])
	pestr=replace(read(io, String), "NaN"=>"null")
	pe = LazyJSON.value(pestr)["vals"]
	pedf = vcat(mapreduce(process_state, vcat, pe["States"]),
				mapreduce(process_event, vcat, pe["Events"]))
	delete!(pedf, isempty.(pedf.times))
	sort!(pedf, [:times, order(:transition, rev=true)])
	pedf.sessiontime = pedf.times .+ convert(Float32,pe["StartTime"])
	pedf.trial_num = fill(pevec[1], length(pedf.times))
	pedf
end





event_df(dbc, sessid) = begin
	df = DBInterface.execute(dbc, "select parsed_events from beh.trialsview where sessid = $(sessid)", mysql_store_result=false) |> DataFrame
	pedf = mapreduce(process_trial, vcat, enumerate(df.parsed_events))
end

