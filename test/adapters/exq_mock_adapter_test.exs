defmodule GenQueue.ExqAdapterTest do
  use ExUnit.Case

  import GenQueue.ExqTestHelpers

  alias GenQueue.ExqMockTest
  alias GenQueue.ExqMockJob

  describe "push/2" do
    test "sends the queue and job back to the process from module" do
      {:ok, pid} = ExqMockTest.start_link()
      {:ok, _} = ExqMockTest.push("default", ExqMockJob)
      assert_receive({"default", {ExqMockJob, [], %{jid: _}}}, 5_000)
      stop_process(pid)
    end

    test "enqueues and runs job from module tuple" do
      {:ok, pid} = ExqMockTest.start_link()
      {:ok, _} = ExqMockTest.push("default", {ExqMockJob})
      assert_receive({"default", {ExqMockJob, [], %{jid: _}}}, 5_000)
      stop_process(pid)
    end

    test "enqueues and runs job from module and args" do
      {:ok, pid} = ExqMockTest.start_link()
      {:ok, _} = ExqMockTest.push("default", {ExqMockJob, ["foo", "bar"]})
      assert_receive({"default", {ExqMockJob, ["foo", "bar"], %{jid: _}}}, 5_000)
      stop_process(pid)
    end

    test "enqueues a job with :in delay" do
      {:ok, pid} = ExqMockTest.start_link()
      {:ok, _} = ExqMockTest.push("default", {ExqMockJob, [], %{in: 0}})
      assert_receive({"default", {ExqMockJob, [], %{in: _, jid: _}}}, 5_000)
      stop_process(pid)
    end

    test "enqueues a job with :at delay" do
      {:ok, pid} = ExqMockTest.start_link()
      {:ok, _} = ExqMockTest.push("default", {ExqMockJob, [], %{at: DateTime.utc_now()}})
      assert_receive({"default", {ExqMockJob, [], %{at: _, jid: _}}}, 5_000)
      stop_process(pid)
    end
  end
end

Application.put_env(:gen_queue_exq, GenQueue.ExqMockTest, adapter: GenQueue.ExqMockAdapter)

defmodule GenQueue.ExqMockTest do
  use GenQueue, otp_app: :gen_queue_exq
end

defmodule GenQueue.ExqMockJob do
end
