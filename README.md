# GenQueue Exq
[![Build Status](https://travis-ci.org/nsweeting/gen_queue_exq.svg?branch=master)](https://travis-ci.org/nsweeting/gen_queue_exq)
[![GenQueue Exq Version](https://img.shields.io/hexpm/v/gen_queue_exq.svg)](https://hex.pm/packages/gen_queue_exq)

This is an adapter for [GenQueue](https://github.com/nsweeting/gen_queue) to enable
functionaility with [Exq](https://github.com/akira/exq).

## Installation

The package can be installed by adding `gen_queue_exq` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_queue_exq, "~> 0.1.3"}
  ]
end
```

## Documentation

See [HexDocs](https://hexdocs.pm/gen_queue_exq) for additional documentation.

## Configuration

Before starting, please refer to the [Exq](https://github.com/akira/exq) documentation
for details on configuration. This adapter handles zero `Exq` related config.

## Creating Enqueuers

We can start off by creating a new `GenQueue` module, which we will use to push jobs to
Exq.

```elixir
defmodule Enqueuer do
  use GenQueue, otp_app: :my_app
end
```

Once we have our module setup, ensure we have our config pointing to the `GenQueue.Adapters.Exq`
adapter.

```elixir
config :my_app, Enqueuer, [
  adapter: GenQueue.Adapters.Exq
]
```

## Starting Enqueuers

By default, `gen_queue_exq` does not start Exq on application start. So we must add
our new `Enqueuer` module to our supervision tree.

```elixir
  children = [
    supervisor(Enqueuer, []),
  ]
```

## Creating Jobs

Jobs are simply modules with a `perform` method.

```elixir
defmodule MyJob do
  def perform(arg1) do
    IO.inspect(arg1)
  end
end
```

## Enqueuing Jobs

We can now easily enqueue jobs to `Exq`. The adapter will handle a variety of argument formats.

```elixir
# Push MyJob to "default" queue
{:ok, job} = Enqueuer.push(MyJob)

# Push MyJob to "default" queue
{:ok, job} = Enqueuer.push({MyJob})

# Push MyJob to "default" queue with "arg1"
{:ok, job} = Enqueuer.push({MyJob, "arg1"})

# Push MyJob to "default" queue with no args
{:ok, job} = Enqueuer.push({MyJob, []})

# Push MyJob to "default" queue with "arg1" and "arg2"
{:ok, job} = Enqueuer.push({MyJob, ["arg1", "arg2"]})

# Push MyJob to "foo" queue with "arg1"
{:ok, job} = Enqueuer.push({MyJob, "arg1"}, [queue: "foo"])

# Schedule MyJob to "default" queue with "arg1" in 10 seconds
{:ok, job} = Enqueuer.push({MyJob, "arg1"}, [delay: 10_000])

# Schedule MyJob to "default" queue with "arg1" at a specific time
date = DateTime.utc_now()
{:ok, job} = Enqueuer.push({MyJob, "arg1"}, [delay: date])
```

## Testing

Optionally, we can also have our tests use the `GenQueue.Adapters.MockJob` adapter.

```elixir
config :my_app, Enqueuer, [
  adapter: GenQueue.Adapters.MockJob
]
```

This mock adapter uses the standard `GenQueue.Test` helpers to send the job payload
back to the current processes mailbox (or another named process) instead of actually
enqueuing the job to redis.

```elixir
defmodule MyJobTest do
  use ExUnit.Case, async: true

  import GenQueue.Test

  setup do
    setup_test_queue(Enqueuer)
  end

  test "my enqueuer works" do
    {:ok, _} = Enqueuer.push(Job)
    assert_receive(%GenQueue.Job{module: Job, args: []})
  end
end
```

If your jobs are being enqueued outside of the current process, we can use named
processes to recieve the job. This wont be async safe.

```elixir
import GenQueue.Test

setup do
  setup_global_test_queue(Enqueuer, :my_process_name)
end
```
