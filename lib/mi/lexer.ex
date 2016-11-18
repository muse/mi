defmodule Mi.Lexer do
  @moduledoc """
  This lexer module converts a sequence of characters into a sequence of
  tokens, removing unnecessary whitespace while doing so. These tokens will later
  be passed to the parser to create an abstract syntax tree which will
  eventually be used to generate Javascript.
  """

  import Mi.Token, only: :macros

  alias Mi.Lexer
  alias Mi.Token

  defstruct errors: [], tokens: [], line: 1, pos: 1

  defp lexer_error(lexer, message) do
    "#{lexer.line}:#{lexer.pos}: #{message}"
  end

  defp lex_identifier(expr, acc \\ '')
  defp lex_identifier([char | rest], acc)
    when is_identifier_literal(char) or
         is_numeric_literal(char) do
    lex_identifier(rest, acc ++ [char])
  end
  defp lex_identifier(expr, acc) do
    {expr, acc}
  end

  defp lex_string(expr, acc \\ '')
  defp lex_string([?\\, char | rest], acc) do
    lex_string(rest, acc ++ [?\\, char])
  end
  defp lex_string([char | rest], acc) when char === ?" do
    {rest, acc}
  end
  defp lex_string([char | rest], acc) do
    lex_string(rest, acc ++ [char])
  end

  defp lex_number(expr, acc \\ '')
  defp lex_number([char | rest], acc) when is_numeric_literal(char) do
    lex_number(rest, acc ++ [char])
  end
  defp lex_number(expr, acc) do
    {expr, acc}
  end

  defp lex_atom(expr, acc \\ '')
  defp lex_atom([char | rest], acc) when is_atom_literal(char) do
    lex_atom(rest, acc ++ [char])
  end
  defp lex_atom(expr, acc) do
    {expr, acc}
  end

  defp skip_comment([]), do: []
  defp skip_comment([?\n | _rest] = expr), do: expr
  defp skip_comment([_char | rest]), do: skip_comment(rest)

  def lex(expr),       do: lex(to_charlist(expr), %Lexer{})
  defp lex([], lexer), do: lexer
  defp lex([?\n | rest], lexer) do
    # Newline
    lex(rest, %{lexer | line: lexer.line + 1, pos: 1})
  end
  defp lex([?; | rest], lexer) do
    # Skip comment
    lex(skip_comment(rest), lexer)
  end
  defp lex([char | rest], lexer) when is_whitespace(char) do
    # Skip whitespace
    lex(rest, %{lexer | pos: lexer.pos + 1})
  end
  defp lex([char | rest] = expr, lexer) do
    {value, type} =
      case char do
        ?( -> {char, :oparen}
        ?) -> {char, :cparen}
        ?+ -> {char, :+}
        ?- -> {char, :-}
        ?/ -> {char, :/}
        ?* -> {char, :*}
        ?^ -> {char, :^}
        ?& -> {char, :&}
        ?| -> {char, :|}
        ?' -> {char, :quote}
        ?" ->
          {rest, value} = lex_string(rest)
          {value, :string}
        ?: ->
          {rest, value} = lex_atom(rest)
          {value, :atom}
        char when is_numeric_literal(char) ->
          {rest, value} = lex_number(expr)
          {value, :number}
        char when is_identifier_literal(char) and not is_numeric_literal(char) ->
          {rest, value} = lex_identifier(expr)

          if Token.keyword?(value) do
            {value, List.to_atom(value)}
          else
            {value, :identifier}
          end
        _ ->
          {char, :error}
      end

    token = Token.new(lexer, %{value: value, type: type})

    lex(rest, %{lexer |
      tokens: lexer.tokens ++ [token],
      pos: lexer.pos + String.length(to_string(token.value))
    })
  end
end
