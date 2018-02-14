defmodule GenQueue.ExqAdapter do
  use GenQueue.Adapter

  @default_opts %{
    queue: "default"
  }

  def start_link(gen_queue, opts \\ []) do
    opts
    |> Keyword.merge(name: gen_queue)
    |> Exq.start_link()
  end

  def handle_push(gen_queue, module, opts) when is_atom(module) do
    do_enqueue(gen_queue, module, [], build_opts_map(opts))
  end

  def handle_push(gen_queue, {module}, opts) do
    do_enqueue(gen_queue, module, [], build_opts_map(opts))
  end

  def handle_push(gen_queue, {module, args}, opts) do
    do_enqueue(gen_queue, module, args, build_opts_map(opts))
  end

  def build_opts_map(opts) do
    opts = Enum.into(opts, %{})
    Map.merge(@default_opts, opts)
  end

  defp do_enqueue(gen_queue, module, args, %{in: _} = opts) do
    case Exq.enqueue_in(gen_queue, opts.queue, opts.in, module, args) do
      {:ok, jid} -> {:ok, {module, args, Map.put(opts, :jid, jid)}}
      error -> error
    end
  end

  defp do_enqueue(gen_queue, module, args, %{at: _} = opts) do
    case Exq.enqueue_at(gen_queue, opts.queue, opts.at, module, args) do
      {:ok, jid} -> {:ok, {module, args, Map.put(opts, :jid, jid)}}
      error -> error
    end
  end

  defp do_enqueue(gen_queue, module, args, opts) do
    case Exq.enqueue(gen_queue, opts.queue, module, args) do
      {:ok, jid} -> {:ok, {module, args, Map.put(opts, :jid, jid)}}
      error -> error
    end
  end
end
