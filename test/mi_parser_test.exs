defmodule MiParserTest do
  alias Mi.{Parser, Lexer, AST}
  use   ExUnit.Case

  describe "&Parser.parse/1" do
    test "Expressions are parsed" do
      {:ok, tokens} = Lexer.lex("(+ 1 (* 5 5))")
      {:ok, ast} = Parser.parse(tokens)

      assert ast === [[%AST.Operator{value: :+}, %AST.Number{value: '1'},
                      [%AST.Operator{value: :*}, %AST.Number{value: '5'},
                                                 %AST.Number{value: '5'}]]]
    end
  end
end
