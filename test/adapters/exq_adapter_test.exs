defmodule GenQueue.ExqAdapterTest do
  use ExUnit.Case

  import GenQueue.ExqTestHelpers

  Application.put_env(:gen_queue_exq, GenQueue.ExqAdapterTest.Enqueuer, adapter: GenQueue.ExqAdapter)

  defmodule Enqueuer do
    use GenQueue, otp_app: :gen_queue_exq
  end
  
  defmodule Job do
    def perform do
      send(:test, :performed)
    end
  
    def perform("foo", "bar") do
      send(:test, {:foo, :bar})
    end
  end

  setup do
    Process.register(self(), :test)
    :ok
  end

  describe "push/2" do
    test "enqueues and runs job from module" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push("default", Job)
      assert_receive(:performed, 5_000)
      assert {Job, [], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module tuple" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push("default", {Job})
      assert_receive(:performed, 5_000)
      assert {Job, [], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module and args" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push("default", {Job, ["foo", "bar"]})
      assert_receive({:foo, :bar}, 5_000)
      assert {Job, ["foo", "bar"], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues a job with :in delay" do
      {:ok, pid} = Enqueuer.start_link(scheduler_enable: true)
      {:ok, job} = Enqueuer.push("default", {Job, [], %{in: 0}})
      assert_receive(:performed, 5_000)
      assert {Job, [], %{jid: _}} = job
      stop_process(pid)
    end

    test "enqueues a job with :at delay" do
      {:ok, pid} = Enqueuer.start_link(scheduler_enable: true)
      {:ok, job} = Enqueuer.push("default", {Job, [], %{at: DateTime.utc_now()}})
      assert_receive(:performed, 5_000)
      assert {Job, [], %{jid: _}} = job
      stop_process(pid)
    end
  end
end
