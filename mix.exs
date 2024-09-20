defmodule ErrorMessageShorts.MixProject do
  use Mix.Project

  @source_url "https://github.com/cylkdev/error_message_shorts"
  @version "0.1.0"

  def project do
    [
      app: :error_message_shorts,
      version: @version,
      elixir: "~> 1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Declarative comparisons and changes",
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        dialyzer: :test,
        coveralls: :test,
        "coveralls.lcov": :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test
      ],
      dialyzer: [
        plt_add_apps: [
          :ex_unit,
          :decimal,
          :mix
        ],
        list_unused_filters: true,
        plt_local_path: "dialyzer",
        plt_core_path: "dialyzer",
        flags: [:unmatched_returns]
      ]
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
      {:ex_doc, "~> 0.1", runtime: false},
      {:excoveralls, "~> 0.14.0", runtime: false},
      {:dialyxir, "~> 1.0", runtime: false},
      {:credo, "~> 1.0", runtime: false},
      {:substitute_x, git: "https://github.com/cylkdev/substitute_x.git", branch: "main"}
    ]
  end

  defp package do
    [
      maintainers: ["Kurt Hogarth"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/cylkdev/error_message_shorts"},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/cylkdev/error_message_shorts",
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.txt": [title: "License"],
        "README.md": [title: "Readme"]
      ],
      source_url: @source_url,
      source_ref: @version,
      api_reference: false,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
