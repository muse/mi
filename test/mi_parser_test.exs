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
          operator: :add,
          arguments: [%AST.Number{value: "1"},
                      %AST.Number{value: "2"},
                      %AST.Expression{
                        operator: :*,
                        arguments: [
                          %AST.Number{value: "3"},
                          %AST.Number{value: "3"}
                        ]
                      }]}
      ] = ast
    end
  end
end
