defmodule GenQueueExq.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_queue_exq,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_queue, "~> 0.1.2"},
      {:exq, "~> 0.10.1", runtime: false}
    ]
  end
end
