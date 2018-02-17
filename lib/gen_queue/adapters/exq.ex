defmodule GenQueue.Adapters.Exq do
  @moduledoc """
  An adapter for `GenQueue` to enable functionaility with `Exq`.
  """

  use GenQueue.JobAdapter

  alias GenQueue.Job

  def start_link(gen_queue, opts \\ []) do
    opts
    |> Keyword.merge(name: gen_queue)
    |> Exq.start_link()
  end

  @doc """
  Push a `GenQueue.Job` for Exq to consume.

  ## Parameters:
    * `gen_queue` - A `GenQueue` module
    * `job` - A `GenQueue.Job`

  ## Returns:
    * `{:ok, job}` if the operation was successful
    * `{:error, reason}` if there was an error
  """
  @spec handle_job(gen_queue :: GenQueue.t(), job :: GenQueue.Job.t()) ::
          {:ok, GenQueue.Job.t()} | {:error, any}
  def handle_job(gen_queue, %Job{queue: nil} = job) do
    handle_job(gen_queue, %{job | queue: "default"})
  end

  def handle_job(gen_queue, %Job{delay: %DateTime{}} = job) do
    case Exq.enqueue_at(gen_queue, job.queue, job.delay, job.module, job.args) do
      {:ok, _} -> {:ok, job}
      error -> error
    end
  end

  def handle_job(gen_queue, %Job{delay: offset} = job) when is_integer(offset) do
    case Exq.enqueue_in(gen_queue, job.queue, round(offset / 1000), job.module, job.args) do
      {:ok, _} -> {:ok, job}
      error -> error
    end
  end

  def handle_job(gen_queue, job) do
    case Exq.enqueue(gen_queue, job.queue, job.module, job.args) do
      {:ok, _} -> {:ok, job}
      error -> error
    end
  end
end
