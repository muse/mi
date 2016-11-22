defmodule MiParserTest do
  alias Mi.{Parser, Lexer, AST}
  use   ExUnit.Case

  describe "&Parser.parse/1" do
    test "Expressions are parsed" do
      {:ok, tokens} = Lexer.lex("(+ 1 (* 5 5))")
      assert Parser.parse(tokens) ===
        [%AST.Expression{operator: :+, lhs: 1,
                         rhs: %AST.Expression{operator: :*, lhs: 5, rhs: 5}}]
    end
  end
end
