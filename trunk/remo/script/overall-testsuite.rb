#!/usr/bin/env ruby
#
# Overall testsuite for project remo
#

require "test/unit"

# testcases below are started automatically

# libs
require "./test/functional/various_test"
require "./test/functional/rules_generator_test"

# models
require "./test/unit/request_test"
require "./test/unit/header_test"
require "./test/unit/postparameter_test"

# views / controller
require "./test/functional/main_controller_test"
require "./test/functional/generate_requestrule_controller_test"

# application
require "./test/integration/user_story6_test"

