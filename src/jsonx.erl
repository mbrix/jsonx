%% @copyright 2013 Yuriy Iskra <iskra.yw@gmail.com>

%% @doc JSONX is an Erlang library for efficient decode and encode JSON, written in C.
%%      Works with binaries as strings, arrays as lists and it only knows how to decode UTF-8 (and ASCII).
%%
%%      <h3>Decode (json -> erlang)</h3>
%%      <ul>
%%       <li>null   -> atom null</li>
%%       <li>true   -> atom true</li>
%%       <li>false  -> atom false</li>
%%       <li>string -> binary</li>
%%       <li>number -> number</li>
%%       <li>array  -> list</li>
%%       <li>object -> {PropList}, optional struct or proplist.</li>
%%      </ul>
%%      <h3>Encode (erlang -> json)</h3>
%%      <ul>
%%       <li>atom null 	      -> null</li>
%%       <li>atom true 	      -> true</li>
%%       <li>atom true 	      -> false</li>
%%       <li>any other atom     -> string</li>
%%       <li>binary             -> string</li>
%%       <li>number             -> number</li>
%%       <li>{struct, PropList} -> object</li>
%%       <li>{PropList}         -> object</li>
%%       <li>PropList           -> object</li>
%%       <li>{json, IOList}     -> include IOList with no validation</li>
%%      </ul>

-module(jsonx).
-export([decode/1, decode/2, encode/1, encoder/1]).
-on_load(init/0).
-define(LIBNAME, jsonx).
-define(APPNAME, jsonx).

%%@doc Encode JSON.
-spec encode(JSON_TERM) -> JSON when
      JSON      :: binary(),
      JSON_TERM :: any().
encode(_) ->
    not_loaded(?LINE).


%%@doc Encode JSON.
-spec encoder(RECORDS_DESC) -> ENCODER when
      RECORDS_DESC :: [{tag, [names]}],
      ENCODER      :: function().
%% %% Records descriptions for NIF
%% {
%%   Rcnt                                 %% Records count
%%  ,Fcnt                                 %% Counter all fields in records
%%  ,Records = [{Tag, Fields_off, Arity}] %% List of records tag, position and length fields
%%  ,Fields  = [{Name_off, Size}]         %% List of position and size fields names in binary storage
%%  ,Binsz                                  %% Binary data size
%%  ,Bin                                  %% Binary storage for names of fields, format - <,"name": >
%% }
encoder(R) ->
    {Rcnt, Fcnt, Binsz, Rs, Fs, Bin} = inspect_records(R),
    Resource = make_records_resource(Rcnt, Fcnt, Rs, Fs, Binsz, Bin),
    fun(JSON_TERM) -> encode(JSON_TERM, Resource) end.

make_records_resource(_Rcnt, _Fcnt, _Rs, _Fs, _Binsz, _Bin) ->
    not_loaded(?LINE).
encode(_JSON_TERM, _Resource) ->
    not_loaded(?LINE).
inspect_records(T) ->
    {Rcnt, Fcnt, Rs, {Fs, Blen, Bins}} = records(T),
    {Rcnt, Fcnt, Blen, lists:reverse(Rs), lists:reverse(Fs),
     iolist_to_binary(lists:reverse(Bins))}.
records(Rs) ->
    records_(Rs, {_Rcnt = 0, _OffF = 0, _Rs = [],
	    {_Fields = [], _OffB = 0, _Bins = []}}).
records_([], R) ->
    R;
records_([{Tag, Fs} | RTail], {Rcnt, OffF, Rs, FsR}) when is_atom(Tag) ->
    Fcnt = length(Fs),
    records_(RTail, {Rcnt+1, OffF + Fcnt, [{Tag,  OffF, Fcnt} | Rs] , fields1(Fs, FsR)}).
fields1([], R) ->
    R;
fields1( [Name|NTail], {Fields, OffB, Bins}  ) when is_atom(Name) ->
    Bin = iolist_to_binary(["\"", atom_to_binary(Name, latin1),<<"\": ">>]),
    LenB = size(Bin),
    fields(NTail, {[{OffB, LenB} | Fields], OffB + LenB, [Bin|Bins]}).
fields([], R) ->
    R;
fields( [Name|NTail], {Fields, OffB, Bins}  ) when is_atom(Name) ->
    Bin = iolist_to_binary([",\"", atom_to_binary(Name, latin1),<<"\": ">>]),
    LenB = size(Bin),
    fields(NTail, {[{OffB, LenB} | Fields], OffB + LenB, [Bin|Bins]}).

%%@doc Decode JSON to Erlang term.
-spec decode(JSON) -> JSON_TERM when
      JSON      :: binary(),
      JSON_TERM :: any().
decode(_) ->
    not_loaded(?LINE).

%%@doc Decode JSON to Erlang term with options.
-spec decode(JSON, Options) -> JSON_TERM when
      JSON      :: binary(),
      Options   :: [{format, struct|eep18|proplist}],
      JSON_TERM :: any().
decode(B, []) -> decode2(B, eep18);
decode(B, [{format, struct}]) ->   decode2(B, struct);
decode(B, [{format, eep18}]) ->    decode2(B, eep18);
decode(B, [{format, proplist}]) -> decode2(B, proplist);
decode(B, [_|XS]) -> decode(B, XS).

decode2(_JSON, _Options) ->
    not_loaded(?LINE).

%% Init

init() ->
    So = case code:priv_dir(?APPNAME) of
        {error, bad_name} ->
            case filelib:is_dir(filename:join(["..", priv])) of
                true ->
                    filename:join(["..", priv, ?LIBNAME]);
                _ ->
                    filename:join([priv, ?LIBNAME])
            end;
        Dir ->
            filename:join(Dir, ?LIBNAME)
    end,
    erlang:load_nif(So, [[json, struct, proplist, eep18, no_match], [true, false, null],
			 [error, big_num, invalid_string, invalid_json, trailing_data]]).

not_loaded(Line) ->
    exit({not_loaded, [{module, ?MODULE}, {line, Line}]}).
