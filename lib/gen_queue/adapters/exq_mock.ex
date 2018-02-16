defmodule GenQueue.Adapters.ExqMock do
  @moduledoc """
  An adapter for `GenQueue` to enable mock functionaility with `Exq`.
  """

  use GenQueue.Adapter

  alias GenQueue.Adapters.Exq, as: ExqAdapter

  def start_link(_gen_queue, _opts) do
    :ignore
  end

  @doc """
  Push a job that will be returned to the current (or globally set) processes
  mailbox. Please see `GenQueue.Test` for further details.

  ## Parameters:
    * `gen_queue` - Any GenQueue module
    * `job` - Any valid job format
    * `opts` - A keyword list of job options

  ## Options
    * `:queue` - The queue to push the job to. Defaults to "default".
    * `:delay` - Either a `DateTime` or millseconds-based integer.

  ## Returns:
    * `{:ok, {module, args, opts}}` if the operation was successful
    * `{:error, reason}` if there was an error
  """
  @spec handle_push(GenQueue.t(), GenQueue.Adapters.Exq.job(), list) ::
          {:ok, GenQueue.Adapters.Exq.pushed_job()} | {:error, any}
  def handle_push(gen_queue, job, opts) when is_atom(job) do
    do_return(gen_queue, job, [], ExqAdapter.build_opts_map(opts))
  end

  def handle_push(gen_queue, {job}, opts) do
    do_return(gen_queue, job, [], ExqAdapter.build_opts_map(opts))
  end

  def handle_push(gen_queue, {job, args}, opts) when is_list(args) do
    do_return(gen_queue, job, args, ExqAdapter.build_opts_map(opts))
  end

  def handle_push(gen_queue, {job, arg}, opts) do
    do_enqueue(gen_queue, job, [arg], ExqAdapter.build_opts_map(opts))
  end

  @doc false
  def handle_pop(_gen_queue, _opts) do
    {:error, :not_implemented}
  end

  @doc false
  def handle_flush(_gen_queue, _opts) do
    {:error, :not_implemented}
  end

  @doc false
  def handle_length(_gen_queue, _opts) do
    {:error, :not_implemented}
  end

  defp do_return(gen_queue, job, args, opts) do
    full_job = {job, args, Map.put(opts, :jid, UUID.uuid4())}
    GenQueue.Test.send_item(gen_queue, full_job)
    {:ok, full_job}
  end
end
