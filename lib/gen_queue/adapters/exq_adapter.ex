defmodule GenQueue.ExqAdapter do
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

  defp do_enqueue(gen_queue, queue, {module, args, %{in: offset} = meta}) do
    case Exq.enqueue_in(gen_queue, queue, offset, module, args) do
      {:ok, jid} -> {:ok, {module, args, Map.put(meta, :jid, jid)}}
      error -> error
    end
  end

  defp do_enqueue(gen_queue, queue, {module, args, %{at: time} = meta}) do
    case Exq.enqueue_at(gen_queue, queue, time, module, args) do
      {:ok, jid} -> {:ok, {module, args, Map.put(meta, :jid, jid)}}
      error -> error
    end
  end

  defp do_enqueue(gen_queue, queue, {module, args, meta}) do
    case Exq.enqueue(gen_queue, queue, module, args) do
      {:ok, jid} -> {:ok, {module, args, Map.put(meta, :jid, jid)}}
      error -> error
    end
  end
end
