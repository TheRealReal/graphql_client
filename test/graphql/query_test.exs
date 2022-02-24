defmodule GraphQL.QueryTest do
  use ExUnit.Case, async: true

  alias GraphQL.{Node, Query, Variable}

  import GraphQL.QueryBuilder

  doctest Query, import: true

  @user_query query(
                "UserQuery",
                %{"userId" => "Integer"},
                [
                  field("user", %{"userId" => :"$user_id"}, [
                    field("id"),
                    field("email"),
                    fragment("personFields")
                  ])
                ],
                [
                  fragment("personFields", "PersonType", [
                    field("name")
                  ])
                ]
              )

  @product_query query(
                   "ProductQuery",
                   %{sku: "String!"},
                   [
                     field("product", %{"sku" => :"$sku"}, [
                       field("id"),
                       fragment("productFields")
                     ])
                   ],
                   [
                     fragment("productFields", "ProductType", [
                       field("title"),
                       field("description")
                     ])
                   ]
                 )
  @merged_queries %Query{
    name: "ProductAndUser",
    operation: :query,
    variables: [
      %Variable{name: "userId", type: "Integer"},
      %Variable{name: :sku, type: "String!"}
    ],
    fields: [
      %Node{
        node_type: :field,
        name: "user",
        arguments: %{"userId" => :"$user_id"},
        nodes: [
          %Node{node_type: :field, name: "id"},
          %Node{node_type: :field, name: "email"},
          %Node{node_type: :fragment_ref, name: "personFields"}
        ]
      },
      %Node{
        node_type: :field,
        name: "product",
        arguments: %{"sku" => :"$sku"},
        nodes: [
          %Node{node_type: :field, name: "id"},
          %Node{node_type: :fragment_ref, name: "productFields"}
        ]
      }
    ],
    fragments: [
      %Node{
        node_type: :fragment,
        name: "personFields",
        type: "PersonType",
        nodes: [
          %Node{node_type: :field, name: "name"}
        ]
      },
      %Node{
        node_type: :fragment,
        name: "productFields",
        type: "ProductType",
        nodes: [
          %Node{node_type: :field, name: "title"},
          %Node{node_type: :field, name: "description"}
        ]
      }
    ]
  }

  describe "query/1" do
    test "creates a new query from a keyword list" do
      props = @user_query |> Map.drop([:operation, :__struct__]) |> Map.to_list()
      result = Query.query(props)
      assert result == @user_query
    end
  end

  describe "mutation/1" do
    test "creates a new query from a keyword list" do
      props = @user_query |> Map.drop([:operation, :__struct__]) |> Map.to_list()
      result = Query.mutation(props)
      expected = Map.put(@user_query, :operation, :mutation)
      assert result == expected
    end
  end

  describe "merge/3" do
    test "merges two queries" do
      result = Query.merge(@user_query, @product_query, "ProductAndUser")

      assert @merged_queries == result
    end
  end

  describe "merge_many/2" do
    test "merges a list of queries" do
      result = Query.merge_many([@product_query, @user_query], "ProductAndUser")

      assert @merged_queries == result
    end

    test "returns a query if it is the only element on the list" do
      result = Query.merge_many([@product_query])

      assert result == @product_query
    end
  end
end
