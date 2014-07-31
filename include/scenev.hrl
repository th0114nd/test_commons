%%  Proper testing occurs via automated scripting of randomly generated
%%  scenarios. Each application provides its own customized randomization,
%%  application behavior, set of event types, and a predictive engine which
%%  generates the expected solution for a given scenario. A test suite is
%%  the execution of the automated script against a collection of scenarios.

%% All types used to express the DSL description of a scenario
-type scenev_dsl_desc()    :: term().
-type scenev_dsl_status()  :: term().
-type scenev_dsl_events()  :: [term()].

%% All types used to express the live implementation of a scenario
-type scenev_live_ref()    :: term().
-type scenev_live_desc()   :: term().
-type scenev_live_status() :: term().
-type scenev_live_events() :: [term()].

%% An instance of a scenario description using DSL
-record(scenev_scenario,
        {
          instance = 0     :: non_neg_integer(),                % Scenario instance id
          scenario_desc    :: scenev_dsl_desc(),    % Description of the scenario
          initial_status   :: scenev_dsl_status(),  % Initial status for the scenario
          events = []      :: scenev_dsl_events()   % Set of events to occur during test
        }).

-type scenev_scenario() :: #scenev_scenario{}.

%% An test case is a scenario augmented with expected and observered statuses
-record(scenev_test_case,
        {
          scenario         :: scenev_scenario(),
          expected_status  :: scenev_dsl_status(),
          observed_status  :: scenev_live_status()
        }).

-type scenev_test_case() :: #scenev_test_case{}.

-type scenev_model_id()  :: term().
-type scenev_source() :: {file, file:name_all()}
                       | {dir,  file:name_all()}
                       | {mfa, {Module::module(), Function::atom(), Args::list()}}.

-type scenev_result() :: {Result :: boolean(),
                          Number_Of_Passed_Scenarios :: non_neg_integer(),
                          Failed_Scenarios :: [scenev_scenario()]}.
