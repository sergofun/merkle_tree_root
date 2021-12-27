defmodule MerkleTreeRoot.Source do
  @moduledoc """
    This module defines API for the transactions acquisition
    You can your own adapter in accordance with desired transactions
    source
  """

  @callback transactions(term()) :: Enumerable.t()

end
