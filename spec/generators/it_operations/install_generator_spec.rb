# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'generators/it_operations/install_generator'

RSpec.describe ItOperations::Generators::InstallGenerator do
  subject(:generator) { described_class.new([], [], destination_root: root) }

  around do |example|
    Dir.mktmpdir do |dir|
      @root = dir
      example.run
    end
  end

  attr_reader :root

  # The generator prints what it writes, which is noise in the spec output.
  def run_generator
    original = $stdout
    $stdout = StringIO.new
    generator.invoke_all
    $stdout = original
  ensure
    $stdout = original
  end

  def migration
    Dir[File.join(root, 'db/migrate/*_install_it_operations.rb')].first
  end

  it 'writes a timestamped migration' do
    run_generator

    expect(File.basename(migration)).to match(/\A\d{14}_install_it_operations\.rb\z/)
  end

  it 'creates the it_operations table' do
    run_generator

    expect(File.read(migration)).to include('create_table :it_operations do |t|',
                                            't.integer :entity_id, null: false',
                                            't.string :entity_class, null: false',
                                            't.string :operation, index: true',
                                            't.timestamps null: false')
  end

  it 'stamps the migration with the active record version of the application' do
    run_generator

    expect(File.read(migration))
      .to include("class InstallItOperations < ActiveRecord::Migration#{generator.migration_version}")
  end

  describe '#migration_version' do
    it 'is the major and minor version of active record' do
      expect(generator.migration_version)
        .to eq("[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]")
    end
  end
end
