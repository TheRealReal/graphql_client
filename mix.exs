defmodule GraphqlClient.MixProject do
  use Mix.Project

  @source_url "https://github.com/TheRealReal/graphql_client"
  @version "0.1.0"

  def project do
    [
      app: :graphql_client,
      version: @version,
      name: "GraphQL Client",
      description: " A composable GraphQL client library for Elixir",
      elixir: "~> 1.11",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["TheRealReal"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/graphql_client",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md": [filename: "changelog", title: "Changelog"],
        "CODE_OF_CONDUCT.md": [filename: "code_of_conduct", title: "Code of Conduct"],
        LICENSE: [filename: "license", title: "License"],
        NOTICE: [filename: "notice", title: "Notice"]
      ]
    ]
  end
end
