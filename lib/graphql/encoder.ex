defmodule GraphQL.Encoder do
  @moduledoc """
  Functions to encode `GraphQL.Query` struct into a string
  """
  alias GraphQL.{Node, Query, Variable}

  @doc """
  Encodes a `GraphQL.Query` struct into a GraphQL query body
  """
  @spec encode(Query.t()) :: String.t()
  def encode(%Query{} = query) do
    has_fragments? = valid?(query.fragments)
    has_variables? = valid?(query.variables)

    identation = 0

    [
      query.operation,
      " ",
      query.name,
      if(has_variables?, do: encode_variables(query.variables)),
      " {\n",
      encode_nodes(query.fields, identation + 2),
      "\n}",
      if(has_fragments?, do: "\n"),
      if(has_fragments?, do: encode_nodes(query.fragments, identation))
    ]
    |> Enum.join()
  end

  # Variables

  defp encode_variables(variables) do
    [
      "(",
      variables |> Enum.map(&encode_variable/1) |> Enum.join(", "),
      ")"
    ]
    |> Enum.join()
  end

  defp encode_variable(%Variable{} = var) do
    has_default? = var.default_value != nil

    [
      "$",
      var.name,
      ": ",
      var.type,
      if(has_default?, do: " = "),
      encode_value(var.default_value)
    ]
    |> Enum.join()
  end

  defp encode_nodes(nil, _), do: ""
  defp encode_nodes([], _), do: ""

  defp encode_nodes(fields, identation) do
    fields
    |> Enum.map(&encode_node(&1, identation))
    |> Enum.join("\n")
  end

  # Field
  defp encode_node(%Node{node_type: :field} = a_node, identation) do
    has_arguments? = valid?(a_node.arguments)
    has_nodes? = valid?(a_node.nodes)
    has_directives? = valid?(a_node.directives)

    [
      String.duplicate(" ", identation),
      encode_field_alias(a_node.alias),
      encode_name(a_node.name),
      if(has_arguments?, do: encode_arguments(a_node.arguments)),
      if(has_directives?, do: " "),
      if(has_directives?, do: encode_directives(a_node.directives)),
      if(has_nodes?, do: " {\n"),
      encode_nodes(a_node.nodes, identation + 2),
      if(has_nodes?, do: "\n"),
      if(has_nodes?, do: String.duplicate(" ", identation)),
      if(has_nodes?, do: "}")
    ]
    |> Enum.join()
  end

  # Fragment reference
  defp encode_node(%Node{node_type: :fragment_ref} = a_node, identation) do
    [
      String.duplicate(" ", identation),
      "...",
      a_node.name
    ]
    |> Enum.join()
  end

  # Fragment
  defp encode_node(%Node{node_type: :fragment} = fragment, identation) do
    [
      String.duplicate(" ", identation),
      "fragment ",
      fragment.name,
      " on ",
      fragment.type,
      " {\n",
      fragment.nodes |> Enum.map(&encode_node(&1, identation + 2)) |> Enum.join("\n"),
      "\n",
      String.duplicate(" ", identation),
      "}"
    ]
    |> Enum.join()
  end

  # Inline Fragment
  defp encode_node(%Node{node_type: :inline_fragment} = a_node, identation) do
    [
      String.duplicate(" ", identation),
      "... on ",
      a_node.type,
      " {\n",
      a_node.nodes |> Enum.map(&encode_node(&1, identation + 2)) |> Enum.join("\n"),
      "\n",
      String.duplicate(" ", identation),
      "}"
    ]
    |> Enum.join()
  end

  defp encode_name(name) when is_atom(name), do: Atom.to_string(name)
  defp encode_name(name) when is_binary(name), do: name

  defp encode_field_alias(nil), do: ""
  defp encode_field_alias(an_alias), do: "#{an_alias}: "

  # Arguments
  def encode_arguments(nil), do: ""

  def encode_arguments([]), do: ""

  def encode_arguments(map_or_keyword) do
    vars =
      map_or_keyword
      |> Enum.map(&encode_argument/1)
      |> Enum.join(", ")

    "(#{vars})"
  end

  def encode_argument({key, value}) do
    "#{key}: #{encode_value(value)}"
  end

  defp encode_value(v) do
    cond do
      is_binary(v) ->
        "\"#{v}\""

      is_list(v) ->
        v
        |> Enum.map(&encode_value/1)
        |> Enum.join()

      is_map(v) ->
        parsed_v =
          v
          |> Enum.map(&encode_argument/1)
          |> Enum.join(", ")

        Enum.join(["{", parsed_v, "}"])

      true ->
        case v do
          {:enum, v} -> v
          v -> "#{v}"
        end
    end
  end

  defp encode_directives(directives) do
    directives
    |> Enum.map(&encode_directive/1)
    |> Enum.join(" ")
  end

  defp encode_directive({key, arguments}) do
    [
      "@",
      key,
      encode_arguments(arguments)
    ]
    |> Enum.join()
  end

  defp encode_directive(key) do
    ["@", key] |> Enum.join()
  end

  defp valid?(nil), do: false
  defp valid?([]), do: false
  defp valid?(a_map) when is_map(a_map), do: a_map != %{}
  defp valid?(_), do: true
end
