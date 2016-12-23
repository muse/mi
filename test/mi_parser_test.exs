defmodule MiParserTest do
  alias Mi.{Parser, AST}
  use   ExUnit.Case

  describe "&Parser.parse/1" do
    test "Literal lists are parsed" do
      {:ok, ast} = Parser.parse("('(1 \"ok\" 3 4) '() '('()))")

      assert [[
        %AST.List{items: [%AST.Number{value: "1"},
                          %AST.String{value: "ok"},
                          %AST.Number{value: "3"},
                          %AST.Number{value: "4"}]},
        %AST.List{items: []},
        %AST.List{items: [%AST.List{items: []}]}
      ]] === ast
    end

    test "Expressions are parsed" do
      {:ok, ast} = Parser.parse("(+ 1 2 (* 3 3))")

      assert [
        %AST.Expression{
          operator: :plus,
          arguments: [%AST.Number{value: "1"},
                      %AST.Number{value: "2"},
                      %AST.Expression{
                        operator: :*,
                        arguments: [
                          %AST.Number{value: "3"},
                          %AST.Number{value: "3"}
                        ]
                      }]}
      ] === ast
    end

    test "Expressions error accordingly" do
      {:error, error} = Parser.parse("(* 1)")
      assert String.contains?(error, "not enough arguments")

      {:error, error} = Parser.parse("(typeof true false)")
      assert String.contains?(error, "too many arguments")

      {:error, error} = Parser.parse("(-)")
      assert String.contains?(error, "missing argument(s)")

      assert {:ok, _} = Parser.parse("(- 1)")
      assert {:ok, _} = Parser.parse("(- 1 2)")
      assert {:ok, _} = Parser.parse("(- 1 2 3)")
    end

    test "Use statements are parsed" do
      {:ok, ast} = Parser.parse("((use \"http\") (use* \"http\" 'myhttp))")

      assert [[
        %AST.Use{module: "http", name: "http"},
        %AST.Use{module: "http", name: "myhttp"}
      ]] === ast
    end

    test "Use statements error accordingly" do
      assert {:error, _} = Parser.parse("(use)")
      assert {:error, _} = Parser.parse("(use* \"http\" myhttp)")
      assert {:error, _} = Parser.parse("(use* \"http\")")
      assert {:error, _} = Parser.parse("(use* \"http\" 'myhttp \"extra string\")")
    end
  end
end
