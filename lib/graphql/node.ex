defmodule GraphQL.Node do
  @moduledoc """
  Functions to create all different types of nodes of a GraphQL operation.

  Usually, this module should not be used directly, since it is easier to use
  the function from `GraphQL.QueryBuilder`.
  """
  @enforce_keys [:node_type]
  defstruct node_type: nil,
            name: nil,
            alias: nil,
            type: nil,
            arguments: nil,
            nodes: nil,
            directives: nil

  @typedoc """
  The GraphQL query element that this node represents.

  The four node types are:
    - field: a single field of a GraphQL schema, may have arguments and other nodes
    - fragment_ref: a reference to a fragment, used inside fields to import fragment fields
    - fragment: a fragment definition, with name, type and fields
    - inline_fragment: much like a fragment, but being inline, it does not need a name
  """
  @type node_type :: :field | :fragment_ref | :fragment | :inline_fragment

  @typedoc """
  A GraphQL identifier that is not a GraphQL keyword (like mutation, query and fragment)

  Used to identify fields, aliases and fragments.
  """
  @type name :: String.t() | atom()

  @typedoc """
  A two-element tuple where the first position is the name of the field and the
  second element is the alias of the field.
  """
  @type name_and_alias :: {name(), name()}

  @typedoc """
  A struct representing a GraphQL operation node.

  A %Node{} struct can be represent a field, a fragment, an inline fragment or a
  fragment reference, identified by the `:node_type` field.

  The `name` represents how this node is identified within the GraphQL operation.

  The `alias` is only used when the `:node_type` is `:field`, and as the name
  suggests, represents the alias of the field's name.

  The `arguments` is a map with all the arguments used by a node, and it's only
  valid when thew `:node_type` is `:field`.

  The `type` is only used when `:node_type` is `:fragment` or `:inline_fragment`,
  and represents the GraphQL type of the fragment.

  The `nodes` is a list of child nodes, that can used to query for complex
  objects.

  The `directives` field is an enum with all the graphQL directives to be
  applied on a node node.
  """
  @type t :: %__MODULE__{
          node_type: node_type(),
          name: name(),
          alias: name(),
          type: String.t(),
          arguments: map() | Keyword.t(),
          nodes: [t()],
          directives: map() | Keyword.t()
        }

  @doc """
  Creates a simple field, with no arguments or sub nodes.

  The `name` parameter can be an atom or string, or a two-element tuple with
  atoms or strings, where the first element is the actual name of the field and
  the second element is the alias of the field.

  ## GraphQL example

  A query with a simple field inside another field:
  ```
  query {
    user {
      id      <---- Simple field
    }
  }
  ```

  A query with a simple field with an alias:
  ```
  query {
    user {
      theId: id      <---- Simple field with alias
    }
  }
  ```

  ## Examples

      iex> field(:my_field)
      %GraphQL.Node{node_type: :field, name: :my_field}

      iex> field({:my_field, "field_alias"})
      %GraphQL.Node{node_type: :field, name: :my_field, alias: "field_alias"}
  """
  @spec field(name() | name_and_alias()) :: t()
  def field(name_spec)

  def field({name, an_alias}) do
    %__MODULE__{
      node_type: :field,
      name: name,
      alias: an_alias
    }
  end

  def field(name) do
    %__MODULE__{
      node_type: :field,
      name: name
    }
  end

  @doc """
  Creates a field with arguments and sub nodes.

  The `name` parameter can be an atom or string, or a two-element tuple with
  atoms or strings, where the first element is the actual name of the field and
  the second element is the alias of the field.

  The `arguments` parameter is a map.

  The `nodes` argument is a list of `%GraphQL.Node{}` structs.

  ## GraphQL Example

  A query with a field that has arguments, an alias and subfields

  ```
  query {
    someObject: object(slug: "the-object") {   <----- Field with an alias and arguments
      field                                    <----- Sub field
      anotherField                             <----- Sub field
    }
  }
  ```

  ## Examples

      iex> field(:my_field, %{id: "id"}, [ field(:subfield) ] )
      %GraphQL.Node{node_type: :field, name: :my_field, arguments: %{id: "id"}, nodes: [%GraphQL.Node{node_type: :field, name: :subfield}]}

      iex> field({:my_field, "field_alias"}, %{id: "id"}, [ field(:subfield) ] )
      %GraphQL.Node{node_type: :field, name: :my_field, alias: "field_alias", arguments: %{id: "id"}, nodes: [%GraphQL.Node{node_type: :field, name: :subfield}]}
  """
  @spec field(name() | name_and_alias(), map(), [t()], [any()]) :: t()
  def field(name_spec, arguments, nodes, directives \\ nil)

  def field({name, an_alias}, arguments, nodes, directives) do
    %__MODULE__{
      node_type: :field,
      name: name,
      alias: an_alias,
      arguments: arguments,
      nodes: nodes,
      directives: directives
    }
  end

  def field(name, arguments, nodes, directives) do
    %__MODULE__{
      node_type: :field,
      name: name,
      arguments: arguments,
      nodes: nodes,
      directives: directives
    }
  end

  @doc """
  Creates a reference to a fragment.

  A fragment reference is used inside a field to import the fields of a fragment.

  ## GraphQL Example

  ```
  query {
    object {
      ...fieldsFromFragment        <----- Fragment Reference
    }
  }
  ```

  ## Examples

      iex> fragment("myFields")
      %GraphQL.Node{node_type: :fragment_ref, name: "myFields"}

  """
  @spec fragment(name()) :: t()
  def fragment(name) do
    %__MODULE__{
      node_type: :fragment_ref,
      name: name
    }
  end

  @doc """
  Creates a fragment.

  A fragment is used to share fields between other fields

  ## GraphQL Example

  ```
  query {
    object {
      ...fieldsFromFragment
    }
  }

  fragment fieldsFromFragment on Type {    <------ Fragment
    field1
    field2
  }
  ```

  ## Examples

      iex> fragment("myFields", "SomeType", [field(:field)])
      %GraphQL.Node{node_type: :fragment, name: "myFields", type: "SomeType", nodes: [%GraphQL.Node{node_type: :field, name: :field}]}

  """
  @spec fragment(name(), name(), [t()]) :: t()
  def fragment(name, type, fields) do
    %__MODULE__{
      node_type: :fragment,
      name: name,
      type: type,
      nodes: fields
    }
  end

  @doc """
  Creates an inline fragment.

  An inline fragment is used to conditionally add fields on another field depending
  on its type


  ## GraphQL Example

  ```
  query {
    object {
      ... on Type {          <------  Inline Fragment
        field1
        field2
      }
    }
  }

  ```

  ## Examples

      iex> inline_fragment("SomeType", [field(:field)])
      %GraphQL.Node{node_type: :inline_fragment, type: "SomeType", nodes: [%GraphQL.Node{node_type: :field, name: :field}]}

  """
  @spec inline_fragment(name(), [t()]) :: t()
  def inline_fragment(type, fields) do
    %__MODULE__{
      node_type: :inline_fragment,
      type: type,
      nodes: fields
    }
  end
end
