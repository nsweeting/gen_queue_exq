defmodule GenQueue.Adapters.ExqTest do
  use ExUnit.Case

  import GenQueue.Test
  import GenQueue.ExqTestHelpers

  defmodule Enqueuer do
    Application.put_env(:gen_queue_exq, __MODULE__, adapter: GenQueue.Adapters.Exq)

    use GenQueue, otp_app: :gen_queue_exq
  end
  
  defmodule Job do
    def perform do
      send_item(Enqueuer, :performed)
    end
  
    def perform(arg1) do
      send_item(Enqueuer, {:performed, arg1})
    end

    def perform(arg1, arg2) do
      send_item(Enqueuer, {:performed, arg1, arg2})
    end
  end

  setup do
    setup_global_test_queue(Enqueuer, :test)
  end

  describe "push/2" do
    test "enqueues and runs job from module" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push(Job)
      assert_receive(:performed)
      assert {Job, [], %{queue: "default", jid: _}} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module tuple" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push({Job})
      assert_receive(:performed)
      assert {Job, [], %{queue: "default", jid: _}} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module and args" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push({Job, ["foo", "bar"]})
      assert_receive({:performed, "foo", "bar"})
      assert {Job, ["foo", "bar"], %{queue: "default", jid: _}} = job
      stop_process(pid)
    end

    test "enqueues a job with :in delay" do
      {:ok, pid} = Enqueuer.start_link(scheduler_enable: true)
      {:ok, job} = Enqueuer.push({Job, []}, [in: 0])
      assert_receive(:performed, 5_000)
      assert {Job, [], %{queue: "default", jid: _}} = job
      stop_process(pid)
    end

    test "enqueues a job with :at delay" do
      {:ok, pid} = Enqueuer.start_link(scheduler_enable: true)
      {:ok, job} = Enqueuer.push({Job, []}, [at: DateTime.utc_now()])
      assert_receive(:performed)
      assert {Job, [], %{queue: "default", jid: _}} = job
      stop_process(pid)
    end

    test "enqueues a job to a specific queue" do
      {:ok, pid} = Enqueuer.start_link(queues: ["q1", "q2"])
      {:ok, job1} = Enqueuer.push({Job, [1]}, [queue: "q1"])
      {:ok, job2} = Enqueuer.push({Job, [2]}, [queue: "q2"])
      assert_receive({:performed, 1})
      assert_receive({:performed, 2})
      assert {Job, [1], %{queue: "q1", jid: _}} = job1
      assert {Job, [2], %{queue: "q2", jid: _}} = job2
      stop_process(pid)
    end
  end

  test "enqueuer can be started as part of a supervision tree" do
    {:ok, pid} = Supervisor.start_link([{Enqueuer, []}], strategy: :one_for_one)
    {:ok, job} = Enqueuer.push(Job)
    assert_receive(:performed)
    stop_process(pid)
  end
end
