defmodule MerkleTreeRootTest do
  use ExUnit.Case
  use ExUnitProperties

  @max_txn_number 1000
  @txn_length 16

  property "Root calculation returns the same value as reference implementation" do
    check all txn_num <- StreamData.integer(1..@max_txn_number),
              txn_list <- StreamData.list_of(StreamData.binary(length: @txn_length), length: txn_num),
              parallel <- StreamData.boolean() do
      assert reference_computing(txn_list) == MerkleTreeRoot.compute(txn_list, parallel: parallel)
    end
  end

  ################################################################################################
  #                                 reference implementation                                     #
  ################################################################################################
  defp reference_computing(transactions) do
    transactions
    |> Enum.map(&(hash(&1)))
    |> process_tree()
  end

  defp process_tree([root]), do: {:ok, root}

  defp process_tree(nodes) do
    nodes
    |> Enum.chunk_every(2)
    |> Enum.reduce([], fn
      [left_node, right_node], acc -> [hash(left_node, right_node) | acc]
      [single_node], acc -> [hash(single_node, single_node) | acc]
    end)
    |> Enum.reverse()
    |> process_tree()
  end

  defp hash(transaction),
       do: :crypto.hash(:sha256, "#{transaction}") |> Base.encode16(case: :lower)

  defp hash(left_node, right_node),
       do: :crypto.hash(:sha256, "#{left_node}#{right_node}") |> Base.encode16(case: :lower)
end
