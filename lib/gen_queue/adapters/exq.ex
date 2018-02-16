defmodule GenQueue.Adapters.Exq do
  @moduledoc """
  An adapter for `GenQueue` to enable functionaility with `Exq`.
  """

  use GenQueue.Adapter

  @type job :: module | {module} | {module, any}
  @type pushed_job :: {module, list, map}

  def start_link(gen_queue, opts \\ []) do
    opts
    |> Keyword.merge(name: gen_queue)
    |> Exq.start_link()
  end

  @doc """
  Push a job for Exq to consume.

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
    do_enqueue(gen_queue, job, [], build_opts_map(opts))
  end

  def handle_push(gen_queue, {job}, opts) do
    do_enqueue(gen_queue, job, [], build_opts_map(opts))
  end

  def handle_push(gen_queue, {job, args}, opts) do
    do_enqueue(gen_queue, job, args, build_opts_map(opts))
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

  @doc false
  def build_opts_map(opts) do
    opts
    |> Enum.into(%{})
    |> Map.put_new(:queue, "default")
  end

  defp do_enqueue(gen_queue, job, args, %{delay: %DateTime{}} = opts) do
    case Exq.enqueue_at(gen_queue, opts.queue, opts.delay, job, args) do
      {:ok, jid} -> {:ok, {job, args, Map.put(opts, :jid, jid)}}
      error -> error
    end
  end

  defp do_enqueue(gen_queue, job, args, %{delay: offset} = opts) when is_integer(offset) do
    case Exq.enqueue_in(gen_queue, opts.queue, round(offset / 1000), job, args) do
      {:ok, jid} -> {:ok, {job, args, Map.put(opts, :jid, jid)}}
      error -> error
    end
  end

  defp do_enqueue(gen_queue, job, args, opts) do
    case Exq.enqueue(gen_queue, opts.queue, job, args) do
      {:ok, jid} -> {:ok, {job, args, Map.put(opts, :jid, jid)}}
      error -> error
    end
  end
end
