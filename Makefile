PROJECT = test_commons

DIALYZER_OPTS := -Werror_handling \
			     -Wrace_conditions \
			     -Wunmatched_returns 

include erlang.mk

data:
	curl -o priv/application.csv http://www.iana.org/assignments/media-types/application.csv

csv: data # Extract the middle component and put it in a binary, then remove empties and the pattern.
	cut -d , -f 2 priv/application.csv \
		|   sed 's/\(.*\)/"\1"./'\
		|   grep -v '""'        \
		|   grep -v Template    \
		>   priv/mimes.edata

clean-data:
	rm priv/application.csv
	rm priv/mimes.edata
