-module(sw_core_faction).
-include("sw_core_db.hrl").
-include_lib("stdlib/include/qlc.hrl").

-export([execute/4]).
-export([introduce/2]).

%% tag::starshipExecute[]
execute(_Ctx, #faction { id = ID,
                         name = Name }, Field, Args) ->
    case Field of
        <<"id">> ->
            {ok, sw_core_id:encode({'Faction', ID})};
        <<"name">> ->
            {ok, Name};
        <<"ships">> ->
            Txn = fun() ->
                          QH = qlc:q(
                                 [#{ starship => S,
                                     transport => T } ||
                                     S <- mnesia:table(starship),
                                     T <- mnesia:table(transport),
                                     T#transport.faction == ID,
                                     S#starship.id == T#transport.id]),
                          qlc:e(QH)
                  end,
            {atomic, Records} = mnesia:transaction(Txn),
            sw_core_paginate:select(Records, Args)
    end.

%% tag::introduce[]
introduce(_Ctx, #{ <<"name">> := Name }) ->
    ID = sw_core_db:nextval(faction), % <1>
    Faction = #faction { id = ID, name = Name }, % <2>
    Txn = fun() ->
                  mnesia:write(Faction) % <3>
          end,
    case mnesia:transaction(Txn) of
        {atomic, ok} ->
            {ok, Faction} % <4>
    end.
%% end::introduce[]

