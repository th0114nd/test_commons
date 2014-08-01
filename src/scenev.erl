%% @doc
%%   scenev (Scenario Events) is a behaviour which describes a scenario and a set of events,
%%   deduces the expected results and then observes and compares the actual results when
%%   the events are fed to the scenario. The scenario is expected to be a description
%%   of a running erlang configuration (e.g., a supervisor hierarchy with children),
%%   while the events are a series of exported function calls or actions that impact
%%   the corresponding running erlang scenario.
%%
%%   A collection of scenarios can be generated either by using file:consult/1 on a
%%   static set of scenario descriptions, or by using proper to generate random
%%   scenario descriptions. A static set could be generated by saving randomly
%%   generated scenarios or by hand-editing specific scenarios that reproduce an
%%   actual bug observed in production afflicting the software being tested.
%% @end
-module(scenev).

%% External API: Certifying code against a set of proper model instances.
-export([test_all_models/1]).

-include("scenev.hrl").

%% Behaviour callbacks for generating a scenev_model and expected outcomes
-callback get_all_test_model_ids() -> [{Model_Id :: scenev_model_id(), Source :: scenev_source()}].
-callback transform_raw_scenario(Scenario_Num :: pos_integer(), Raw_Scenario :: term()) -> {single, scenev_scenario()} |
                                                                                           {many,  [scenev_scenario()]}.
-callback deduce_expected(Scenario_Instance :: scenev_scenario()) -> Expected_Status :: term().

%% Behaviour callbacks used per scenario when validating against the model
-callback generate_observation(scenev_scenario()) -> Observed_Status :: term().

-callback passed_test_case(Case_Number     :: pos_integer(),
                           Expected_Status :: scenev_dsl_status(),
                           Observed_Status :: scenev_live_status())
              -> boolean().


%%-------------------------------------------------------------------
%% External API for testing all models implemented by a module.
%%-------------------------------------------------------------------

%% Cb_Module is the callback module provided by the model instance.
-spec test_all_models(module()) -> [{scenev_model_id(), scenev_result()}].
test_all_models(Cb_Module) ->
    {ok, IDs} = exec_callback(Cb_Module, get_all_test_model_ids, []),
    NewIDs = lists:append([expand_dir(ID) || ID <- IDs]),
    [begin
         {ok, Raw_Scenarios} = generate_raw(Source),
         Scenarios = transform_raw_scenarios(Cb_Module, Raw_Scenarios),
         {Model_Id, verify_all_scenarios(Cb_Module, Scenarios)}
     end || {Model_Id, Source} <- NewIDs].

-spec expand_dir({scenev_model_id(), scenev_source()}) -> [{scenev_model_id(), scenev_source()}].
expand_dir({Id, {dir, Dir}}) ->
    {ok, Files} = file:list_dir(Dir),
    Pairs = [{Id ++ [$/ | filename:rootname(File)], filename:absname(Dir ++ File)} || File <- Files],
    [{Test_Name, {file, File_Name}} || {Test_Name, File_Name} <- Pairs];
expand_dir(X) -> [X].

-spec generate_raw(scenev_source()) -> {ok, [term()]}.
generate_raw({file, Full_Name} = _Source) ->
    file:consult(Full_Name);
generate_raw({mfa, {Mfa_Module, Function, Args}} = _Source) ->
    {ok, apply(Mfa_Module, Function, Args)}.

-spec transform_raw_scenarios(module(), [term()]) -> [scenev_scenario()].
transform_raw_scenarios(Cb_Module, Raw_Scenarios) ->
    {_, Scenarios} = lists:foldl(fun(Raw_Scenario, {Scenario_Num, Scenarios}) ->
                                     {Scenario_Num + 1,
                                      case exec_callback(Cb_Module, transform_raw_scenario, 
                                              [Scenario_Num, Raw_Scenario]) of
                                          {ok, {single, OneScen}} -> [[OneScen] | Scenarios];
                                          {ok, {many, ManyScens}} -> [ManyScens | Scenarios];
                                          _Error -> Scenarios
                                      end} end, 
                                  {1, []}, 
                                  Raw_Scenarios),
    lists:reverse(lists:append(Scenarios)).

-spec verify_all_scenarios(module(), Scenarios :: [scenev_scenario()]) -> scenev_result().
%% @doc
%%   Given a module and corresponding scenarios, generate observed test cases and
%%   validate that they all pass.
%% @end
verify_all_scenarios(Cb_Module, Scenarios)
  when is_atom(Cb_Module), is_list(Scenarios) ->
    {Success, Success_Cases, Failed_Cases}
       = lists:foldl(run_all(Cb_Module), {true, [], []}, Scenarios),
    {Success, lists:reverse(Success_Cases), lists:reverse(Failed_Cases)}.

-type loop_acc() :: {boolean(), non_neg_integer(), [scenev_test_case()]}.
-type loop_func() :: fun(([scenev_scenario()], loop_acc()) -> loop_acc()).
-spec run_all(module()) -> loop_func().
run_all(Cb_Module)
  when is_atom(Cb_Module) ->
    fun (#scenev_scenario{instance = Case_Number} = Scenario, {Result, Successes, Failures})
      when is_integer(Case_Number), Case_Number > 0,
           is_boolean(Result),
           is_list(Successes),
           is_list(Failures) ->
        try evaluate(Cb_Module, Scenario) of
                {true,  Test_Case} -> {Result, [Test_Case | Successes], Failures};
                {false, Test_Case} -> {false,  Successes,  [Test_Case | Failures]}
        catch Error:Type ->
                error_logger:error_msg("Scenario instance ~p crashed with ~p~n  Stacktrace: ~p~n",
                                       [Scenario, {Error, Type}, erlang:get_stacktrace()]),
                {false, Successes, [Scenario | Failures]}
        end
     end.

-spec evaluate(module(), scenev_scenario()) -> {boolean(), scenev_test_case()}.
evaluate(Cb_Module, #scenev_scenario{instance = Case_Number} = Scenario)
  when is_atom(Cb_Module) ->
    {ok, Expected} = exec_callback(Cb_Module, deduce_expected,      [Scenario]),
    {ok, Observed} = exec_callback(Cb_Module, generate_observation, [Scenario]),
    {ok, Res} = exec_callback(Cb_Module, passed_test_case, [Case_Number, Observed, Expected]),
    Test_Case = #scenev_test_case{scenario = Scenario,
                                   expected_status = Expected,
                                   observed_status = Observed},
    {Res, Test_Case}.

%%-------------------------------------------------------------------
%% Internal API steps used to validate a single scenario.
%%-------------------------------------------------------------------

-spec exec_callback(module(), atom(), [any()]) -> any().
%% @private
%% @doc
%%   Executes the modules callback, and logs an error if one is found.
%% @end
exec_callback(Mod, Fun, Args)
  when is_atom(Mod), is_atom(Fun), is_list(Args)->
    try {ok, apply(Mod, Fun, Args)}
    catch Error:Type -> 
        error_logger:error_msg("Caught ~p error in ~p:~p/~p~n~p",
                [{Error, Type}, Mod, Fun, length(Args), erlang:get_stacktrace()]),
        {Error, Type}
    end.
