defmodule Mi.REPL do
  @moduledoc """
  Read and write based on user io.
  """

  def loop() do

  end

  def read(message) do
    String.trim(IO.gets(message))
  end

  def print() do
    :ok
  end

  def evaluate() do
    :ok
  end
end
