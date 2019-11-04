.PHONY: test test1 testname

update: Gemfile.lock

Gemfile.lock: Gemfile
	bundle install
	touch $@

# $ make test
# $ make test file=test/*.rb
# $ make test file=test/test_progressions.rb
# $ make testname file=test/test_entry_analyzer.rb name="incomplete"
file?=$(shell find . -name "*_test.rb")
test:
ifdef name
	${MAKE} exec_ruby command="./${file} \"--name=/test_\d+_.*${name}.*/\""
else
	${MAKE} exec_ruby command="$(foreach filename,$(wildcard $(file)),-r./$(filename))"
endif

# Autoload all classes into irb session
irb:
	bundle exec irb -I ./lib $(foreach filename,$(shell find ./lib -name '*.rb'),-r./$(filename))

exec_ruby:
	bundle exec ruby -w -Ilib/railway:test ${command} -e exit
