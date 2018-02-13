defmodule GenQueue.ExqAdapterTest do
  use ExUnit.Case

  import GenQueue.TestHelpers

  alias GenQueue.ExqTest
  alias GenQueue.ExqJob

  describe "push/2" do
    test "enqueues and runs job from module" do
      Process.register(self(), :gen_queue_exq_test)
      {:ok, pid} = ExqTest.start_link()
      {:ok, job} = ExqTest.push("default", ExqJob)
      assert_receive(:performed, 5_000)
      assert {ExqJob, [], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module tuple" do
      Process.register(self(), :gen_queue_exq_test)
      {:ok, pid} = ExqTest.start_link()
      {:ok, job} = ExqTest.push("default", {ExqJob})
      assert_receive(:performed, 5_000)
      assert {ExqJob, [], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module and args" do
      Process.register(self(), :gen_queue_exq_test)
      {:ok, pid} = ExqTest.start_link()
      {:ok, job} = ExqTest.push("default", {ExqJob, ["foo", "bar"]})
      assert_receive({:foo, :bar}, 5_000)
      assert {ExqJob, ["foo", "bar"], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues a job with :in delay" do
      Process.register(self(), :gen_queue_exq_test)
      {:ok, pid} = ExqTest.start_link(scheduler_enable: true)
      {:ok, job} = ExqTest.push("default", {ExqJob, [], %{in: 0}})
      assert_receive(:performed, 5_000)
      assert {ExqJob, [], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues a job with :at delay" do
      Process.register(self(), :gen_queue_exq_test)
      {:ok, pid} = ExqTest.start_link(scheduler_enable: true)
      {:ok, job} = ExqTest.push("default", {ExqJob, [], %{at: DateTime.utc_now()}})
      assert_receive(:performed, 5_000)
      assert {ExqJob, [], %{jid: _}} = job
      stop_process(pid)
    end
  end
end

Application.put_env(:gen_queue_exq, GenQueue.ExqTest, adapter: GenQueue.ExqAdapter)

defmodule GenQueue.ExqTest do
  use GenQueue, otp_app: :gen_queue_exq
end

defmodule GenQueue.ExqJob do
  def perform do
    send(:gen_queue_exq_test, :performed)
  end

  def perform("foo", "bar") do
    send(:gen_queue_exq_test, {:foo, :bar})
  end
end
