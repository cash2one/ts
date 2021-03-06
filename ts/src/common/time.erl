%% @author snail
%% @doc @todo 时间相关函数.
%%

-module(time).
-author(snail).

-include("type.hrl").
-include("common.hrl").

-define(SECONDS_PER_DAY, 86400).
-define(DAYS_FROM_0_TO_1970, 719528).

%%没有加1970年的相对秒
-type dateTimeSec() :: uint().
%%没有加1970年的相对日期时间
-type datetime() :: calendar:datetime().

%%加上1970年的绝对秒
-type dateTimeSec1970() :: uint().
%%加上1970年的绝对日期时间
-type datetime1970() :: calendar:datetime1970().

%%没有加1970年的相对毫秒
-type dateTimeMS() :: uint().


%% ====================================================================
%% API functions
%% ====================================================================

%%以下为获取绝对日期时间的函数
-export([
	chinaGregorianSecondsDateTime/0,

	localDateTime/0,
	localGregorianSeconds/0,

	datetime/0,
	gregorianSeconds/0
]).

%%以下为获取相对日期时间的函数
-export([
	timestamp/0,
	timestampMS/0
]).

%%以下为转换函数
-export([
	convertTimeStamp2MS/1,
	convertDateTime1970ToSec/1,

	convertSec2DateTime/1,
	convertSec2DateTimeStr/1,

	convertTimeStamp2DateTime/1,
	convertTimeStamp2DateTimeStr/1,

	dateTimeToInt64/1,
	int64ToTimeString/1
]).

-export([
	timestampMSDiff2010/0,
	getDayBeginSeconds/1,
	getWeekBeginSecondsByDay/1,
	diffSecFrom1970/1
]).

-export([
	localtimeSeconds/0,
	gregorianSecondsDB/0,
	adjustHour/0,
	localtimeSecondsDB/0,
	timestampDB/0
]).

-export([
	getLogTimeSec/0
]).

%% ====================================================================
%% 以下为获取函数
%% ====================================================================
%获取当前中国时间，精确到秒，主要用于日志记录使用
%返回{{Year,Month,Day}, {Hour,Minute,Second}}
-spec chinaGregorianSecondsDateTime() -> datetime1970().
chinaGregorianSecondsDateTime() ->
	Sec = timeOtp:chinaGregorianSeconds(),
	calendar:gregorian_seconds_to_datetime(Sec).

%获取本地时间，精确到秒，主要用于除日志外的其它使用
%返回{{Year,Month,Day}, {Hour,Minute,Second}}
-spec localDateTime() -> datetime1970().
localDateTime() ->
	DT = timeOtp:datetime(),
	calendar:universal_time_to_local_time(DT).

%获取本地时间秒数
-spec localGregorianSeconds() -> dateTimeSec1970().
localGregorianSeconds() ->
	DT = calendar:now_to_local_time(timeOtp:timestamp()),
	calendar:datetime_to_gregorian_seconds(DT).

%%获取UTC时间，精确到秒
-spec datetime() -> datetime1970().
datetime() ->
	timeOtp:datetime().

%%获取当前UTC的绝对日期时间的秒数
-spec gregorianSeconds() -> dateTimeSec1970().
gregorianSeconds() ->
	timeOtp:gregorianSeconds().

%获取当前相对于1970-1-1 0:0:0的UTC时间差，精确到秒，相当于Unix时间
-spec timestamp() -> dateTimeSec().
timestamp() ->
	timeOtp:gregorianSeconds() - ?SECS_FROM_0_TO_1970.

%获取当前相对于1970-1-1 0:0:0的UTC时间差，精确到毫秒，相当于Unix时间
-spec timestampMS() -> dateTimeMS().
timestampMS() ->
	convertTimeStamp2MS(timeOtp:timestamp()).

%%获取从2010年到现在的时间差，单位：毫秒
-spec timestampMSDiff2010() -> uint().
timestampMSDiff2010() ->
	NowMS = timestampMS(),
	Sec = diffSecFrom1970({{2010,1,1},{0,0,0}}),
	NowMS - Sec * 1000.

%%获取本地时间的调整时区，由DBS同步过来的
-spec adjustHour() -> int().
adjustHour() ->
	timeOtp:adjustHour().

%%获取从DBS同步过来的本地绝对时间秒
-spec localtimeSeconds() -> uint().
localtimeSeconds() ->
	timeOtp:localtimeSeconds().

%%获取从DBS同步过来的绝对UTC时间秒
-spec gregorianSecondsDB() -> uint().
gregorianSecondsDB() ->
	timeOtp:localtimeSeconds() - timeOtp:adjustHour() * 3600.

%%获取从DBS同步过来的本地相对时间，单位秒
localtimeSecondsDB() ->
	timeOtp:localtimeSeconds() - ?SECS_FROM_0_TO_1970.

%%获取从DBS同步过来的相对UTC时间秒
-spec timestampDB() -> uint().
timestampDB() ->
	timeOtp:localtimeSeconds() - ?SECS_FROM_0_TO_1970 - timeOtp:adjustHour() * 3600.

%%==========================================================================
%%以下为转换函数
%%==========================================================================

%%根据给定时间，返回其毫秒时间
-spec convertTimeStamp2MS({MegaSecs, Secs, MicroSecs}) -> MilliSeconds :: integer() when
	MegaSecs :: integer(), Secs :: integer(), MicroSecs :: integer().
convertTimeStamp2MS({MegaSecs, Secs, MicroSecs}) ->
	(MegaSecs * 1000000 + Secs) * 1000 + MicroSecs div 1000.

%%根据date,time，返回的时间是中性的，本地时间 unix时间都可以用
-spec diffSecFrom1970(DateTime) -> int() when DateTime::datetime1970().
diffSecFrom1970(DateTime) ->
    Seconds1 = calendar:datetime_to_gregorian_seconds(DateTime),
    Seconds2 = calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
    Seconds1 - Seconds2.

%%返回本地时间今天开始那1s，是本地时间
-spec getDayBeginSeconds(DateTime) -> uint() when DateTime::datetime1970() | datetime().
getDayBeginSeconds({{Year,Month,Day},{_Hour,_Min,_Sec}}) ->
	convertDateTime1970ToSec( {{Year,Month,Day},{0,0,0}} ).

%%返回本周一开始的秒数,是本地时间
-spec getWeekBeginSecondsByDay(DateTime)-> uint() when DateTime::datetime1970() | datetime().
getWeekBeginSecondsByDay({{Year,Month,Day},{_Hour,_Min,_Sec}})->
	DayOfWeek = calendar:day_of_the_week(Year, Month, Day),
	TodayBegin = calendar:datetime_to_gregorian_seconds( {{Year,Month,Day},{0,0,0}} ),
	(TodayBegin - (DayOfWeek - 1) * 86400).

%%转换一个日期时间为秒
-spec convertDateTime1970ToSec(CreateTime) -> uint() when CreateTime ::datetime1970() | datetime().
convertDateTime1970ToSec({{Year,Month,Day}, {Hour,Minute,Second}}) ->
	calendar:datetime_to_gregorian_seconds({{Year,Month,Day}, {Hour,Minute,Second}}).

%%转换一个相对或者绝对秒为日期时间，不作1970年的校正
-spec convertSec2DateTime(Sec) -> datetime() | datetime1970() when Sec::dateTimeSec1970() | dateTimeSec().
convertSec2DateTime(Sec) ->
	calendar:gregorian_seconds_to_datetime(Sec).

%%转换一个相对或者绝对秒为日期时间的字符串，不作1970年的校正
-spec convertSec2DateTimeStr(Sec) -> string() when Sec::dateTimeSec1970() | dateTimeSec().
convertSec2DateTimeStr(Sec) ->
	{{Y,M,D},{H,Min,S}} = calendar:gregorian_seconds_to_datetime(Sec),
	lists:concat([Y, "-", one_to_two(M), "-", one_to_two(D), " ", one_to_two(H) , ":", one_to_two(Min), ":", one_to_two(S)]).

%%将一个由erlang:now()或者os:timestamp()换算的相对1970年的秒转换为绝对日期时间
-spec convertTimeStamp2DateTime(Sec) -> datetime1970() when Sec::dateTimeSec().
convertTimeStamp2DateTime(Sec) ->
	calendar:gregorian_seconds_to_datetime(Sec + ?SECS_FROM_0_TO_1970).

%%将一个由erlang:now()或者os:timestamp()换算的相对1970年的秒转换为绝对日期时间字符串
-spec convertTimeStamp2DateTimeStr(Sec) -> string() when Sec::dateTimeSec().
convertTimeStamp2DateTimeStr(Sec) ->
	{{Y,M,D},{H,Min,S}} = calendar:gregorian_seconds_to_datetime(Sec + ?SECS_FROM_0_TO_1970),
	lists:concat([Y, "-", one_to_two(M), "-", one_to_two(D), " ", one_to_two(H) , ":", one_to_two(Min), ":", one_to_two(S)]).

dateTimeToInt64(DateTime) ->
	case erlang:is_integer(DateTime) of
		true ->
			DateTime;
		false ->
			case DateTime of
				{datetime, {{1970, 1, 1}, {0, 0, 0}}} ->
					0;
				{datetime, DT} ->
					convertDateTime1970ToSec(DT)
			end
	end.

int64ToTimeString(Time) when erlang:is_integer(Time) ->
	case Time > 0 of
		true ->
			convertSec2DateTimeStr(Time);
		_ ->
			"1970-01-01 00:00:00"
	end.

%%获取日志记录所需要的本地时间（相对于1970年的时间）秒
-spec getLogTimeSec() -> uint().
getLogTimeSec() ->
	%%这里获取的是一个绝对时间秒，所以需要减去1970年的秒，
	%%注意日志的时间需要的是一个UTC时间，不然查出来会多一个时区的小时，因为数据库已经有时区信息了，所以只能传一个UTC时间
	Sec = gregorianSecondsDB(),
	Sec - ?SECS_FROM_0_TO_1970.
%% ====================================================================
%% Internal functions
%% ====================================================================
one_to_two(One) -> io_lib:format("~2..0B", [One]).

time_format(Now) -> 
	{{Y,M,D},{H,MM,S}} = calendar:now_to_local_time(Now),
	time_format1(Y, M, D, H, MM, S).
time_format1(Y, M, D, H, MM, S) ->
	lists:concat([Y, "-", one_to_two(M), "-", one_to_two(D), " ", 
						one_to_two(H) , ":", one_to_two(MM), ":", one_to_two(S)]).
