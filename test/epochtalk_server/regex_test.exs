defmodule Test.EpochtalkServer.Regex do
  use Test.Support.ConnCase, async: true

  @test_string """
  Money printer go brrrrr genesis block proof-of-work @blockchain Bitcoin
  Improvement Proposal bitcoin@Bitcoin.com Improvement Proposal segwit sats.
  Hard fork to the moon hard fork soft fork key pair soft fork mining.
  Soft fork proof-of-work@gmail.com block reward mempool @hodl,
  @__decentralized-deflationary_monetary.policy__full..node.

  @Hodl halvening genesis block outputs, @blockchain public key
  @satoshis[code]double-spend @problem[/code] @volatility
  [code][code]Block height @satoshis segwit UTXO electronic cash[/code][/code]
  Digital @signature@UTXO.soft fork UTXO money printer go brrrrr price action
  blocksize when @lambo! Merkle Tree hashrate?@Full node stacking sats @volatility block reward,
  soft fork Merkle Tree halvening digital @signature.
  """

  describe "pattern/1" do
    test "given valid atom, gets pattern" do
      assert EpochtalkServer.Regex.pattern(:username_mention) != nil
      assert EpochtalkServer.Regex.pattern(:username_mention_curly) != nil
      assert EpochtalkServer.Regex.pattern(:user_id) != nil
    end
    test "given invalid atom, returns nil" do
      assert EpochtalkServer.Regex.pattern(:bad_atom) == nil
    end

    test "given :username_mention, scans string correctly" do
      matches = Regex.scan(EpochtalkServer.Regex.pattern(:username_mention), @test_string)
      [username | matches] = matches
      assert username == ["@blockchain", "blockchain"]
      [username | matches] = matches
      assert username == ["@hodl", "hodl"]
      [username | matches] = matches
      assert username == ["@__decentralized-deflationary_monetary.policy__full..node.", "__decentralized-deflationary_monetary.policy__full..node."]
      [username | matches] = matches
      assert username == ["@Hodl", "Hodl"]
      [username | matches] = matches
      assert username == ["@blockchain", "blockchain"]
      [username | matches] = matches
      assert username == ["@satoshis", "satoshis"]
      [username | matches] = matches
      assert username == ["@volatility", "volatility"]
      [username | matches] = matches
      assert username == ["@signature", "signature"]
      [username | matches] = matches
      assert username == ["@lambo", "lambo"]
      [username | matches] = matches
      assert username == ["@volatility", "volatility"]
      [username | matches] = matches
      assert username == ["@signature.", "signature."]
    end
  end
end
