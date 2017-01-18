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
      ast = [
        %Mi.AST.List{
          items: [%Mi.AST.Number{value: "1"}, %Mi.AST.Number{value: "2"},
                  %Mi.AST.Symbol{name: "test"}, %Mi.AST.Identifier{name: "ww"}]
        }
      ]

      {:ok, program} = Codegen.generate(ast)

      assert program === ~s([1, 2, "test", ww];)
    end

    test "Expressions are generated" do
      ast = [
        %Mi.AST.Expression{
          operator: :+,
          arguments: [
            %Mi.AST.Number{value: "1"},
            %Mi.AST.Number{value: "2"},
            %Mi.AST.Number{value: "3"},
            %Mi.AST.Expression{
              operator: :*,
              arguments: [%Mi.AST.Number{value: "4"},
                          %Mi.AST.Number{value: "5"}]}]
        }
      ]

      {:ok, program} = Codegen.generate(ast)

      assert program === "(1 + 2 + 3 + (4 * 5));"
    end

    test "Define is generated" do
      ast = [
        %Mi.AST.Variable{
          default?: false, name: "x",
          value: %Mi.AST.Expression{
            operator: :*,
            arguments: [%Mi.AST.Number{value: "8"},
                        %Mi.AST.Number{value: "8"}]
          }
        },
        %Mi.AST.Variable{default?: true, name: "y",
                         value: %Mi.AST.Symbol{name: "default"}}
      ]

      {:ok, program} = Codegen.generate(ast)

      assert program === "var x = (8 * 8);var y = y || \"default\";"
    end

    test "Lambdas are generated" do
      {:ok, _} = lex_parse_gen("""
      (lambda (x) (+ x 5))
      (lambda test (x) (+ x 5))
      """)
    end

    test "Functions are generated" do
      {:ok, _} = lex_parse_gen("""
      (defun test () 5)
      """)
    end

    test "Function calls are generated" do
      {:ok, _} = lex_parse_gen("""
      (test 1 2 3)
      """)
    end

    test "Use statements are generated" do
      {:ok, program} = lex_parse_gen("""
      (use* "http" 'myhttp)
      """)

      IO.puts program
    end
  end
end
