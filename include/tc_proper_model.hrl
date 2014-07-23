%%  Proper testing occurs via automated scripting of randomly generated
%%  scenarios. Each application provides its own customized randomization,
%%  application behavior, set of event types, and a predictive engine which
%%  generates the expected solution for a given scenario. A test suite is
%%  the execution of the automated script against a collection of scenarios.

%% All types used to express the DSL description of a scenario
-type tcb_scenario_dsl_desc()    :: term().
-type tcb_scenario_dsl_status()  :: term().
-type tcb_scenario_dsl_events()  :: [term()].

%% All types used to express the live implementation of a scenario
-type tcb_scenario_live_ref()    :: term().
-type tcb_scenario_live_desc()   :: term().
-type tcb_scenario_live_status() :: term().
-type tcb_scenario_live_events() :: [term()].

%% An instance of a scenario description using DSL
-record(tcb_scenario,
        {
          instance = 0     :: non_neg_integer(),                % Scenario instance id
          scenario_desc    :: tcb_scenario_dsl_desc(),    % Description of the scenario
          initial_status   :: tcb_scenario_dsl_status(),  % Initial status for the scenario
          events           :: tcb_scenario_dsl_events()   % Set of events to occur during test
        }).

-type tcb_scenario() :: #tcb_scenario{}.

%% An test case is a scenario augmented with expected and observered statuses
-define(TC_MISSING_TEST_CASE_ELEMENT, '$$_not_generated').

-record(tcb_test_case,
        {
          scenario        :: tcb_scenario(),
          expected_status  = ?TC_MISSING_TEST_CASE_ELEMENT :: tcb_scenario_dsl_status()
                                                            | ?TC_MISSING_TEST_CASE_ELEMENT,
          observed_status  = ?TC_MISSING_TEST_CASE_ELEMENT :: tcb_scenario_live_status()
                                                            | ?TC_MISSING_TEST_CASE_ELEMENT
        }).

-type tcb_test_case() :: #tcb_test_case{}.

-type tcb_model_id()     :: term().
-type tcb_model_source() :: {file, file:name_all()}
                                | {mfa, {Module::module(), Function::atom(), Args::list()}}.

%% The full Test Common Behavior model
-record(tcb_model,
        {
          id             :: tcb_model_id(),      % Unique identifier
          source         :: tcb_model_source(),  % Source of the model
          behaviour      :: module(),                  % Implementation of the tcb_model behaviour
          scenarios = [] :: [tcb_scenario()]     % A set of scenarios to be tested
        }).

-type tcb_model()        :: #tcb_model{}.
-type tcb_model_result() :: {boolean(), Number_Of_Passed_Scenarios :: pos_integer(),
                                   Failed_Scenarios :: [tcb_scenario()]}.
