PROJECT = test_commons

DIALYZER_OPTS := test/test_commons -Werror_handling \
								   -Wrace_conditions \
								   -Wunmatched_returns 

include erlang.mk
