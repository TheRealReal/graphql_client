defmodule GraphQL.QueryRegistry do
  @moduledoc """
  Functions to handle query registries.

  A query registry stores several `GraphQL.Query` structs, so they
  can be combined into a single query before the execution.
  """
  alias GraphQL.{Client, Query}

  @enforce_keys [:name]
  defstruct name: nil, queries: [], variables: [], resolvers: []

  @typedoc """
  A resolver is a function that must accept two arguments:
    - a `GraphQL.Response` struct
    - an accumulator, that can be of any type

  It also must return the updated value of the accumulator.
  """
  @type resolver :: (Response.t(), any() -> any())

  @typedoc """
  A struct that keeps the information about several queries, variables and
  resolvers.

  The `name` field will be used as the name of the final query or mutation.

  The `queries` field is a list of `GraphQL.Query` structs, that
  will be merged before execution.

  The `variables` is a map with all _values_ of variables that will be sent
  to the server along with the GraphQL body.

  The `resolver` is a list of `t:resolver()` functions that can be used to
  produce the side effects in an accumulator.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          queries: [Query.t()],
          variables: [map()],
          resolvers: list()
        }

  @doc """
  Creates a new QueryRegistry struct with the given name.
  """
  @spec new(String.t()) :: t()
  def new(name) do
    %__MODULE__{name: name}
  end

  @doc """
  Add a query to the a query registry
  """
  @spec add_query(t(), Query.t(), map()) :: t()
  def add_query(%__MODULE__{} = registry, %Query{} = query, variables \\ nil) do
    updated_variables =
      if variables == %{} || variables == nil do
        registry.variables
      else
        [variables | registry.variables]
      end

    %__MODULE__{registry | queries: [query | registry.queries], variables: updated_variables}
  end

  @doc """
  Add a new resolver into a query registry
  """
  @spec add_resolver(t(), resolver()) :: t()
  def add_resolver(%__MODULE__{} = registry, function) when is_function(function, 2) do
    add_resolvers(registry, [function])
  end

  @doc """
  Add a list of resolvers into a query registry
  """
  @spec add_resolvers(t(), [resolver()]) :: t()
  def add_resolvers(%__MODULE__{} = registry, resolvers) do
    %__MODULE__{registry | resolvers: registry.resolvers ++ resolvers}
  end

  @doc """
  Executes the given query registry, using the given accumulator `acc` and the given options
  """
  @spec execute(t(), any(), Keyword.t()) :: any()
  def execute(registry, acc, options \\ []) do
    case prepare_query(registry) do
      {:ok, {query, variables, resolvers}} ->
        result =
          query
          |> Client.execute(variables, options)
          |> resolve(resolvers, acc)

        {:ok, result}

      error ->
        error
    end
  end

  defp prepare_query(%__MODULE__{} = registry) do
    case registry.queries do
      [_head | _tail] ->
        query = Query.merge_many(registry.queries, registry.name)

        variables =
          if registry.variables == [],
            do: %{},
            else: Enum.reduce(registry.variables, &Map.merge/2)

        {:ok, {query, variables, registry.resolvers}}

      _empty ->
        {:error, "no queries available"}
    end
  end

  defp resolve(response, resolvers, initial_acc) do
    Enum.reduce(resolvers, initial_acc, fn resolver, acc ->
      resolver.(response, acc)
    end)
  end
end
