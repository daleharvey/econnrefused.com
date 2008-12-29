%% @author Dale Harvey <dale@arandomurl.com>
%% @doc generates stats and html for the log view, the code is ugly because
%%      I cant really tell the difference in a shell
-module(chat_log_util).
-export([start/1]).

-define(LOG_PATH,"/home/daleharvey/www/econnrefused.com/logs/").
-define(CUR_PATH,"/home/daleharvey/www/econnrefused.com/logviewer/").
-define(ROOM,    "web@conference.econnrefused.com").

start(clean) ->
    F = fun(?LOG_PATH++X) -> 
                stats(filename:dirname(X)++"/"++filename:basename(X,".txt"))
        end,
    lists:map(F,filelib:wildcard(?LOG_PATH++"*/*/*/*.txt"));

start(last) ->
    {Y,M,D} = erlang:date(),
    stats(lists:concat([?ROOM,"/",Y,"/",M,"/",D])).

stats(Path) ->
    filelib:ensure_dir(?CUR_PATH++Path),
    gen_logs(?LOG_PATH++Path++".txt",?CUR_PATH++Path++".html"),
    gen_stats(?LOG_PATH++Path++".txt",?CUR_PATH++Path++".freq"),
    ok.

gen_stats(InFile,OutFile) ->
    {ok,File}  = file:open(InFile,[read]),
    {ok,Times} = get_timestamps(File,dict:new()),
    save_file(OutFile,Times),  
    ok.

save_file(File, Times) ->
    {ok,Out}  = file:open(File,[write]),
    io:format(Out,"{\"frequency\": [",[]),
    save_hours(Out,lists:seq(0,23),Times),
    io:format(Out,"]}",[]),
    file:close(Out),
    ok.

save_hours(_File,[],_Dict)     -> ok;
save_hours(File,[H|Tail],Dict) ->
    
    F = fun(M) ->
		C = case dict:is_key({H,M},Dict) of
			true  ->  dict:fetch({H,M},Dict);
			false ->  0
		    end,
		io_lib:format("{\"h\":~p,\"m\":~p,\"v\":~p}",[H,M,C])
	end,

    End = case Tail of 
	      []    -> "";
	      _Else -> ","
	  end,

    io:format(File,"\n\t~s,\n\t~s,\n\t~s,\n\t~s~s",[F(00),F(15),F(30),F(45),End]),
    save_hours(File,Tail,Dict).

get_timestamps(File,Dict) ->
    case io:get_line(File,"") of
        eof ->
            file:close(File),
            {ok,Dict};
        
        [$[,H1,H2,$:,M1,M2,$:,_S1,_S2,$]|_Rest]  ->
            Time  = {list_to_integer([H1,H2]),
                     round_down(list_to_integer([M1,M2]))},
            NDict = dict:update_counter(Time,1,Dict),
            get_timestamps(File,NDict);
        
        _Else ->
            get_timestamps(File,Dict)
    end.

round_down(M) when M < 15 -> 00;
round_down(M) when M < 30 -> 15;
round_down(M) when M < 45 -> 30;
round_down(M) when M < 60 -> 45.

gen_logs(InFile,OutFile) ->
    {ok,File}  = file:open(InFile,[read]),
    {ok,Out}   = file:open(OutFile,[write]),
    io:format(Out,"<table>",[]),
    gen_log(File,Out),
    io:format(Out,"</table>",[]),
    ok.

dname([],_Acc) ->
    no_name;
dname([$>|T],Acc) ->
    {ok,lists:reverse(Acc),T};
dname([$<|T],Acc) ->
    dname(T,Acc);
dname([H|T],Acc) ->
    dname(T,[H|Acc]).

gen_log(File,Out) ->

    Row = "<tr><td class='date'>~s</td>"
        ++"<td class='name'>~s</td><td class='msg'>~s</td></tr>",

    case io:get_line(File,"") of
        eof ->
            file:close(File),
            ok;
        
        [$[,H1,H2,$:,M1,M2,$:,_S1,_S2,$],32|Rest]  ->
            {X,Y} = case dname(Rest,[]) of 
                        {ok,Name,TheRest} ->
                            {Name,TheRest};
                        no_name ->
                            {"","<span class='notice'>"++Rest++"</span>"}
                    end,
            
            io:format(Out,Row,[[$[,H1,H2,$:,M1,M2,$:,_S1,_S2,$]],X,Y]),
            gen_log(File,Out);
        
        _Else ->
            io:format(Out,Row,["","",_Else]),
            gen_log(File,Out)
    end.
