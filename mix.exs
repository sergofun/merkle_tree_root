defmodule MerkleTreeRoot.MixProject do
  use Mix.Project

  def project do
    [
      app: :merkle_tree_root,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flow, "~> 1.1"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.4.0", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.5", only: :test}
    ]
  end
end
