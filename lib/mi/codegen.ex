defmodule Mi.Codegen do
  alias Mi.{AST, Codegen}

  defstruct program: "", ast: []

  @type t :: %__MODULE__{
    program: String.t,
    ast: AST.t
  }

  @spec generate(AST.t) :: String.t
  def generate(ast), do: do_generate(%Codegen{ast: ast})

  @spec do_generate(Codegen.t) :: {:ok, String.t}
  defp do_generate(%Codegen{ast: [], program: program}) do
    {:ok, program}
  end
  defp do_generate(%Codegen{ast: [node | rest]} = codegen) do
    result = generate_top_level(node)
    do_generate(%{codegen | ast: rest, program: codegen.program <> result})
  end

  @spec generate_top_level(AST.tnode) :: {:ok, AST.t, String.t}
  defp generate_top_level(node) do
    generate_node(node) <> ";"
  end

  @spec generate_node(AST.tnode) :: {:ok, AST.t, String.t}
  defp generate_node(node) do
    case node do
      %AST.List{}       -> generate_list(node)
      %AST.Expression{} -> generate_expression(node)
      %AST.Lambda{}     -> generate_lambda(node)
      %AST.Number{}     -> node.value
      %AST.String{}     -> ~s("#{node.value}")
      %AST.Symbol{}     -> ~s("#{node.name}")
      %AST.Identifier{} -> node.name
      %AST.Bool{}       -> node.value
      %AST.Nil{}        -> "null"
    end
  end

  @spec generate_list(AST.List.t, [String.t]) :: {:ok, String.t}
  defp generate_list(list, generated_items \\ [])
  defp generate_list(%AST.List{items: []}, generated_items) do
    items = generated_items |> Enum.reverse |> Enum.join(", ")
    "[#{items}]"
  end
  defp generate_list(%AST.List{items: [item | rest]} = list, generated_items) do
    result = generate_node(item)
    generate_list(%{list | items: rest}, [result | generated_items])
  end

  @spec generate_expression(AST.Expression.t, [String.t]) :: {:ok, String.t}
  defp generate_expression(expr, generated_items \\ [])
  defp generate_expression(%AST.Expression{arguments: []} = expr, generated_args) do
    expression = generated_args |> Enum.reverse |> Enum.join(" #{expr.operator} ")
    "(#{expression})"
  end
  defp generate_expression(%AST.Expression{arguments: [arg | rest]} = expr, generated_args) do
    result = generate_node(arg)
    generate_expression(%{expr | arguments: rest}, [result | generated_args])
  end

  @spec generate_lambda(AST.Lambda.t) :: {:ok, String.t}
  defp generate_lambda(%AST.Lambda{} = lambda) do
    params = Enum.join(lambda.parameters, " ")
    body = generate_body(lambda.body)

    "function #{lambda.name}(#{params}) { #{body} }"
  end

  @spec generate_body([AST.tnode], [String.t]) :: String.t
  defp generate_body(nodes, generated_nodes \\ [])
  defp generate_body([], generated_nodes) do
    "\n" <> (generated_nodes |> Enum.reverse |> Enum.join(";\n"))
  end
  defp generate_body([node | rest], generated_nodes) do
    result = generate_node(node)
    generate_body(rest, [result | generated_nodes])
  end
end
