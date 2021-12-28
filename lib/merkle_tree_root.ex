defmodule MerkleTreeRoot do
  @moduledoc """
    Functions for computing Merkle tree root and transactions collection acquisition.

    ## example
      iex> MerkleTreeRoot.FileAdapter |> MerkleTreeRoot.txns("./priv/sample_8") |> MerkleTreeRoot.compute
        {:ok, "bdd07e07772861b7c4e954674c2b012246249f4f4e9c0071d387d3077909c919"}
      iex> MerkleTreeRoot.FileAdapter |> MerkleTreeRoot.txns("./priv/sample_1000") |> MerkleTreeRoot.compute(paraller: true)
        {:ok, "ad079a53015f07e9ba30e9118eab6f673d1f70dad2d6dc8c9d84fe9f8d51c594"}
  """

  require Logger

  @type transaction :: String.t()
  @type root :: String.t()
  @type tree_node :: String.t | {integer(), String.t()}
  @type tree_chunk :: [node()]

  @doc """
    Takes out transactions in accordance with provided adapter and parameters
  """
  @spec txns(module(), term()) :: Enumerable.t()
  def txns(adapter_module, params),
      do: adapter_module.transactions(params)

  @doc """
    Calculates Merkle tree root
    ## parameters
      - transactions: transactions collection
      - options: options, supported options:
        :parallel - boolean
    ## example
      iex> 1..800 |> Enum.map(&(Integer.to_string(&1))) |> MerkleTreeRoot.compute(parallel: true)
        {:ok, "b360ad8a433373acf304bbaf51ab35e67830b494cb58c3fbac9192772046eaaa"}
      iex> 1..800 |> Enum.map(&(Integer.to_string(&1))) |> MerkleTreeRoot.compute()
        {:ok, "b360ad8a433373acf304bbaf51ab35e67830b494cb58c3fbac9192772046eaaa"}
  """
  @spec compute([transaction()], keyword()) :: {:ok, root()} | {:error, String.t()}
  def compute(transactions, options \\ [])
  def compute([], _options),
      do: {:error, "wrong transactions collection"}

  def compute(transactions, options) when is_list(transactions) do
    parallel_processing = Keyword.get(options, :parallel, false)

    transactions
    |> prepare_first_layer_nodes(parallel_processing)
    |> process_tree(parallel_processing)
  end

  def compute(_transactions, _options),
      do: {:error, "wrong transactions collection"}

  # Prepares bottom layer nodes. In case of parallel processing it also assigns sequence numbers for the subsequent
  # sorting
  @spec prepare_first_layer_nodes([transaction()], boolean()) :: [tree_node()]
  defp prepare_first_layer_nodes(transactions, false) do
    transactions
    |> Stream.map(&hash(&1))
    |> Enum.to_list()
  end

  defp prepare_first_layer_nodes(transactions, true) do
    transactions
    |> Stream.transform(0, &{[{&2, hash(&1)}], &2 + 1})
    |> Stream.chunk_every(2)
    |> Flow.from_enumerable()
    |> Flow.reduce(fn -> [] end, fn
      [{left_num, left_node}, {right_num, right_node}], acc ->
        [{left_num + right_num, hash(left_node, right_node)} | acc]
      result, [] -> result
      [{num, last_node}], acc -> [{num + num, hash(last_node, last_node)} | acc]
    end)
    |> Enum.to_list()
  end

  # Processes merkle tree (splits into pairs and calculates next layer nodes)
  @spec process_tree([tree_node()], boolean()) :: {:ok, root()}
  defp process_tree([{_num, tree_root}], _),
       do: {:ok, tree_root}

  defp process_tree([tree_root], _),
       do: {:ok, tree_root}

  defp process_tree(nodes, parallel) do
    nodes
    |> prepare_nodes(parallel)
    |> calc_nodes(parallel)
    |> process_tree(parallel)
  end

  # Groups nodes for the tree next layer processing
  # for the single process calculation just splits into chunks
  # for the parallel calculation performs nodes sorting and nodes pair numeration
  @spec prepare_nodes([tree_node()], boolean()) :: [tree_chunk()]
  defp prepare_nodes(nodes, false),
    do: Enum.chunk_every(nodes, 2)

  defp prepare_nodes(nodes, true) do
    nodes
    |> Enum.sort(fn {number1, _node1}, {number2, _node2} -> number1 < number2 end)
    |> Enum.chunk_every(2)
    |> Enum.reduce(%{pair_key: 0, acc: []}, fn
      [{_, left_node}, {_, right_node}], %{pair_key: pair_key, acc: acc} ->
        %{pair_key: pair_key + 1, acc: [{pair_key, [left_node, right_node]} | acc]}

      [{_, single_node}], %{pair_key: pair_key, acc: acc} ->
        %{pair_key: pair_key + 1, acc: [{pair_key, [single_node, single_node]} | acc]}
    end)
    |> Map.get(:acc)
  end

  # Calculates current tree layer nodes
  @spec calc_nodes([tree_chunk()], boolean()) :: [tree_node()]
  defp calc_nodes(chunks, false) do
    chunks
    |> Enum.reduce([], fn
      [left_node, right_node], acc -> [hash(left_node, right_node) | acc]
      [single_node], acc -> [hash(single_node, single_node) | acc]
    end)
    |> Enum.reverse()
  end

  defp calc_nodes(chunks, true) do
    chunks
    |> Flow.from_enumerable()
    |> Flow.map(fn {num, [left, right]} -> {num, hash(left, right)} end)
    |> Enum.to_list()
  end

  # Calculates SHA256 hash for the transaction
  @spec hash(transaction()) :: String.t()
  defp hash(transaction),
    do: :crypto.hash(:sha256, "#{transaction}") |> Base.encode16(case: :lower)

  # Calculates SHA256 hash by using two nodes values
  @spec hash(tree_node(), tree_node()) :: String.t()
  defp hash(left_node, right_node),
    do: :crypto.hash(:sha256, "#{left_node}#{right_node}") |> Base.encode16(case: :lower)
end
