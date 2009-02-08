-module(urlutil).

%%-export([parse_url/1]).
-compile(export_all).
-include_lib("eunit/include/eunit.hrl").

%% @spec parse_url(Url) -> {Scheme, Host, Port, Path, Params}
%% @doc Parses a URL into scheme, host, port, path, and query parameters.
%% all values are strings except port (integer) and query parameters, a
%% list of tuples.

port_from_acc(PortAcc) ->
    if
        length(PortAcc) > 0 ->
            list_to_integer(lists:reverse(PortAcc));
        true -> 0
    end.

parse_host(Url) ->
    parse_host(Url, [], []).
parse_host([], PortAcc, RestAcc) ->
    {lists:reverse(RestAcc), port_from_acc(PortAcc), []};
parse_host([$/|Rest], PortAcc, Acc) ->
    {lists:reverse(Acc), port_from_acc(PortAcc), [$/|Rest]};
parse_host([$:|[C|Rest]], [], Tsoh)
  when is_integer(C), C > $0, C < $9 ->
    parse_host(Rest, [C], Tsoh);
parse_host([$:|[C|Rest]], [], Tsoh) ->
    {lists:reverse(Tsoh), error, [C|Rest]};
parse_host([C|Rest], PortAcc, Tsoh)
  when length(PortAcc) > 0, is_integer(C), C > $0, C < $9 ->
    parse_host(Rest, [C|PortAcc], Tsoh);
parse_host([C|Rest], PortAcc, Tsoh)
  when length(PortAcc) > 0, is_integer(C) ->
    {lists:reverse(Tsoh), error, [C|Rest]};
parse_host([C|Rest], PortAcc, Acc) when length(PortAcc) =:= 0 ->
    parse_host(Rest, PortAcc, [C|Acc]).

parse_scheme(Url) ->
    Pos = string:str(Url, "://"),
    if Pos > 1 ->
            {ok, string:substr(Url, 1, Pos - 1), string:substr(Url, Pos + 3)};  
       true ->
            {error, no_scheme, Url}
    end.

parse_scheme_test_() ->
    [
     ?_assertMatch({ok, "http", "foo.bar"}, parse_scheme("http://foo.bar")),
     ?_assertMatch({ok, "http", ""}, parse_scheme("http://")),
     ?_assertMatch({error, no_scheme, _}, parse_scheme("blah")),
     ?_assertMatch({error, no_scheme, _}, parse_scheme("://blah"))
    ].

parse_host_test_() ->
    [
     ?_assertMatch({"foo.bar.com",0,[]}, parse_host("foo.bar.com")),
     ?_assertMatch({"foo.bar.com",123,[]}, parse_host("foo.bar.com:123")),
     ?_assertMatch({"foo.bar.com",0,"/a/b"}, parse_host("foo.bar.com/a/b")),
     ?_assertMatch({"f.com",4,"/a/b"}, parse_host("f.com:4/a/b")),
     ?_assertMatch({"f.com",error,"x"}, parse_host("f.com:x")),
     ?_assertMatch({"f.com",error,"y2/"}, parse_host("f.com:1y2/"))
    ].
