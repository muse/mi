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

    test "Use statements are parsed" do
      {:ok, ast} = Parser.parse("((use \"http\") (use* \"http\" \"myhttp\"))")

      assert [[
        %AST.Use{module: "http", name: "http"},
        %AST.Use{module: "http", name: "myhttp"}
      ]] === ast
    end

    test "Lambda statements are parsed" do
      {:ok, ast} = Parser.parse("(lambda () 5)")

      assert [[
               %AST.Lambda{name: nil, args: [], body: %AST.Number{value: "5"}}
             ]] === ast
    end
  end
end
