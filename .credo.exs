%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.WithSingleClause, false},
        {Credo.Check.Refactor.Nesting, max_nesting: 3}
      ]
    }
  ]
}
