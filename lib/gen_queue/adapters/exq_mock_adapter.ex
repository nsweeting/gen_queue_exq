defmodule GenQueue.ExqMockAdapter do
  use GenQueue.Adapter

  def start_link(gen_queue, opts \\ []) do
    opts
    |> Keyword.merge(name: gen_queue)
    |> Exq.start_link()
  end

  def handle_push(gen_queue, queue, module) when is_atom(module) do
    do_enqueue(gen_queue, queue, {module, [], %{}})
  end

  def handle_push(gen_queue, queue, {module}) do
    do_enqueue(gen_queue, queue, {module, [], %{}})
  end

  def handle_push(gen_queue, queue, {module, args}) do
    do_enqueue(gen_queue, queue, {module, args, %{}})
  end

  def handle_push(gen_queue, queue, {_module, _args, _meta} = job) do
    do_enqueue(gen_queue, queue, job)
  end

  defp do_enqueue(gen_queue, queue, {module, args, meta}) do
    job = {module, args, Map.put(meta, :jid, UUID.uuid4())}
    send(self(), {queue, job})
    {:ok, job}
  end
end
