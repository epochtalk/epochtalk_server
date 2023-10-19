defmodule Test.EpochtalkServer.Regex do
  use Test.Support.ConnCase, async: true

  describe "pattern/1" do
    test "given valid atom, gets pattern" do
      assert EpochtalkServer.Regex.pattern(:username_mention) != nil
      assert EpochtalkServer.Regex.pattern(:username_mention_curly) != nil
      assert EpochtalkServer.Regex.pattern(:user_id) != nil
    end

    test "given invalid atom, returns nil" do
      assert EpochtalkServer.Regex.pattern(:bad_atom) == nil
    end
  end

  @mentions_string """
  Money printer go @brrrrr genesis block proof-of-work @blockchain Bitcoin
  Improvement Proposal bitcoin@Bitcoin.com Improvement Proposal segwit sats.
  Hard fork to the moon hard fork soft fork key pair soft fork mining.
  Soft fork proof-of-work@gmail.com block reward mempool @hodl,
  @__decentralized-deflationary_monetary.policy__full..node.

  @Hodl halvening genesis block outputs, @BloCkchAIn public key
  @satoshis[code]double-spend @problem[/code] @volatility
  [code][code]Block height @satoshis segwit UTXO electronic cash[/code][/code]
  Digital @signature@UTXO.soft fork UTXO money printer go @brrrrr, price action
  blocksize when @lambo! Merkle Tree hashrate?@Full node stacking sats @volatility block reward,
  soft fork Merkle Tree halvening digital @signature.
  """

  @mentions_usernames [
    "brrrrr",
    "blockchain",
    "hodl",
    "__decentralized-deflationary_monetary.policy__full..node.",
    "Hodl",
    "BloCkchAIn",
    "satoshis",
    "volatility",
    "signature",
    "brrrrr",
    "lambo",
    "volatility",
    "signature."
  ]

  describe "pattern/1 mentions" do
    test "given :username_mention, scans string correctly" do
      # scan test string for mentions
      matches = Regex.scan(EpochtalkServer.Regex.pattern(:username_mention), @mentions_string)

      # check usernames appear in matches
      Enum.zip(matches, @mentions_usernames)
      |> Enum.each(fn {match, username} ->
        assert match == ["@" <> username, username]
      end)
    end

    test "given :username_mention_curly, scans string with curly brace replacements correctly" do
      # replace mentions with curly brace format
      curly_test_string =
        @mentions_string
        |> String.replace(
          EpochtalkServer.Regex.pattern(:username_mention),
          &"{#{String.downcase(&1)}}"
        )

      # get possible username matches
      matches =
        Regex.scan(EpochtalkServer.Regex.pattern(:username_mention_curly), curly_test_string)

      # check usernames appear in matches
      Enum.zip(matches, @mentions_usernames)
      |> Enum.each(fn {match, username} ->
        username = String.downcase(username)
        assert match == ["{@" <> username <> "}", username]
      end)
    end

    test "given :user_id, scans string with curly brace id replacements correctly" do
      # form keyword list of downcased unique usernames with index
      # (provides pseudo user_id)
      unique_usernames_with_index =
        @mentions_usernames
        |> Enum.map(&String.downcase(&1))
        |> Enum.uniq()
        |> Enum.with_index()

      # create username to pseudo user_id map
      username_to_id_map =
        unique_usernames_with_index
        |> Enum.into(%{})

      # create pseudo user_id to username map
      id_to_username_map =
        unique_usernames_with_index
        |> Enum.into(%{}, fn {k, v} -> {v, k} end)

      # replace mentions with curly brace format
      username_mentions_string =
        @mentions_string
        |> String.replace(
          EpochtalkServer.Regex.pattern(:username_mention),
          &"{#{String.downcase(&1)}}"
        )

      # replace username mentions with user_id mentions
      user_id_mentions_string =
        unique_usernames_with_index
        |> Enum.reduce(username_mentions_string, fn {username, user_id}, acc ->
          username_mention = "{@#{username}}"
          user_id_mention = "{@#{user_id}}"

          acc
          |> String.replace(username_mention, user_id_mention)
        end)

      # create pseudo user_id mentions list from usernames list for checking mentions scan
      user_id_mentions_list =
        @mentions_usernames
        |> Enum.map(fn username -> username_to_id_map[String.downcase(username)] end)

      # check user_id's appear in matches()
      Regex.scan(EpochtalkServer.Regex.pattern(:user_id), user_id_mentions_string)
      |> Enum.zip(user_id_mentions_list)
      |> Enum.each(fn {match, id} ->
        assert match == ["{@" <> Integer.to_string(id) <> "}"]
      end)
    end
  end
end
