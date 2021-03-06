%% @author snail
%% @doc @todo 时间进程.


-module(timeOtp).
-author(snail).

-include("type.hrl").

-define(TABLE, timeOtpEts).

-define(SECONDS_PER_DAY, 86400).
-define(DAYS_FROM_0_TO_1970, 719528).

-record(recTime,
{
	gregorianSeconds = 0,             %%当前UTC时间，精确秒，类型：整数
	chinaGregorianSeconds = 0,			%%中国本地日期时间，精确到秒，类型：整数

	nowDataTime = 0,                %%当前UTC时间，精确到秒，类型：{{Year,Month,Day}, {Hour,Minute,Second}}
	timeStamp = 0      	        %%当前UTC时间，精确到微秒，类型：{MegaSecs, Secs, MicroSecs}
}).

-record(recSyncTime,
{
	localTimeAdjustHour = 0,	%%本地时区
	syncFromDBSLocalTime = 0	%%从DBS同步过来的本地时间
}).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		timestamp/0,
		datetime/0,
		gregorianSeconds/0,
		chinaGregorianSeconds/0
		]).

-export([
	localtimeSeconds/0,
	adjustHour/0
]).

-export([
		 start_link/0,
		 init/1, 
		 handle_call/3, 
		 handle_cast/2, 
		 handle_info/2, 
		 terminate/2, 
		 code_change/3,
		 handle_exception/3
		]).

start_link() ->
	myGenServer:start_link({local,?MODULE},?MODULE, [], [{timeout,8000}]).

%%获取当前时间戳，与os:timestamp()函数一致
-spec timestamp() -> {MegaSecs, Secs, MicroSecs} when
		  MegaSecs::uint(),Secs::uint(),MicroSecs::uint().
timestamp() ->
	ets:lookup_element(?TABLE, recTime, #recTime.timeStamp).

%%获取UTC当前日期时间的秒数
-spec gregorianSeconds() -> uint().
gregorianSeconds() ->
	ets:lookup_element(?TABLE, recTime, #recTime.gregorianSeconds).

%%获取UTC当前日期时间
-spec datetime() -> calendar:datetime1970().
datetime() ->
	ets:lookup_element(?TABLE, recTime, #recTime.nowDataTime).

-spec chinaGregorianSeconds() -> calendar:datetime1970().
chinaGregorianSeconds() ->
	ets:lookup_element(?TABLE, recTime, #recTime.chinaGregorianSeconds).

%%获取本地时间的调整时区，由DBS同步过来的
-spec adjustHour() -> int().
adjustHour() ->
	ets:lookup_element(?TABLE, recSyncTime, #recSyncTime.localTimeAdjustHour).

-spec localtimeSeconds() -> uint().
localtimeSeconds() ->
	ets:lookup_element(?TABLE, recSyncTime, #recSyncTime.syncFromDBSLocalTime).

%% ====================================================================
%% CallBack functions
%% ====================================================================

init([]) ->
	erlang:process_flag(trap_exit, true),
	%%8小时的秒数
	MSof8Hour = 8 * 3600,
	put(msOf8Hour,MSof8Hour),
	ets:new(?TABLE, [protected, named_table, {read_concurrency, true},{keypos,1}]),
	ets:insert(?TABLE,[#recTime{},#recSyncTime{}]),
	update_time(),
	%% PS:使用erlang:send_after会累积误差(借用cowboy源码实现方式 cowboy_clock.erl模块)
	{ok, _TRef} = timer:send_interval(100, update),
	timer:send_interval(1000,updateSyncTime),

	logger:info("~p init OK",[?MODULE]),
	{ok, {}}.

handle_call(_Msg, _From, State) ->
	{noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_info({osTimeFromDBS,_Pid, Time},State) ->
	myEts:updateEts(?TABLE, recSyncTime, {#recSyncTime.syncFromDBSLocalTime,Time}),
	{noreply, State};

handle_info({adjustTimeHour,_Pid, Hour},State) ->
	myEts:updateEts(?TABLE, recSyncTime, {#recSyncTime.localTimeAdjustHour,Hour}),
	{noreply, State};

handle_info(update, State) ->
	update_time(),
	{noreply, State};

handle_info(updateSyncTime, State) ->
	ets:update_counter(?TABLE,recSyncTime,{#recSyncTime.syncFromDBSLocalTime,1}),
	{noreply, State};

handle_info(Info,State) ->
	logger:error("unhandle info:[~p] in [~p] [~p,~p]",[Info,node(),?MODULE,self()]),
	{noreply,State}.

handle_exception(Type,Why,State) ->
	myGenServer:default_handle_excetion(Type, Why, State).

%% ====================================================================
%% Internal functions
%% ====================================================================

-spec update_time() -> ok.
update_time() ->
	OSTimeStamp = os:timestamp(),
	%%转换为UTC日期时间
	UTCDateTime = calendar:now_to_datetime(OSTimeStamp),
	%%转换为UTC日期时间的绝对秒数
	GregorianSeconds = calendar:datetime_to_gregorian_seconds(UTCDateTime),
	
	ChinaGregorianSeconds = GregorianSeconds + get(msOf8Hour),

	%%更新各种时间
	true = myEts:updateEts(?TABLE,recTime,
		[
			{#recTime.gregorianSeconds,GregorianSeconds},
			{#recTime.chinaGregorianSeconds,ChinaGregorianSeconds},
			{#recTime.timeStamp,OSTimeStamp},
			{#recTime.nowDataTime,UTCDateTime}
		]),
	ok.

