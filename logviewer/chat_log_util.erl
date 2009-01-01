%% @author Dale Harvey <dale@arandomurl.com>
%% @doc generates stats and html for the log view, the code is ugly because
%%      I cant really tell the difference in a shell
-module(chat_log_util).

-import(filename,[dirname/1,basename/2]).
-export([start/1]).

-define(LOG_PATH,"/home/daleharvey/www/econnrefused.com/logs/").
-define(CUR_PATH,"/home/daleharvey/www/econnrefused.com/logviewer/").
-define(ROOM,    "web@conference.econnrefused.com").
-define(COLOURS, [alizarin,blue, indigo, springgreen,
                 burgundy,orange,cerise, tangerine,
                 violet]).

start(clean) ->
    F = fun(?LOG_PATH++X) -> 
                stats(dirname(X)++"/"++basename(X,".txt"))
        end,
    lists:map(F,filelib:wildcard(?LOG_PATH++"*/*/*/*.txt"));

start(last) ->
    {Y,M,D} = erlang:date(),
    F = fun(X) -> io_lib:format("~2.10.0B",[X]) end,
    stats(lists:flatten(lists:concat([?ROOM,"/",Y,"/",F(M),"/",F(D)]))).

stats(Path) -> 
    In  = ?LOG_PATH++Path++".txt",
    Out = ?CUR_PATH++Path,
    filelib:ensure_dir(Out),
    gen_logs( In,Out++".html"),
    gen_stats(In,Out++".freq"),
    ok.

gen_stats(InFile,OutFile) ->
    I = fun list_to_integer/1,
    F = fun([$[,H1,H2,$:,M1,M2,$:,_S1,_S2,$]|_Rest], Acc) -> 
                Time = {I([H1,H2]), round_down(I([M1,M2]))},
                dict:update_counter(Time, 1, Acc);
           (_Line,Acc) ->
                Acc
        end,
    {ok,Times} = with_file(InFile,F,dict:new()),
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
    
    io:format(File,"~s,~s,~s,~s~s",[F(00),F(15),F(30),F(45),End]),
    save_hours(File,Tail,Dict).

round_down(M) when M < 15 -> 00;
round_down(M) when M < 30 -> 15;
round_down(M) when M < 45 -> 30;
round_down(M) when M < 60 -> 45.

-define(ROW,"<tr><td class='date'>~s</td><td class='name ~s'>"
          ++"~s</td><td class='msg'>~s</td></tr>").

gen_logs(InFile,OutFile) ->
    {ok,Out} = file:open(OutFile,[write]),
    F = fun(X,Dict) -> write_log(X,Out,Dict) end,
    io:format(Out,"<table>",[]),
    with_file(InFile,F,dict:store(colours,?COLOURS++?COLOURS,dict:new())),
    io:format(Out,"</table>",[]),
    file:close(Out).

write_log( [$[,H1,H2,$:,M1,M2,$:,S1,S2,$],32|Rest],File,Dict) ->
    Time = [$[,H1,H2,$:,M1,M2,$:,S1,S2,$],32],
    case dname(Rest,[]) of 
        {ok,Name,Msg} ->
            {Colour,NDict} = get_colour(Dict,Name),
            io:format(File,?ROW,[Time,Colour,Name,Msg]),
            NDict;
        no_name ->
            Msg = "<span class='notice'>"++Rest++"</span>",
            io:format(File,?ROW,[Time,"","",Msg]),
            Dict
    end;
write_log(Else,File,Dict) ->
    io:format(File,?ROW,["","","",Else]),
    Dict.
    
get_colour(Dict,Name) ->
    case dict:is_key(Name,Dict) of
        true  -> {dict:fetch(Name,Dict),Dict};
        false ->
            [H|T] = dict:fetch(colours,Dict),
            D1 = dict:store(colours,T,Dict),
            {H,dict:store(Name,H,D1)}
    end.
            

dname([],_Acc) ->
    no_name;
dname([$>|T],Acc) ->
    {ok,lists:reverse(Acc),T};
dname([$<|T],Acc) ->
    dname(T,Acc);
dname([H|T],Acc) ->
    dname(T,[H|Acc]).

with_file(File, Fun, Acc) ->
    {ok, Fd} = file:open(File, [read]),
    Res = feed(Fd, io:get_line(Fd,""), Fun, Acc),
    file:close(Fd),
    Res.

feed(_Fd, eof, _Fun, Acc) ->
    {ok,Acc};
feed(Fd, Line, Fun, Farg) ->
    feed(Fd, io:get_line(Fd,""), Fun, Fun(Line, Farg)).
