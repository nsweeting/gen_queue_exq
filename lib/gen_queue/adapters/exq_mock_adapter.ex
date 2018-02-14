defmodule GenQueue.ExqMockAdapter do
  use GenQueue.Adapter

  alias GenQueue.ExqAdapter

  def start_link(gen_queue, opts \\ []) do
    opts
    |> Keyword.merge(name: gen_queue)
    |> Exq.start_link()
  end

  def handle_push(gen_queue, module, opts) when is_atom(module) do
    handle_push(gen_queue, {module}, opts)
  end

  def handle_push(_gen_queue, {module}, opts) do
    do_enqueue(module, [], ExqAdapter.build_opts_map(opts))
  end

  def handle_push(_gen_queue, {module, args}, opts) do
    do_enqueue(module, args, ExqAdapter.build_opts_map(opts))
  end

  defp do_enqueue(module, args, opts) do
    job = {module, args, Map.put(opts, :jid, UUID.uuid4())}
    if Process.whereis(:gen_queue_exq), do: send(:gen_queue_exq, job)
    {:ok, job}
  end
end
