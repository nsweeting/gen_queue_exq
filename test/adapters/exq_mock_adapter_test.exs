defmodule GenQueue.ExqMockAdapterTest do
  use ExUnit.Case

  Application.put_env(:gen_queue_exq, GenQueue.ExqMockAdapterTest.Enqueuer, adapter: GenQueue.ExqMockAdapter)

  defmodule Enqueuer do
    use GenQueue, otp_app: :gen_queue_exq
  end
  
  defmodule Job do
  end

  setup do
    Process.register(self(), :gen_queue_exq)
    :ok
  end

  describe "push/2" do
    test "sends the job back to the registered process from module" do
      {:ok, _} = Enqueuer.push(Job)
      assert_receive({Job, [], %{jid: _}})
    end

    test "sends the job back to the registered process from module tuple" do
      {:ok, _} = Enqueuer.push({Job})
      assert_receive({Job, [], %{jid: _}})
    end

    test "sends the job back to the registered process from module and args" do
      {:ok, _} = Enqueuer.push({Job, ["foo", "bar"]})
      assert_receive({Job, ["foo", "bar"], %{jid: _}})
    end

    test "sends the job back to the registered process with :in delay" do
      {:ok, _} = Enqueuer.push({Job, []}, [in: 0])
      assert_receive({Job, [], %{in: _, jid: _}})
    end

    test "sends the job back to the registered process with :at delay" do
      {:ok, _} = Enqueuer.push({Job, []}, [at: DateTime.utc_now()])
      assert_receive({Job, [], %{at: _, jid: _}})
    end

    test "does nothing if process is not registered" do
      Process.unregister(:gen_queue_exq)
      {:ok, _} = Enqueuer.push(Job)
    end
  end
end
