defmodule GraphQL.NodeTest do
  use ExUnit.Case, async: true

  alias GraphQL.Node

  doctest Node, import: true

  describe "field/1" do
    test "creates a Node struct for a field" do
      expected = %Node{node_type: :field, name: :field_name}

      result = Node.field(:field_name)

      assert result == expected
    end

    test "creates a Node struct for a field with an alias" do
      expected = %Node{node_type: :field, name: :field_name, alias: "fieldAlias"}

      result = Node.field({:field_name, "fieldAlias"})

      assert result == expected
    end
  end

  describe "field/3" do
    test "creates a Node struct for a field with arguments and variables" do
      expected = %Node{
        node_type: :field,
        name: :field_name,
        arguments: %{arg: "value"},
        nodes: [
          %Node{node_type: :field, name: :subfield}
        ]
      }

      result =
        Node.field(:field_name, %{arg: "value"}, [
          %Node{node_type: :field, name: :subfield}
        ])

      assert result == expected
    end

    test "creates a Node struct for a field with arguments, variables and an alias" do
      expected = %Node{
        node_type: :field,
        name: :field_name,
        alias: "fieldAlias",
        arguments: %{arg: "value"},
        nodes: [
          %Node{node_type: :field, name: :subfield}
        ]
      }

      result =
        Node.field({:field_name, "fieldAlias"}, %{arg: "value"}, [
          %Node{node_type: :field, name: :subfield}
        ])

      assert result == expected
    end
  end

  describe "fragment/1" do
    test "creates a Node struct for a fragment reference" do
      expected = %Node{
        node_type: :fragment_ref,
        name: "someFields"
      }

      result = Node.fragment("someFields")

      assert result == expected
    end
  end

  describe "fragment/3" do
    test "creates a Node struct for a fragment" do
      expected = %Node{
        node_type: :fragment,
        name: "someFields",
        type: "SomeType",
        nodes: [
          %Node{node_type: :field, name: :subfield}
        ]
      }

      result =
        Node.fragment("someFields", "SomeType", [
          %Node{node_type: :field, name: :subfield}
        ])

      assert result == expected
    end
  end

  describe "inline_fragment/2" do
    test "creates a Node struct for an inline fragment" do
      expected = %Node{
        node_type: :inline_fragment,
        type: "SomeType",
        nodes: [
          %Node{node_type: :field, name: :subfield}
        ]
      }

      result =
        Node.inline_fragment("SomeType", [
          %Node{node_type: :field, name: :subfield}
        ])

      assert result == expected
    end
  end
end
