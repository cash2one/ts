%%%-------------------------------------------------------------------
%%% @author snail
%%% @copyright (C) 2015, <公司>
%%% @doc
%%%
%%% @end
%%% Created : 22. 八月 2015 10:10
%%%-------------------------------------------------------------------

-module(monitorVMOtp).
-author("snail").

-behaviour(gen_server).

%% API
-export([start_link/0,logPsInfo/0]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-define(SERVER, ?MODULE).

-define(KIB, (1024)).
-define(MIB, (?KIB * 1024)).
-define(GIB, (?MIB * 1024)).
-define(FMT,   "~p\t~12s~20s\t\t~p\t\t~p\t\t~s\t\t~p:~p/~p~n").
-define(FMT_H, "~s\t~12s~20s\t\t~s\t\t~s\t\t~s\t\t~s~n").
%%20分钟执行一次
-define(TickInterval, 5 * 60 * 1000).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
    {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
    {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term()} | ignore).
init([]) ->
    timer:send_interval(?TickInterval, tick),
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
    {reply, Reply :: term(), NewState :: #state{}} |
    {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_info(tick, State) ->
    logPsInfo(),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
    {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

mem2str(Mem) ->
    if Mem > ?GIB -> io_lib:format("~.3fG", [Mem / ?GIB]);
        Mem > ?MIB -> io_lib:format("~.3fM", [Mem / ?MIB]);
        Mem > ?KIB -> io_lib:format("~.3fK", [Mem / ?KIB]);
        Mem >= 0 -> io_lib:format("~.1fB", [Mem / 1.0])
    end.

logPsInfo() ->
    MemTotal = erlang:memory(total),
    PS_Count = erlang:system_info(process_count),
    RQ = erlang:statistics(run_queue),
    ProcessUsed = erlang:memory(processes_used),
    ProcessTotal = erlang:memory(processes),
    MemInfo = erlang:memory([system, atom, atom_used, binary, code, ets]),

    SystemMem = mem2str(proplists:get_value(system, MemInfo)),
    AtomMem = mem2str(proplists:get_value(atom, MemInfo)),
    AtomUsedMem = mem2str(proplists:get_value(atom_used, MemInfo)),
    BinMem = mem2str(proplists:get_value(binary, MemInfo)),
    CodeMem = mem2str(proplists:get_value(code, MemInfo)),
    EtsMem = mem2str(proplists:get_value(ets, MemInfo)),

    PSList = erlang:processes(),

    ProcessesProplist = [[{pid, erlang:pid_to_list(P)} | process_info_items(P)] || P <- PSList],

    Fun = fun(L, AccIn) ->
        Pid = proplists:get_value(pid, L),
        RegName = case proplists:get_value(registered_name, L) of
                      [] ->
                          "null";
                      V ->
                          V
                  end,
        Red = proplists:get_value(reductions, L),
        MQL = proplists:get_value(message_queue_len, L),
        Mem = proplists:get_value(memory, L),
        CF = proplists:get_value(current_function, L),

        [{Pid, RegName, Red, MQL, Mem, CF} | AccIn]
          end,
    PPList = lists:foldl(Fun, [], ProcessesProplist),
    Str1 = logSortByMQueue(PPList),
    Str2 = logSortByMem(PPList),
    logger:info(
        "~n~nnodes:~p~n"
        "~nProcess:~p(run_queue:~p)~n"
        "total:~s\tprocess memory:~s(~s used)~n"
        "Sys:~s,\tAtom:~s/~s,\tBin:~s,\tCode:~s,\tEts:~s~n~n"
        ?FMT_H
        "---------------------------------------------------------------------------------------------------------------~n"
        "MsqQ(**)~n"
        "~ts~n"
        "Memory(**)~n"
        "~ts~n",
        [nodes(),
            PS_Count, RQ,
            mem2str(MemTotal), mem2str(ProcessUsed), mem2str(ProcessTotal),
            SystemMem, AtomUsedMem, AtomMem, BinMem, CodeMem, EtsMem,
            "Row", "Pid","RegName","Reds","MsgQ",  "Memory",  "Current Function",
            Str1,
            Str2]),
    ok.

logSortByMQueue(PPList) ->
    List = lists:keysort(4, PPList),
    Fun = fun({Pid, RegName, Red, MQL, Mem, {M, F, A}}, {N, AccIn}) ->
        case N =< 0 of
            true ->
                {break, {N, AccIn}};
            _ ->
                {N - 1,io_lib:format(?FMT,
                    [N, Pid, RegName, Red, MQL, mem2str(Mem), M, F, A]) ++ AccIn}
        end
          end,
    {_, Str} = misc:mapAccList(List, {20, []}, Fun),
    Str.

logSortByMem(PPList) ->
    List = lists:keysort(5, PPList),
    Fun = fun({Pid, RegName, Red, MQL, Mem, {M, F, A}}, {N, AccIn}) ->
        case N =< 0 of
            true ->
                {break, {N, AccIn}};
            _ ->
                {N - 1,io_lib:format(?FMT,
                    [N, Pid, RegName, Red, MQL, mem2str(Mem), M, F, A]) ++ AccIn}
        end
          end,
    {_, Str} = misc:mapAccList(List, {20, []}, Fun),
    Str.

process_info_items(P) ->
    erlang:process_info(P,
        [
            registered_name,
            reductions,
            message_queue_len,
            memory,
            heap_size,
            stack_size,
            total_heap_size,
            current_function
        ]).

