-module(sw_core_planet).
-include("sw_core_db.hrl").
-include_lib("stdlib/include/qlc.hrl").

-export([execute/4]).

%% tag::planetExecute[]
execute(_Ctx, #planet { id = PlanetId } = Planet, Field, Args) ->
    case Field of
        <<"id">> -> {ok, sw_core_id:encode({'Planet', Planet#planet.id})};
        <<"edited">> -> {ok, Planet#planet.edited};
        <<"climate">> -> {ok, Planet#planet.climate};
        <<"surfaceWater">> -> {ok, Planet#planet.surface_water};
        <<"name">> -> {ok, Planet#planet.name};
        <<"diameter">> -> {ok, integer(Planet#planet.diameter)};
        <<"rotationPeriod">> -> {ok, integer(Planet#planet.rotation_period)};
%% end::planetExecute[]
        <<"filmConnection">> ->
            Txn = fun() ->
                          QH = qlc:q([F || F <- mnesia:table(film),
                                           lists:member(PlanetId, F#film.planets)]),
                          qlc:e(QH)
                  end,
            {atomic, Films} = mnesia:transaction(Txn),
            sw_core_paginate:select(Films, Args);
%% tag::residentConnection[]
        <<"residentConnection">> ->
            Txn = fun() ->
                          QH = qlc:q([P || P <- mnesia:table(person),
                                           P#person.homeworld == PlanetId]),
                          qlc:e(QH)
                  end,
            {atomic, People} = mnesia:transaction(Txn),
            sw_core_paginate:select(People, Args);
%% end::residentConnection[]
        <<"created">> -> {ok, Planet#planet.created};
        <<"terrains">> ->
            Terrains = Planet#planet.terrain,
            {ok, [{ok, T} || T <- Terrains]};
        <<"gravity">> -> {ok, Planet#planet.gravity};
        <<"orbitalPeriod">> -> {ok, integer(Planet#planet.orbital_period)};
        <<"population">> -> {ok, integer(Planet#planet.population)}
    end.

integer(I) when is_integer(I) -> I;
integer(nan) -> null.
    
