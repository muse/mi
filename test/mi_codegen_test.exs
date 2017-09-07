defmodule MiCodegenTest do
  alias Mi.{AST, Lexer, Parser, Codegen}
  use   ExUnit.Case

  defp lex_parse_gen(expr) do
    with {:ok, tokens} <- Lexer.lex(expr),
         {:ok, ast}    <- Parser.parse(tokens),
      do: Codegen.generate(ast)
  end

  describe "&Codegen.generate/1" do
    test "Lists are generated" do
      ast = [
        %AST.List{
          items: [%AST.Number{value: "1"}, %AST.Number{value: "2"},
                  %AST.Symbol{name: "test"}, %AST.Identifier{name: "ww"}]
        }
      ]

      {:ok, program} = Codegen.generate(ast)

      assert program === ~s([1, 2, "test", ww];)
    end

    test "Expressions are generated" do
      ast = [
        %AST.Expression{
          operator: :+,
          arguments: [
            %AST.Number{value: "1"},
            %AST.Number{value: "2"},
            %AST.Number{value: "3"},
            %AST.Expression{
              operator: :*,
              arguments: [%AST.Number{value: "4"},
                          %AST.Number{value: "5"}]
            }
          ]
        }
      ]

      {:ok, program} = Codegen.generate(ast)

      assert program === "(1 + 2 + 3 + (4 * 5));"
    end

    test "Define is generated" do
      ast = [
        %AST.Define{
          default?: false, name: "x",
          value: %AST.Expression{
            operator: :*,
            arguments: [%AST.Number{value: "8"},
                        %AST.Number{value: "8"}]
          }
        },
        %AST.Define{default?: true, name: "y",
                    value: %AST.Symbol{name: "default"}}
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
    end
  end
end
