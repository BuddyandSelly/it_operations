# frozen_string_literal: true

require_relative 'it_operations/version'
require 'active_support'
# SingleForwardable below, which the standard library does not load by itself.
require 'forwardable'

ActiveSupport.on_load(:active_record) do
  require 'it_operations/it_operation'
  include ItOperations
end

module ItOperations
  extend SingleForwardable

  BATCH_SIZE = ENV.fetch('IT_OPERATIONS_BATCH_SIZE', 1000).to_i

  # ItOperation is an ActiveRecord model, so it is only required once active record
  # itself is loaded, see the hook above. Naming the target as a string leaves the
  # constant to be resolved on the first call instead of here.
  def_delegators 'ItOperations::ItOperation', :by_op, :processed, :unprocessed, :unsuccessful, :successful

  def self.entities_for_operation(operation)
    entities_by_operation = by_op(operation).group(:entity_class).count
    entities_given_operation = entities_by_operation.keys.count
    raise 'All entities need to be the same for a given operation' if entities_given_operation > 1
    return [] if entities_given_operation.zero?

    ids = by_op(operation).pluck(:entity_id)
    entities_by_operation.keys.first.constantize.where(id: ids)
  end

  # rubocop: disable-next Metrics/MethodLength
  def self.create_from_entity_ids(entity_ids, entity_class, operation)
    date = Time.now
    base = {
      entity_class: entity_class,
      operation: operation,
      successful: false,
      processed: false,
      result: nil,
      arguments: nil,
      created_at: date,
      updated_at: date
    }
    entity_ids.in_groups_of(BATCH_SIZE, false) do |group|
      ItOperations::ItOperation.insert_all(group.map do |entity_id|
        { entity_id: entity_id }.merge(base)
      end)
    end
  end

  # Helper method to reduce "boilerplate" around executing an operation
  #
  # Example:
  # Given the following it operations in the database:
  # { entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 1, arguments: 'arg1' }
  # { entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 2, arguments: 'arg2' }
  # { entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 3, arguments: 'arg3' }
  # { entity_class: 'Order', operation: 'OTHER_OP',  entity_id: 1, arguments: 'arg4' }
  #
  # ItOperations.run("SAMPLE_OP") do |order, args|
  #   puts "Doing something with #{order.id} and #{args}"
  # end
  # Should print:
  # Doing something with 1 and arg1
  # Doing something with 2 and arg2
  # Doing something with 3 and arg3
  #
  def self.run(operation_name, succeed_msg = 'done')
    operations = by_op(operation_name).unprocessed
    operations.in_batches(of: BATCH_SIZE).each_record do |operation|
      yield operation.entity, operation.arguments
      operation.mark_successful!(succeed_msg)
    rescue StandardError => e
      operation.mark_failed!(e.message)
    end
  end
end
