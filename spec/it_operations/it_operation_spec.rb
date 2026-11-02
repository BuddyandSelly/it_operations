require 'spec_helper'

RSpec.describe ItOperations::ItOperation do
  let(:it_operation) { described_class.new(entity_id: 1, operation: 'test', entity_class: 'Test') }

  describe '.mark_successful' do
    it 'mark itself as successful' do
      it_operation.mark_successful
      expect(it_operation.successful).to be(true)
    end

    it 'bang version (!) calls mark_successful and persists' do
      allow(it_operation).to receive(:mark_successful)
      it_operation.mark_successful!
      expect(it_operation).to have_received(:mark_successful)
      expect(it_operation).to be_persisted
    end

    it 'mark itself as processed' do
      it_operation.mark_successful
      expect(it_operation.processed).to be(true)
    end

    it 'can set result with message' do
      msg = 'Some Response'
      it_operation.mark_successful(msg)
      expect(it_operation.result).to eq(msg)
    end
  end

  describe '.mark_failed' do
    it 'mark itself as not successful' do
      it_operation.mark_failed
      expect(it_operation.successful).to be(false)
    end

    it 'bang version (!) calls mark_failed and persists' do
      allow(it_operation).to receive(:mark_failed)
      it_operation.mark_failed!
      expect(it_operation).to have_received(:mark_failed)
      expect(it_operation).to be_persisted
    end

    it 'mark itself as processed' do
      it_operation.mark_failed
      expect(it_operation.processed).to be(true)
    end

    it 'can set result with message' do
      msg = 'Some Response'
      it_operation.mark_failed(msg)
      expect(it_operation.result).to eq(msg)
    end
  end

  it '#klass' do
    expect(it_operation.klass).to eq(Test)
  end

  it '#entity' do
    it_operation.save
    it_op = described_class.new(entity_id: it_operation.id, operation: 'test', entity_class: described_class.name)
    expect(it_op.entity).to eq(it_operation)
  end
end

# A stand-in for an application model: the specs only ever name it, as the
# entity_class of an operation.
Test = Class.new
