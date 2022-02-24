defmodule GraphQL.Client do
  @moduledoc """
  Facade client for GraphQL requests

  The real backend must implement the execute/4 callback and must be configured
  by the `:therealreal, GraphQL.Client, :backend` application
  config.
  """
  alias GraphQL.{Query, Response}

  @type query :: Query.t() | {String.t(), reference()} | String.t()

  @doc """
  Callback spec for backend implementation
  """
  @callback execute_query(
              query :: Query.t(),
              variables :: map(),
              options :: map()
            ) :: Response.t()

  @doc """
  Executes the given query, with the given variables and options.
  """
  @spec execute(Query.t(), map(), map()) :: Response.t()
  def execute(%Query{} = query, variables, options \\ %{}) do
    backend().execute_query(query, variables, options)
  end

  defp backend do
    Application.fetch_env!(:graphql_client, :backend)
  end
end
