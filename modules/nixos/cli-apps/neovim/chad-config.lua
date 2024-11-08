M = {}

M.base46 = {
  theme = "onedark",
  hl_override = {
    ["@punctuation.delimiter"] = { fg = "white" },
    ["@punctuation.bracket"] = { fg = "blue" },
    ["@tag.delimiter"] = { fg = "white" },
    ["@tag.attribute"] = { link = "@markup.raw" },
    SpecialChar = { link = "Special" },
  },
  hl_add = {
    erubyDelimiter = { link = "Define" },
    rubyStringDelimiter = { fg = "green" },
    htmlTag = { link = "Normal" },
    htmlEndTag = { link = "Normal" },
    htmlArg = { link = "@markup.raw" },
    ["@tag.html"] = { fg = "red" },
  },
}

M.ui = {
  statusline = {
    theme = "vscode_colored",
  }
}

return M
