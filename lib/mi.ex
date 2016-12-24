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

    parser =
      case Parser.parse(input) do
        {:ok, parser}    -> parser
        {:error, reason} -> fatal_error("parser", reason)
      end

    IO.inspect tokens
    IO.inspect '# ======= #'
    IO.inspect parse
  end
end
