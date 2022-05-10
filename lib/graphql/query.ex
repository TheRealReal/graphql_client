defmodule GraphQL.Query do
  @moduledoc """
  Functions to create and modify query representations.
  """
  alias GraphQL.{Node, Variable}

  @enforce_keys [:operation, :name, :fields]
  defstruct [:operation, :name, :fields, :fragments, :variables]

  @typedoc """
  A struct that represents a GraphQL query or mutation.

  The `:operation` field can be `:query`, for a query operation, or `:mutation`,
  for a mutation operation.

  The `:name` field is the name of the query or mutation. GraphQL does not
  require a name for operations, but this struct will enforce its presence in
  order to enrich trace and logging information.

  The `:fields` field is a list of `GraphQL.Node` structs. This the
  list of roof fields of a query or mutation.

  The `:fragments` field is also a list of `GraphQL.Node` structs,
  but intended to only keep fragment nodes, as they are usually placed after
  the  root fields in a typical GraphQL query/mutation.

  The `:variables` fields is a list of `GraphQL.Variable` structs,
  that represents the expected variables during the request. Note that this list
  is the _definition_ of variables, not the _values_ of them.
  """
  @type t :: %__MODULE__{
          operation: :query | :mutation,
          name: String.t(),
          fields: [Node.t()],
          fragments: [Node.t()] | nil,
          variables: [Variable.t()] | nil
        }

  @doc """
  Creates a new query struct for a 'query' operation from a keyword list.
  """
  @spec query(Keyword.t()) :: t()
  def query(options) do
    options = Keyword.put(options, :operation, :query)
    struct(__MODULE__, options)
  end

  @doc """
  Creates a new query struct for a 'mutation' operation from a keyword list.
  """
  @spec mutation(Keyword.t()) :: t()
  def mutation(options) do
    options = Keyword.put(options, :operation, :mutation)
    struct(__MODULE__, options)
  end

  @doc """
  Adds a field to a query.

  The `field` argument must be a `GraphQL.Node` struct and its
  `:node_type` must be `:field`.

  ## Examples

      iex> f1 = GraphQL.Node.field(:field)
      %GraphQL.Node{node_type: :field, name: :field}
      iex> f2 = GraphQL.Node.field(:other_field)
      %GraphQL.Node{node_type: :field, name: :other_field}
      iex> q = %GraphQL.Query{operation: :query, name: "MyQuery", fields: [f1]}
      %GraphQL.Query{operation: :query, name: "MyQuery", fields: [f1]}
      iex> add_field(q, f2)
      %GraphQL.Query{name: "MyQuery", operation: :query, fields: [f2, f1]}

  """
  @spec add_field(t(), Node.t()) :: t()
  def add_field(%__MODULE__{fields: fields} = query, %Node{node_type: :field} = field) do
    fields = if(fields == nil, do: [], else: fields)
    %__MODULE__{query | fields: [field | fields]}
  end

  @doc """
  Adds a fragment to a query.

  The `field` argument must be a `GraphQL.Node` struct and its
  `:node_type` must be `:field`.

  ## Examples

      iex> f1 = GraphQL.Node.fragment("personFields", "Person", [GraphQL.Node.field(:field)])
      %GraphQL.Node{node_type: :fragment, name: "personFields", type: "Person", nodes: [%GraphQL.Node{node_type: :field, name: :field}]}
      iex> f2 = GraphQL.Node.fragment("userFields", "User", [GraphQL.Node.field(:another_field)])
      %GraphQL.Node{node_type: :fragment, name: "userFields", type: "User", nodes: [%GraphQL.Node{node_type: :field, name: :another_field}]}
      iex> q = %GraphQL.Query{operation: :query, name: "MyQuery", fields: [], fragments: [f1]}
      %GraphQL.Query{operation: :query, name: "MyQuery", fields: [], fragments: [f1]}
      iex> add_fragment(q, f2)
      %GraphQL.Query{name: "MyQuery", operation: :query, fields: [], fragments: [f2, f1]}

  """
  @spec add_fragment(t(), Node.t()) :: t()
  def add_fragment(
        %__MODULE__{fragments: fragments} = query,
        %Node{node_type: :fragment} = fragment
      ) do
    fragments = if(fragments == nil, do: [], else: fragments)
    %__MODULE__{query | fragments: [fragment | fragments]}
  end

  @doc """
  Add a new variable to an existing query

  ## Examples

      iex> v1 = %GraphQL.Variable{name: "id", type: "Integer"}
      %GraphQL.Variable{name: "id", type: "Integer"}
      iex> v2 = %GraphQL.Variable{name: "slug", type: "String"}
      %GraphQL.Variable{name: "slug", type: "String"}
      iex> q = %GraphQL.Query{operation: :query, name: "MyQuery", fields: [], variables: [v1]}
      %GraphQL.Query{operation: :query, name: "MyQuery", fields: [], variables: [v1]}
      iex> add_variable(q, v2)
      %GraphQL.Query{operation: :query, name: "MyQuery", fields: [], variables: [v2, v1]}
  """
  @spec add_variable(t(), Variable.t()) :: t()
  def add_variable(%__MODULE__{variables: variables} = query, %Variable{} = variable) do
    variables = if(variables == nil, do: [], else: variables)
    %__MODULE__{query | variables: [variable | variables]}
  end

  @doc """
  Combine two queries into one query, merging fields, variables and fragments.

  The two queries must have the same operation.
  """
  @spec merge(t(), t(), String.t()) :: {:ok, t()} | {:error, any()}
  def merge(
        %__MODULE__{operation: operation} = query_a,
        %__MODULE__{operation: operation} = query_b,
        name
      ) do
    with {:ok, variables} <- merge_variables(query_a.variables || [], query_b.variables || []) do
      {:ok,
       %__MODULE__{
         name: name,
         operation: operation,
         fields: (query_a.fields || []) ++ (query_b.fields || []),
         fragments: (query_a.fragments || []) ++ (query_b.fragments || []),
         variables: variables
       }}
    else
      error -> error
    end
  end

  defp merge_variables(set_a, set_b) do
    repeated_vars =
      for v_a <- set_a, v_b <- set_b, reduce: [] do
        acc ->
          if GraphQL.Variable.same?(v_a, v_b) do
            [v_a | acc]
          else
            acc
          end
      end

    case repeated_vars do
      [] ->
        {:ok, set_a ++ set_b}

      _ ->
        var_names =
          repeated_vars
          |> Enum.map(&"\"#{&1.name}\"")
          |> Enum.join(", ")

        {:error, "variables declared twice: #{var_names}"}
    end
  end

  @doc """
  Combines a list of queries into one query, merging fields, variables and fragments.

  All queries must have the same operation.
  """
  @spec merge_many([t()], String.t()) :: {:ok, t()} | {:error, any()}
  def merge_many(queries, name \\ nil)

  def merge_many([%__MODULE__{} = query], name) do
    if name != nil do
      {:ok, %__MODULE__{query | name: name}}
    else
      {:ok, query}
    end
  end

  def merge_many([first_query | remaining_queries], name) do
    result =
      Enum.reduce_while(remaining_queries, first_query, fn query, result ->
        case merge(query, result, name) do
          {:ok, merged_query} ->
            {:cont, merged_query}

          {:error, error} ->
            {:halt, {:error, error}}
        end
      end)

    case result do
      %__MODULE__{} = query -> {:ok, query}
      error -> error
    end
  end
end
