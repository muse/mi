defmodule Mi do
  import Mi.Utils

  alias Mi.{Parser, Lexer, Codegen}

  def main(_) do
    input =
      case IO.read(:stdio, :all) do
        {:error, reason} -> fatal_error("mi", reason)
        data -> data
      end

    tokens =
      case Lexer.lex(input) do
        {:ok, tokens}    -> tokens
        {:error, reason} -> fatal_error("lexer", reason)
      end

    IO.puts 'TOKENS'
    # IO.inspect tokens
    IO.inspect '# ======= #'


    ast =
      case Parser.parse(tokens) do
        {:ok, ast}       -> ast
        {:error, reason} -> fatal_error("parser", reason)
      end

    IO.puts 'AST'
    # IO.inspect ast
    IO.inspect '# ======= #'

    code =
      case Codegen.generate(ast) do
        {:ok, code}      -> code
        {:error, reason} -> fatal_error("codegen", reason)
      end

    IO.puts 'CODE'
    IO.puts code
  end
end
