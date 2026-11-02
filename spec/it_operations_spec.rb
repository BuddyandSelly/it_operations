# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ItOperations do
  let(:operation_klass) { ItOperations::ItOperation }
  it 'has a version number' do
    expect(ItOperations::VERSION).not_to be_nil
  end

  describe '.entities_for_operation' do
    it 'returns the entities the operations of that name point at' do
      entity = operation_klass.create(entity_id: 1, entity_class: 'Test', operation: 'create entity')
      it_operation = operation_klass.create(entity_id: entity.id, entity_class: operation_klass.name,
                                            operation: 'test')

      expect(described_class.entities_for_operation(it_operation.operation)).to eq([entity])
    end

    it 'returns nothing for an operation that has none' do
      expect(described_class.entities_for_operation('nothing here')).to eq([])
    end

    it 'refuses an operation that spans more than one entity class' do
      operation_klass.create(entity_id: 1, entity_class: 'Test', operation: 'mixed')
      operation_klass.create(entity_id: 2, entity_class: operation_klass.name, operation: 'mixed')

      expect { described_class.entities_for_operation('mixed') }
        .to raise_error('All entities need to be the same for a given operation')
    end
  end

  it '.create_from_entity_ids' do
    stub_const("#{described_class}::BATCH_SIZE", 1)
    ids = [1, 2]
    allow(ItOperations::ItOperation).to receive(:insert_all).and_call_original
    described_class.create_from_entity_ids(ids, 'Test', 'create entity')
    expect(operation_klass.count).to eq(ids.count)
    expect(ItOperations::ItOperation).to have_received(:insert_all).twice
  end

  describe '.run' do
    let(:it_operation) { operation_klass.new(entity_class: operation_klass.name, operation: 'test') }

    before do
      entity = operation_klass.create(entity_id: 1, entity_class: 'Test')
      it_operation.entity_id = entity.id
      it_operation.save
    end

    it 'runs in batches' do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      described_class.create_from_entity_ids([1, 2], operation_klass.name, 'test operation')
      described_class.run('test operation') { true }

      expect(operation_klass.where(operation: 'test operation')).to all(be_processed)
      expect(operation_klass.where(operation: 'test operation')).to all(be_successful)
    end

    context 'when the operation succeeds' do
      let(:run_operation) do
        described_class.run(it_operation.operation, 'succeed!') { true }
      end

      it 'stores the result' do
        expect do
          run_operation
          it_operation.reload
        end.to change(it_operation, :result).to('succeed!')
      end

      it 'marks it as successful' do
        expect do
          run_operation
          it_operation.reload
        end.to change(it_operation, :successful).from(false).to(true)
      end
    end

    context 'when the operation fails' do
      let(:run_operation) do
        described_class.run(it_operation.operation) { raise 'Some Error' }
      end

      it 'stores the result' do
        expect do
          run_operation
          it_operation.reload
        end.to change(it_operation, :result).to('Some Error')
      end

      it 'marks it as failed' do
        expect do
          run_operation
          it_operation.reload
        end.to change {
          [it_operation.processed, it_operation.successful, it_operation.result]
        }.from([false, false, nil]).to([true, false, 'Some Error'])
      end
    end
  end
end
