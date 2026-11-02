# frozen_string_literal: true

# rails/generators/active_record builds on Rails::Generators::Actions, which only
# rails/generators itself defines.
require 'rails/generators'
require 'rails/generators/active_record'

module ItOperations
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.join(__dir__, 'templates')

      def copy_migration
        migration_template 'migration.rb', 'db/migrate/install_it_operations.rb', migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
