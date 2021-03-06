defmodule MerkleTreeRoot.FileAdapter do
  @moduledoc """
    Adapter for file, which has one transaction per line
  """

  @behaviour MerkleTreeRoot.Source

  @impl true
  def transactions(file_path) do
    file_path
    |> File.stream!()
    |> Stream.map(&(String.trim_trailing(&1)))
  end

end
