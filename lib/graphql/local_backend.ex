defmodule GraphQL.LocalBackend do
  @moduledoc """
  A `GraphQL.Client` implementation that uses an `Agent` to store data, useful
  for tests.
  """
  use Agent

  alias GraphQL.Response

  @behaviour GraphQL.Client

  def start_link do
    Application.put_env(:graphql_client, :backend, __MODULE__)
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  @doc """
  Stores a response or a function that will be evaluated to the next call
  to `execute_query`
  """
  def expect(response) do
    Agent.update(__MODULE__, fn _ -> response end)
  end

  @impl true
  def execute_query(query, variables, options) do
    response = Agent.get_and_update(__MODULE__, fn state -> {state, nil} end)

    case response do
      %Response{} = response -> response
      f when is_function(f, 3) -> f.(query, variables, options)
      nil -> raise "there is no response"
    end
  end
end
