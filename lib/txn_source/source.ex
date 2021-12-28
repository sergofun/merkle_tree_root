defmodule MerkleTreeRoot.Source do
  @moduledoc """
    This module defines API for the transactions acquisition
    You can implement own adapter in accordance with desired transactions
    source and format
  """

  @callback transactions(term()) :: Enumerable.t()

end
