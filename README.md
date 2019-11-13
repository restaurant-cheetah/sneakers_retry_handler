## SneakersRetryHandler

Run your worker with delayed retrying.
Define `on_retry` and `on_error` callbacks.

## Install

```ruby
gem install sneakers_retry_handler
```
## Usage of the `DelayedRetry`

The `DelayedRetry` handler is an extension of the default `MaxRetry` handler.
It will try to process the message specified number of times.
When the maximum number of retries is reached it will put the message on an error queue.

When defining your worker, you have to define these extra arguments:

- `number_of_retries`: Specifies how many times to retry.

- `sleep_before_retry`: Retrying delay.

- `retriable_errors`: The list of errors. Puts the message on an error queue otherwise.

- `x-dead-letter-exchange`: The name of the dead-letter exchange where failed messages will be published to.

- `on_retry` and `on_error`: Callbacks.


Here's an example:

```diff
class BusyWorker
  include Sneakers::Worker

  from_queue(
    'busy_worker_queue',
+   exchange: 'retry_exchange',
+   exchange_type: :topic,
+   handler: Sneakers::Handlers::DelayedRetry,
+   arguments: {
+     'x-dead-letter-exchange': 'retry_exchange'
+   },
+   number_of_retries: 3,
+   sleep_before_retry: 2,
+   retriable_errors: [Faraday::TimeoutError],
+   on_retry: proc do |error, payload, tries|
+     /* put your logic here */
+   end,
+   on_error: proc do |error, payload, tries|
+     /* put your logic here */
+   end
  )

  def work(*args)
    ack!
  end
end
```
