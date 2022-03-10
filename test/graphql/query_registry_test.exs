defmodule GraphQL.QueryRegistryTest do
  use ExUnit.Case

  import GraphQL.LocalBackend, only: [expect: 1]

  import GraphQL.QueryBuilder

  alias GraphQL.{QueryRegistry, Response}

  doctest QueryRegistry, import: true

  @character_query query("CharacterQuery", %{power: "String"}, [
                     field(:character, %{power: :"$power"}, [
                       field(:id),
                       field(:name)
                     ])
                   ])

  @dog_query query("DogQuery", %{breed: "String"}, [
               field(:dogs, %{}, [
                 field(:id),
                 field(:name),
                 field(:color)
               ])
             ])

  describe "QueryRegistry integration test" do
    test "creates, modify and execute a QueryRegistry" do
      import QueryRegistry

      registry = new("SuperQuery")

      registry =
        registry
        |> add_query(@character_query, %{power: "flight"})
        |> add_query(@dog_query)
        |> add_resolver(fn _response, acc ->
          Map.put(acc, :resolver_result, true)
        end)

      expect(
        Response.success(%{
          dogs: [
            %{
              id: 456,
              name: "Scooby",
              color: "Brown"
            }
          ],
          character: %{
            id: 123,
            name: "Super Flying Person"
          }
        })
      )

      result = execute(registry, %{result: "success"})

      assert result == {:ok, %{result: "success", resolver_result: true}}
    end
  end

  describe "execute/3" do
    test "executes registered queries as fields in a single query and call resolvers" do
      test_pid = self()

      resolvers = [
        fn _response, acc ->
          send(test_pid, :first_resolver)
          [:first_resolver | acc]
        end,
        fn _response, acc ->
          send(test_pid, :second_resolver)
          [:second_resolver | acc]
        end
      ]

      registry = %QueryRegistry{
        name: "BigQuery",
        queries: [@character_query, @dog_query],
        variables: [
          %{power: "X-Ray Vision"},
          %{breed: "chow chow"}
        ],
        resolvers: resolvers
      }

      expect(fn query, variables, _options ->
        expected_query =
          query("BigQuery", %{breed: "String", power: "String"}, [
            field(:dogs, %{}, [
              field(:id),
              field(:name),
              field(:color)
            ]),
            field(:character, %{power: :"$power"}, [
              field(:id),
              field(:name)
            ])
          ])

        assert expected_query.fields == query.fields
        assert expected_query.variables == query.variables
        assert expected_query.fragments == query.fragments

        assert variables == %{
                 power: "X-Ray Vision",
                 breed: "chow chow"
               }

        Response.success(%{
          character: %{
            id: 1,
            name: "Saitama"
          },
          dog: %{
            id: 123,
            name: "Snoopy",
            color: "#FFF"
          }
        })
      end)

      result = QueryRegistry.execute(registry, [])

      assert result == {:ok, [:second_resolver, :first_resolver]}
      assert_received :first_resolver
      assert_received :second_resolver
    end

    test "returns an error tuple when registry is empty" do
      registry = QueryRegistry.new("Test")
      acc = %{a: 1}

      result = QueryRegistry.execute(registry, acc)

      assert result == {:error, "no queries available"}
    end
  end

  describe "new/1" do
    test "creates a new and empty QueryRegistry" do
      assert %QueryRegistry{
               name: "TheQuery",
               queries: [],
               resolvers: [],
               variables: []
             } = QueryRegistry.new("TheQuery")
    end
  end

  describe "add_query/3" do
    test "add a query and variables to an existing QueryRegistry struct" do
      registry = %QueryRegistry{
        name: "WebsiteQuery",
        queries: [],
        resolvers: [],
        variables: []
      }

      q1 =
        query("userQuery", %{"id" => "Integer"}, [
          field(:user, %{id: :"$id"}, [
            field(:id)
          ])
        ])

      q2 =
        query("productQuery", %{}, [
          field(:product, %{}, [
            field(:id)
          ])
        ])

      registry =
        registry
        |> QueryRegistry.add_query(q1, %{"id" => 123})
        |> QueryRegistry.add_query(q2)

      assert registry.queries == [q2, q1]
      assert registry.variables == [%{"id" => 123}]
    end
  end

  describe "add_resolver/2" do
    test "adds a resolver to the internal list of resolvers and keeps the order" do
      registry = %QueryRegistry{
        name: "WebsiteQuery",
        resolvers: []
      }

      resolver1 = fn _, _ -> 123 end
      resolver2 = fn _, _ -> 456 end

      registry =
        registry
        |> QueryRegistry.add_resolver(resolver1)
        |> QueryRegistry.add_resolver(resolver2)

      assert registry.resolvers == [resolver1, resolver2]
    end
  end

  describe "add_resolvers/2" do
    test "adds a resolver list to the internal list of resolvers and keeps the order" do
      resolver1 = fn _, _ -> 123 end
      resolver2 = fn _, _ -> 456 end
      resolver3 = fn _, _ -> 789 end

      registry = %QueryRegistry{
        name: "WebsiteQuery",
        resolvers: [resolver1]
      }

      registry = QueryRegistry.add_resolvers(registry, [resolver2, resolver3])

      assert registry.resolvers == [resolver1, resolver2, resolver3]
    end
  end
end
