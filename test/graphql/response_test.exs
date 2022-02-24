defmodule GraphQL.ResponseTest do
  use ExUnit.Case, async: true

  alias GraphQL.Response

  doctest Response, import: true

  describe "success/1" do
    test "creates a new Response struct marked as success" do
      expected = %Response{
        success?: true,
        data: %{
          field: %{
            name: "Blorgon"
          }
        }
      }

      result =
        Response.success(%{
          field: %{
            name: "Blorgon"
          }
        })

      assert result == expected
    end
  end

  describe "failure/1" do
    test "creates a new Response struct marked as failure" do
      expected = %Response{
        success?: false,
        errors: [%{message: "Some error", locations: [%{line: 1, column: 1}]}]
      }

      result = Response.failure([%{message: "Some error", locations: [%{line: 1, column: 1}]}])

      assert result == expected
    end
  end

  describe "partial_success/2" do
    test "creates a new Response struct marked as a partial success" do
      expected = %Response{
        success?: :partial,
        data: %{
          field: %{
            name: "Blorgon"
          }
        },
        errors: [
          %{message: "Some error", locations: [%{line: 1, column: 1}]}
        ]
      }

      result =
        Response.partial_success(
          %{field: %{name: "Blorgon"}},
          [%{message: "Some error", locations: [%{line: 1, column: 1}]}]
        )

      assert result == expected
    end
  end
end
