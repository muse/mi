defmodule MiCodegenTest do
  alias Mi.{Lexer, Parser, Codegen}
  use   ExUnit.Case

  defp lex_parse_gen(expr) do
    with {:ok, tokens} <- Lexer.lex(expr),
         {:ok, ast}    <- Parser.parse(tokens),
      do: Codegen.generate(ast)
  end

  describe "&Codegen.generate/1" do
    test "Lists are generated" do
      {:ok, program} = lex_parse_gen("'(1 2 'test ww)")

      assert program === ~s([1, 2, "test", ww];)
    end

    test "Expressions are generated" do
      {:ok, program} = lex_parse_gen("(+ 1 2 3 (* 4 5))")

      assert program === "(1 + 2 + 3 + (4 * 5));"
    end

    test "Lambdas are generated" do
      {:ok, program} = lex_parse_gen("(lambda (x) (+ x 5))")

      IO.puts program
    end
  end
end
