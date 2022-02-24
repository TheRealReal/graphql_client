defmodule GraphQL.QueryBuilder do
  @moduledoc """
  Functions to simplify the creation of GraphQL queries.

  The easiest way to use these functions is to `import` this module directly,
  this way you'll have all you need to build a query.

  ## Helper functions

  - `query/4` - creates a new "query" operation
  - `mutation/4` - creates a new "mutation" operation
  - `field/3` - creates a new field (optionals: variables and subfields)
  - `fragment/1` - creates a reference to a fragment
  - `fragment/3`- creates a fragment
  - `inline_fragment/2` - creates an inline fragment

  ## Writing queries and mutations

  As an example, consider the following GraphQL request:

  ```
  query UserQuery($id: Integer = 1) {
    user (id: $id) {
      id
      email
      ...personFields
    }
  }

  fragment personField on Person {
    firstName
    lastName
  }
  ```

  Using the functions in this module, you can create a representation of this
  query in this way:

  ```
  q = query("UserQuery", %{id: {"Integer", 1}}, [
    field(:user, %{}, [
      field(:id)
      field(:email),
      fragment("personFields")
    ])
  ], [
    fragment("personFields", "Person", [
      field("firstName"),
      field("lastName")
    ])
  ])
  ```
  """

  alias GraphQL.{Node, Query, Variable}

  @doc """
  Creates a new `GraphQL.Query` struct, for a `:query` operation.
  """
  @spec query(String.t(), map(), list(), list()) :: Query.t()
  def query(name, variables, fields, fragments \\ []) do
    build(:query, name, variables, fields, fragments)
  end

  @doc """
  Creates a new `GraphQL.Query` struct, for a `:mutation` operation
  """
  @spec mutation(String.t(), map(), list(), list()) :: Query.t()
  def mutation(name, variables, fields, fragments \\ []) do
    build(:mutation, name, variables, fields, fragments)
  end

  defp build(operation, name, variables, fields, fragments) do
    %Query{
      operation: operation,
      name: name,
      fields: fields,
      fragments: fragments,
      variables: parse_variables(variables)
    }
  end

  @doc """
  Creates a field.

  When rendered, it will have the following body:

  1. A simple field, no arguments or sub fields
  ```
  fieldName
  ```

  2. A field with an alias
  ```
  fieldAlias: fieldName
      ```

  3. A field with arguments
  ```
  fieldName(arg: value)
  ```

  4. A field with sub fields
  ```
  fieldName {
    subField
  }
  ```

  5. A field an alias, arguments and sub fields
  ```
  fieldAlias: fieldName (arg: value) {
    subField
  }
  ```

  ## Examples

      iex> field(:some_field)
      %GraphQL.Node{node_type: :field, name: :some_field}

      iex> field({:some_field, "fieldAlias"})
      %GraphQL.Node{node_type: :field, name: :some_field, alias: "fieldAlias"}

      iex> field("anotherField", %{}, [field(:id)])
      %GraphQL.Node{node_type: :field, name: "anotherField", nodes: [%GraphQL.Node{node_type: :field, name: :id}]}

  """
  @spec field(Node.name() | Node.name_and_alias(), map(), Keyword.t(Node.t())) :: Node.t()
  def field(name, args \\ nil, fields \\ nil, directives \\ nil) do
    args = if(args == %{}, do: nil, else: args)
    Node.field(name, args, fields, directives)
  end

  @doc """
  Creates a `GraphQL.Variable` struct.
  """
  @spec var(any(), any(), any()) :: Variable.t()
  def var(name, type, value \\ nil) do
    %Variable{name: name, type: type, default_value: value}
  end

  @doc """
  Creates a reference to a fragment. Use it inside a field.

  When rendered, it will generate the following body:

  ```
  ...fragmentName
  ```

  ## Examples

      iex> fragment(:fields)
      %GraphQL.Node{node_type: :fragment_ref, name: :fields}
  """
  @spec fragment(String.t()) :: Node.t()
  def fragment(name) do
    Node.fragment(name)
  end

  @doc """
  Creates a fragment. Use it on the query level.


  When rendered, it will generate the following body:

  ```
  ... fragmentName on Type {
    field1
    field2
  }
  ```

  ## Examples

      iex> fragment("personFields", "Person", [field(:name)])
      %GraphQL.Node{node_type: :fragment, name: "personFields", type: "Person", nodes: [%GraphQL.Node{node_type: :field, name: :name}]}
  """
  @spec fragment(String.t(), String.t(), list()) :: Node.t()
  def fragment(name, type, fields) do
    Node.fragment(name, type, fields)
  end

  @doc """
  Creates an inline fragment. Use it inside a field.

  When rendered, it will generate the following body:

  ```
  ... on Type {
    field1
    field2
  }
  ```

  ## Examples

      iex> inline_fragment("Person", [field(:name)])
      %GraphQL.Node{node_type: :inline_fragment, type: "Person", nodes: [%GraphQL.Node{node_type: :field, name: :name}]}
  """
  @spec inline_fragment(String.t(), list()) :: Node.t()
  def inline_fragment(type, fields) do
    Node.inline_fragment(type, fields)
  end

  # Variables

  defp parse_variables(vars) do
    Enum.map(vars, &parse_variable/1)
  end

  defp parse_variable({name, {type, default}}) do
    %Variable{name: name, type: type, default_value: default}
  end

  defp parse_variable({name, type}) do
    %Variable{name: name, type: type, default_value: nil}
  end
end
