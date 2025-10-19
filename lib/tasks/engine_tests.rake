# lib/tasks/engine_tests.rake

namespace :test do
  desc "Run tests from the core_engine within the host app's context"
  task :core_engine do

    # --- THIS IS THE FIX ---
    # Use Gem.loaded_specs which is a hash of loaded gems
    engine_spec = Gem.loaded_specs['core'] # <-- Changed 'your_core_engine_name' to 'core' based on your error
    # --- END OF FIX ---

    if engine_spec.nil?
      abort "Could not find 'core' gem. Is it in your Gemfile and bundled?"
    end

    # Get a list of all test files in the engine
    engine_test_files = FileList["#{engine_spec.full_gem_path}/test/**/*_test.rb"]

    # 1. Load the host application's test helper
    # This sets up the environment and Minitest.
    require File.expand_path(Rails.root.join('test/test_helper.rb'))

    puts "Running #{engine_test_files.count} tests from 'core'..."

    # 2. Require each engine test file
    # Minitest's autorun hook will register them.
    engine_test_files.each do |file|
      require file
    end

    # When this Rake task finishes, Minitest's at_exit hook
    # will run all the tests that were just required.
  end
end

# (Optional but recommended)
# Enhance the default `rails test` command to also run your engine tests
Rake::Task['test'].enhance(['test:core_engine'])
