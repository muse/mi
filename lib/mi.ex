defmodule Mi do
  import Mi.Utils

  alias Mi.{Parser, Lexer}

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

    IO.inspect tokens
    IO.inspect '# ======= #'
    IO.inspect ast
  end
end
