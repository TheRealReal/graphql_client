![Tests](https://github.com/TheRealReal/graphql_client/actions/workflows/ci.yml/badge.svg)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

# Graphql Client

A client-side GraphQL library.

## Installation

Add `graphql_client` to you list of dependencies:

```elixir
def deps do
  [{:graphql_client, "~> 0.1"}]
end
```

**Creating a backend**

Now, you need to implement the `GraphQL.Client` behaviour:

```elixir
defmodule MyClient do
  @behaviour GraphQL.Client

  def execute_query(query, variables, options) do
    # your implementation
  end
end
```

**Configuring the client**

In your configuration, set it as your backend:

```elixir
config :graphql_client, backend: MyClient
```

Now, any call to `GraphQL.Client` will use the configured backend.

## Usage
### GraphQL as code

To build queries, you can `import` all functions from `GraphQL.QueryBuilder`.

A simple query, like this one:

```graphql
query User($slug: String! = "*"){
  user(slug: $slug){
    id
    email
}
```

Can be built using the following snippet:

```elixir
import GraphQL.QueryBuilder

user_query = query("User", %{slug: {"String!", "*"}}, [
  field(:user, %{slug: :"$slug"}, [
    field(:id),
    field(:email)
  ])
])
```

Now, the `user_query` variable contains a _representation_ of this GraphQL operation. If you inspect it, you'll see this:

```elixir
%GraphQL.Query{
  fields: [
    %GraphQL.Node{
      alias: nil,
      arguments: %{slug: :"$slug"},
      name: :user,
      node_type: :field,
      nodes: [
        %GraphQL.Node{
          alias: nil,
          arguments: nil,
          name: :id,
          node_type: :field,
          nodes: nil,
          type: nil
        },
        %GraphQL.Node{
          alias: nil,
          arguments: nil,
          name: :email,
          node_type: :field,
          nodes: nil,
          type: nil
        }
      ],
      type: nil
    }
  ],
  fragments: [],
  name: "User",
  operation: :query,
  variables: [
    %GraphQL.Variable{
      default_value: "*",
      name: :slug,
      type: "String!"
    }
  ]
}
```

But most of the time you'll not need to handle this directly.


### Executing queries

To execute this query, you can now call the `GraphQL.Client` and use this query directly:

```elixir
GraphQL.Client.execute(user_query, %{slug: "some-user"})
```

From the POV of the code that it's calling, it doesn't know if this client is using HTTP, smoke signals or magic.

All you know is that this function will always return a `%GraphQL.Response{}` struct.


To get the actual text body, you can use `GraphQL.Encoder.encode/1` function:

```
iex> user_query |> GraphQL.Encoder.encode() |> IO.puts()
query User($slug: String! = "*") {
  user(slug: $slug) {
    id
    email
  }
}
:ok
```

### The Query Registry

The end goal is to merge different queries into one operation and the query registry does exactly that.

It will accumulate queries, variables and resolvers (yes, resolvers!), merge them, and then execute resolvers with an accumulator.

```elixir
user_query = query(...)
product_query = query(...)

user_resolver = fn response, acc ->
  # do something with the response and return the updated accumulator
  updated_acc
end

registry = QueryRegistry.new("BigQuery")

result = 
  registry
  |> QueryRegistry.add_query(user_query, user_variables,[user_resolver])
  |> QueryRegistry.add_query(product_query, product_variables)
  |> QueryRegistry.execute(%{}, options)

```

A resolver function must accept two parameters: a `%GraphQL.Response{}` struct and the accumulator defined by the query registry.

### Testing

The `%GraphQL.Response{}` is the only thing clients must return, and that we can configure the backend via config files.

Internally, during tests, the backend will be changed to `LocalBackend`, that uses an Agent process to store responses.

Call `GraphQL.LocalBackend.start_link/0` on your `test_helper.exs` file.

Now you can use the `GraphQL.LocalBackend.expect/1` function:

```elixir
import GraphQL.LocalBackend, only: [expect: 1]
alias GraphQL.Response

test "my test" do
  my_registry = QueryRegistry.new(...)
  response = Response.success(%{field: "value"})
  expect(my_registry, response)
  assert 1 == 1
end
```

If you need to inspect and assert the query and variables, you can pass a function:

```elixir
import GraphQL.LocalBackend, only: [expect: 1]
alias GraphQL.Response

test "my test" do
  my_registry = QueryRegistry.new(...)

  expect(my_registry, fn query, _variables, _options ->
    assert query == expected_query
    Response.success(%{field: "value"})
  end)
  assert 1 == 1
end
```

## Code of Conduct

This project  Contributor Covenant version 2.1. Check [CODE_OF_CONDUCT.md](/CODE_OF_CONDUCT.md) file for more information.

## License

`graphql_client` source code is released under Apache License 2.0.

Check [NOTICE](/NOTICE) and [LICENSE](/LICENSE) files for more information.
