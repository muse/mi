defmodule Mi.Token do
  @moduledoc """
  A token is a categorization of text to be used by the parser.
  """

  alias Mi.Token

  defstruct [:value, :type, :line, :pos]

  @type t :: %__MODULE__{
    value: charlist,
    type: type,
    line: pos_integer,
    pos: pos_integer
  }

  @type type :: atom


  defimpl String.Chars, for: Token do
    def to_string(token), do: "#{token.value}"
  end

  defmacro is_whitespace(c) do
    quote do: unquote(c) in [?\t, ?\s, ?\r]
  end

  defmacro is_atom_literal(c) do
    quote do: unquote(c) in ?a..?z or unquote(c) in ?A..?Z or
      unquote(c) in [?_, ?-, ?+, ?-, ?*, ?/, ?%, ?^, ?@, ?!, ?&, ?|]
  end

  defmacro is_numeric_literal(c) do
    quote do: unquote(c) in ?0..?9 or unquote(c) === ?.
  end

  defmacro is_identifier_literal(c) do
    quote do: unquote(c) in ?a..?z or unquote(c) in ?A..?Z or
      unquote(c) in ?0..?9 or unquote(c) in [?-, ?@, ?/, ?!]
  end

  defmacro is_start_of_identifier(c) do
    quote do: unquote(c) in ?a..?z or unquote(c) in ?A..?Z or unquote(c) === ?@
  end

  defmacro is_operator(token) do
    quote do:
      unquote(token.type) in [:+, :-, :/, :*, :bshiftl, :bshiftr, :<, :>,
                              :bnot, :bxor, :bor, :band, :and, :or, :not]
  end

  @keywords [
    'lambda',
    'define',
    'or',
    'and',
    'not',
    'use',
    'loop',  # for, while
    'cond',  # if
    'case',
    'try',
    'catch',
    'throw',
    'true',
    'false',
    'nil',
  ]

  @spec new(%{pos: pos_integer, line: pos_integer}, charlist, type) :: Token.t
  def new(%{pos: pos, line: line}, value, type) do
    %Token{
      value: value,
      type: type,
      pos: pos,
      line: line
    }
  end

  @doc """
  Check if a charlist is a keyword.

  ## Example:
  iex> Mi.Lexer.Token.keyword?('lambda')
  true

  """
  @spec keyword?(charlist) :: boolean
  def keyword?(value), do: value in @keywords
end
