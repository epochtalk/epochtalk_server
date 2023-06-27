%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["mix.exs", "lib/", "test/"],
        excluded: ["test/seed/"]
      },
      checks: [
        {Credo.Check.Readability.WithSingleClause, false},
        {Credo.Check.Refactor.Nesting, max_nesting: 3}
      ]
    }
  ]
}
