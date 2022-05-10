# Changelog for `graphql_client`

## v0.2.0

### Changes
  - `GraphQL.Query.merge/3` and `GraphQL.Query.merge_many/2` now return ok/error tuples instead of structs - the new
    check for duplicated variables may now invalidate a merge and return an error.

### Bugfixes
  - Do not allow variables to be added twice, even when declared with different key types

## v0.1.2

### Bugfixes
  - Fix the return value of `GraphQL.LocalBackend.execute_query/2`

## v0.1.1

### New Features
  - Enable recursive expression for variables
  - New function `GraphQL.QueryBuilder.enum/1`, to declare enum values so they are rendered without quotes.
## v0.1.0

First version!

### New Features
  - GraphQL query representation using elixir code!
  - Merge queries into a single operation
  - Testing suppport
