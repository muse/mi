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

    ast =
      case Parser.parse(tokens) do
        {:ok, ast}       -> ast
        {:error, reason} -> fatal_error("parser", reason)
      end

    code =
      case Codegen.generate(ast) do
        {:ok, code}      -> code
        {:error, reason} -> fatal_error("codegen", reason)
      end

    IO.inspect tokens
    IO.inspect '# ======= #'
    IO.inspect ast
    IO.inspect '# ======= #'
    IO.inspect code
  end
end
