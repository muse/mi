defmodule MiParserTest do
  alias Mi.{Parser, Lexer, AST}
  use   ExUnit.Case

  describe "&Parser.parse/1" do
    test "Expressions are parsed" do
      {:ok, tokens} = Lexer.lex("('(1 2 3 4))")
      {:ok, ast} = Parser.parse(tokens)
    end
  end
end
