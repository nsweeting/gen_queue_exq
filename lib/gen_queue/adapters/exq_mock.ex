defmodule GenQueue.Adapters.ExqMock do
  use GenQueue.Adapter

  alias GenQueue.Adapters.Exq, as: ExqAdapter

  def start_link(_gen_queue, _opts) do
    :ignore
  end

  def handle_push(gen_queue, module, opts) when is_atom(module) do
    do_return(gen_queue, module, [], ExqAdapter.build_opts_map(opts))
  end

  def handle_push(gen_queue, {module}, opts) do
    do_return(gen_queue, module, [], ExqAdapter.build_opts_map(opts))
  end

  def handle_push(gen_queue, {module, args}, opts) do
    do_return(gen_queue, module, args, ExqAdapter.build_opts_map(opts))
  end

  defp do_return(gen_queue, module, args, opts) do
    job = {module, args, Map.put(opts, :jid, UUID.uuid4())}
    GenQueue.Test.send_item(gen_queue, job)
    {:ok, job}
  end
end
