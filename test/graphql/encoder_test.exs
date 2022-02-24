defmodule GraphQL.EncoderTest do
  use ExUnit.Case, async: true

  alias GraphQL.{Encoder, Node, Query, Variable}

  describe "encode/1" do
    test "generates a graphql body for a simple query" do
      query = %Query{
        operation: :query,
        name: "TestQuery",
        fields: [
          Node.field("field", %{}, [
            Node.field("subfield")
          ])
        ]
      }

      expected =
        """
        query TestQuery {
          field {
            subfield
          }
        }
        """
        |> String.trim()

      assert expected == Encoder.encode(query)
    end

    test "generates a graphql body for a simple mutation with variables" do
      query = %Query{
        operation: :mutation,
        name: "TestMutation",
        fields: [
          Node.field("field", %{input: :"$input"}, [
            Node.field("subfield")
          ])
        ],
        variables: [
          %Variable{name: "input", type: "Integer", default_value: 10}
        ]
      }

      expected =
        """
        mutation TestMutation($input: Integer = 10) {
          field(input: $input) {
            subfield
          }
        }
        """
        |> String.trim()

      assert expected == Encoder.encode(query)
    end

    test "generates a graphql query with fragments" do
      query = %Query{
        operation: :query,
        name: "TestQuery",
        fields: [
          Node.field("field", %{}, [
            Node.field("subfield"),
            Node.fragment("someFields")
          ])
        ],
        fragments: [
          Node.fragment("someFields", "SomeType", [
            Node.field("field1"),
            Node.field("field2")
          ])
        ]
      }

      expected =
        """
        query TestQuery {
          field {
            subfield
            ...someFields
          }
        }
        fragment someFields on SomeType {
          field1
          field2
        }
        """
        |> String.trim()

      assert expected == Encoder.encode(query)
    end

    test "generates a graphql query with an inline fragment" do
      query = %Query{
        operation: :query,
        name: "TestQuery",
        fields: [
          Node.field("field", %{}, [
            Node.field("subfield"),
            Node.inline_fragment("SomeType", [
              Node.field("field1"),
              Node.field("field2")
            ])
          ])
        ]
      }

      expected =
        """
        query TestQuery {
          field {
            subfield
            ... on SomeType {
              field1
              field2
            }
          }
        }
        """
        |> String.trim()

      assert expected == Encoder.encode(query)
    end

    test "generates a graphql query with multiple fields and fragments" do
      query = %Query{
        operation: :query,
        name: "TestQuery",
        fields: [
          Node.field({"dog", "theDog"}, %{nick: "Luna"}, [
            Node.fragment("dogFields"),
            Node.field({"name", "dogName"})
          ]),
          Node.field("field", %{}, [
            Node.inline_fragment("SomeType", [
              Node.field("field1"),
              Node.field("field2")
            ]),
            Node.fragment("otherFields"),
            Node.field("subfield")
          ])
        ],
        fragments: [
          Node.fragment("dogFields", "DogObject", [
            Node.field(:race)
          ]),
          Node.fragment("otherFields", "OtherObject", [
            Node.field("someField")
          ])
        ]
      }

      expected =
        """
        query TestQuery {
          theDog: dog(nick: "Luna") {
            ...dogFields
            dogName: name
          }
          field {
            ... on SomeType {
              field1
              field2
            }
            ...otherFields
            subfield
          }
        }
        fragment dogFields on DogObject {
          race
        }
        fragment otherFields on OtherObject {
          someField
        }
        """
        |> String.trim()

      assert expected == Encoder.encode(query)
    end
  end
end
