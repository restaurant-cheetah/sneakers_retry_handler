# frozen_string_literal: true

module Sneakers
  module Handlers
    class DelayedRetry
      def initialize(channel, queue, opts)
        @worker_queue_name = queue.name

        @channel = channel
        @opts = opts

        error_exchange_name = @opts[:error_exchange_name] || 'error_exchange'
        @error_exchange = @channel.exchange(
          error_exchange_name,
          type: 'direct',
          durable: exchange_durable?
        )

        error_queue_name = @opts[:error_queue_name] || "error.#{@worker_queue_name}"
        error_queue = @channel.queue(
          error_queue_name,
          durable: queue_durable?
        )

        error_queue.bind(@error_exchange, routing_key: @worker_queue_name)

        @max_retries = @opts[:number_of_retries] || 5
        @sleep_before_retry = @opts[:sleep_before_retry] || 0
        @retriable_errors = @opts[:retriable_errors] || []
        @on_retry = @opts[:on_retry] || proc {}
        @on_error = @opts[:on_error] || proc {}
      end

      def acknowledge(hdr, _props, _msg)
        @channel.acknowledge(hdr.delivery_tag, false)
      end

      def reject(hdr, props, msg, requeue = false)
        if requeue
          @channel.reject(hdr.delivery_tag, requeue)
        else
          handle_retry(hdr, props, msg, :reject)
        end
      end

      def error(hdr, props, msg, err)
        handle_retry(hdr, props, msg, err)
      end

      def noop(hdr, props, msg); end

      private

      def handle_retry(hdr, props, msg, reason)
        num_attempts = failure_count(props[:headers]) + 1

        if (num_attempts <= @max_retries) && retriable_on?(reason)

          sleep(@sleep_before_retry)

          @on_retry.call(reason, msg, num_attempts)

          @channel.reject(hdr.delivery_tag, false)
        else
          @on_error.call(reason, msg, num_attempts)

          error_data = {
            error: reason.to_s,
            num_attempts: num_attempts,
            failed_at: Time.now.iso8601,
          }.tap do |hash|
            if reason.is_a?(Exception)
              hash[:error_class] = reason.class.to_s
              hash[:error_message] = reason.to_s
              if reason.backtrace
                hash[:backtrace] = reason.backtrace.take(10).join(', ')
              end
            end
          end

          @error_exchange.publish(msg, routing_key: hdr.routing_key, headers: { error_data: error_data })
          @channel.acknowledge(hdr.delivery_tag, false)
        end
      end

      def retriable_on?(exception)
        @retriable_errors.map { |error_class| exception.is_a?(error_class) }.any?
      end

      def failure_count(headers)
        if headers.nil? || headers['x-death'].nil?
          0
        else
          x_death_array = headers['x-death'].select do |x_death|
            x_death['queue'] == @worker_queue_name
          end
          if x_death_array.count > 0 && x_death_array.first['count']
            x_death_array.inject(0) { |sum, x_death| sum + x_death['count'] }
          else
            x_death_array.count
          end
        end
      end

      def queue_durable?
        @opts.fetch(:queue_options, {}).fetch(:durable, false)
      end

      def exchange_durable?
        queue_durable?
      end
    end
  end
end
