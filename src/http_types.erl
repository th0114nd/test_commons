-module(http_types).

-include_lib("proper/include/proper.hrl").

-export([gen_method/0, gen_content_type/0]).

% See http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
-spec gen_method() -> proper_types:type().
gen_method() ->
    union([<<"CONNECT">>,
           <<"DELETE">>,
           <<"GET">>,
           <<"HEAD">>,
           <<"OPTIONS">>,
           <<"POST">>,
           <<"PUT">>,
           <<"PATCH">>,
           <<"TRACE">>]).

-spec gen_content_type() -> proper_types:type().
gen_content_type() ->
    Dir = code:priv_dir(test_commons),
    Handcoded = [<<"application/json">>,
                 <<"text/plain">>,
                 <<"text/html">>],
    Mimes = case file:consult(Dir ++ "mimes.edata") of
        {ok, Binaries} -> Handcoded ++ Binaries;
        {error, _Reason} -> Handcoded
        end,
    union([exactly(Mime) || Mime <- Mimes]).
    
