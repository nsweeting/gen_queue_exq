defmodule GenQueue.ExqMockAdapterTest do
  use ExUnit.Case

  import GenQueue.ExqTestHelpers

  Application.put_env(:gen_queue_exq, GenQueue.ExqMockAdapterTest.Enqueuer, adapter: GenQueue.ExqMockAdapter)

  defmodule Enqueuer do
    use GenQueue, otp_app: :gen_queue_exq
  end
  
  defmodule Job do
  end

  setup do
    Process.register(self(), :test)
    :ok
  end

  describe "push/2" do
    test "sends the queue/job back to the :test process from module" do
      {:ok, _} = Enqueuer.push("default", Job)
      assert_receive({"default", {Job, [], %{jid: _}}}, 5_000)
    end

    test "sends the queue/job back to the :test process from module tuple" do
      {:ok, _} = Enqueuer.push("default", {Job})
      assert_receive({"default", {Job, [], %{jid: _}}}, 5_000)
    end

    test "sends the queue/job back to the :test process from module and args" do
      {:ok, _} = Enqueuer.push("default", {Job, ["foo", "bar"]})
      assert_receive({"default", {Job, ["foo", "bar"], %{jid: _}}}, 5_000)
    end

    test "sends the queue/job back to the :test process with :in delay" do
      {:ok, _} = Enqueuer.push("default", {Job, [], %{in: 0}})
      assert_receive({"default", {Job, [], %{in: _, jid: _}}}, 5_000)
    end

    test "sends the queue/job back to the :test process with :at delay" do
      {:ok, _} = Enqueuer.push("default", {Job, [], %{at: DateTime.utc_now()}})
      assert_receive({"default", {Job, [], %{at: _, jid: _}}}, 5_000)
    end
  end
end
