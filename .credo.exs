%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "config/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Refactor.ABCSize, max_size: 40},
        {Credo.Check.Refactor.Nesting, max_nesting: 3},

        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},

        {Credo.Check.Design.TagTODO, exit_status: 0},

        # {Credo.Check.Design.TagFIXME, false},
      ]
    }
  ]
}
