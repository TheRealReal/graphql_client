defmodule GraphQL.QueryBuilderTest do
  use ExUnit.Case, async: true

  alias GraphQL.{Node, Query, Variable}
  alias GraphQL.QueryBuilder

  doctest QueryBuilder, import: true

  describe "query/4" do
    import QueryBuilder

    test "creates a Query struct with name, variables, fields and arguments" do
      expected = %Query{
        operation: :query,
        name: "TestQuery",
        variables: [%Variable{name: "term", type: "String", default_value: "*"}],
        fields: [
          Node.field("someField")
        ],
        fragments: [
          Node.fragment("fragmentFields", "SomeType", [
            Node.field("whateverField")
          ])
        ]
      }

      generated =
        query(
          "TestQuery",
          %{"term" => {"String", "*"}},
          [
            field("someField")
          ],
          [
            fragment("fragmentFields", "SomeType", [
              field("whateverField")
            ])
          ]
        )

      assert expected == generated
    end
  end

  describe "mutation/4" do
    import QueryBuilder

    test "creates a Query struct with name, variables, fields and arguments" do
      expected = %Query{
        operation: :mutation,
        name: "TestMutation",
        variables: [%Variable{name: "term", type: "String", default_value: "*"}],
        fields: [
          Node.field("someField")
        ],
        fragments: [
          Node.fragment("fragmentFields", "SomeType", [
            Node.field("whateverField")
          ])
        ]
      }

      generated =
        mutation(
          "TestMutation",
          %{"term" => {"String", "*"}},
          [
            field("someField")
          ],
          [
            fragment("fragmentFields", "SomeType", [
              field("whateverField")
            ])
          ]
        )

      assert expected == generated
    end
  end

  describe "var/3" do
    test "creates a Variable struct" do
      expected = %Variable{name: "varName", type: "VarType", default_value: 123}
      result = QueryBuilder.var("varName", "VarType", 123)
      assert result == expected
    end

    test "creates a Variable struct with nil as default_value" do
      expected = %Variable{name: "varName", type: "VarType"}
      result = QueryBuilder.var("varName", "VarType")
      assert result == expected
    end
  end

  describe "field/3" do
    test "creates a simple field Node struct" do
      expected = %Node{node_type: :field, name: "price"}

      generated = QueryBuilder.field("price")

      assert expected == generated
    end

    test "creates a field Node struct with an alias" do
      expected = %Node{
        node_type: :field,
        name: "price",
        alias: "thePrice"
      }

      generated = QueryBuilder.field({"price", "thePrice"})

      assert expected == generated
    end

    test "creates a Node struct with arguments" do
      expected = %Node{node_type: :field, name: "price", arguments: %{currency: "USD"}}

      generated = QueryBuilder.field("price", %{currency: "USD"})

      assert expected == generated
    end

    test "creates a Node struct with subfields" do
      expected = %Node{
        node_type: :field,
        name: "price",
        nodes: [
          %Node{node_type: :field, name: "cents"}
        ]
      }

      generated =
        QueryBuilder.field("price", %{}, [
          QueryBuilder.field("cents")
        ])

      assert expected == generated
    end

    test "creates a field Node struct with subfields, fragments and arguments" do
      expected = %Node{
        node_type: :field,
        name: "price",
        arguments: %{currency: "USD"},
        nodes: [
          %Node{node_type: :field, name: "cents"},
          %Node{node_type: :fragment_ref, name: "moneyFields"}
        ]
      }

      generated =
        QueryBuilder.field("price", %{currency: "USD"}, [
          QueryBuilder.field("cents"),
          QueryBuilder.fragment("moneyFields")
        ])

      assert expected == generated
    end
  end

  describe "fragment/1" do
    test "creates a fragment_ref Node struct" do
      expected = %Node{node_type: :fragment_ref, name: "someFields"}

      fragment = QueryBuilder.fragment("someFields")

      assert expected == fragment
    end
  end

  describe "fragment/3" do
    test "creates a fragment Node struct" do
      expected = %Node{
        node_type: :fragment,
        name: "someFields",
        type: "TargetObject",
        nodes: [
          %Node{node_type: :field, name: "a_field"}
        ]
      }

      fragment = QueryBuilder.fragment("someFields", "TargetObject", [Node.field("a_field")])

      assert expected == fragment
    end
  end

  describe "inline_fragment/2" do
    test "creates an inline fragment Node struct" do
      expected = %Node{
        node_type: :inline_fragment,
        type: "TargetObject",
        nodes: [
          %Node{node_type: :field, name: "a_field"}
        ]
      }

      fragment = QueryBuilder.inline_fragment("TargetObject", [Node.field("a_field")])

      assert expected == fragment
    end
  end
end
