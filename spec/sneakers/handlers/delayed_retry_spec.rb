# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sneakers::Handlers::DelayedRetry do
  describe 'as handler of the worker' do
    class HandledError < StandardError; end
    class UnhandledError < StandardError; end

    class BusyWorker
      include Sneakers::Worker

      def work(msg)
        perform(msg)

        ack!
      end

      private

      def perform(msg); end
    end

    Sneakers.configure(daemonize: true, log: 'log/test.log')
    Sneakers::Worker.configure_logger(Logger.new('/dev/null'))
    Sneakers::Worker.configure_metrics

    let(:handler) { described_class.new(channel, queue, opts) }

    let(:channel) do
      double(:channel, exchange: error_exchange, queue: queue, acknowledge: 'ack', reject: 'reject')
    end

    let(:queue) { double(:queue, name: 'queue_name', bind: nil, opts: {}) }
    let(:error_exchange) { double(:error_exchange, publish: 'publish') }
    let(:delivery_info) do
      double(:delivery_info, routing_key: 'routing.key', delivery_tag: 'delivery.tag', reject: {}, each: [])
    end
    let(:metadata) { { headers: { retry_info: {}.to_json } } }
    let(:test_pool) { Concurrent::ImmediateExecutor }
    let(:msg) { { key: :value }.to_json }
    let(:opts) { { on_retry: on_retry_cb, on_error: on_error_cb } }
    let(:on_retry_cb) { proc {} }
    let(:on_error_cb) { proc {} }

    subject do
      BusyWorker.new(
        queue,
        test_pool.new
      ).do_work(
        delivery_info,
        metadata,
        msg,
        handler
      )
    end

    context 'without errors' do
      before do
        allow_any_instance_of(BusyWorker).to receive(:perform).with(msg).and_return(msg)
      end

      it 'calls acknowledge' do
        expect(handler).to receive(:acknowledge).once
        subject
      end
    end

    context 'with an unhandlen error' do
      before do
        allow_any_instance_of(BusyWorker).to receive(:perform).with(msg).and_raise(UnhandledError)
      end

      it 'calls handle_retry method' do
        expect(handler).to receive(:error).once
        subject
      end

      it 'calls on_error callback' do
        expect(on_error_cb).to receive(:call).once
        subject
      end
    end

    context 'with a handled error' do
      let(:opts) { super().merge(retriable_errors: [HandledError]) }

      before do
        allow_any_instance_of(BusyWorker).to receive(:perform).with(msg).and_raise(HandledError)
      end

      it 'calls handle_retry method' do
        expect(handler).to receive(:error).once
        subject
      end

      it 'calls on_retry_cb callback' do
        expect(on_retry_cb).to receive(:call).once
        subject
      end
    end
  end
end
