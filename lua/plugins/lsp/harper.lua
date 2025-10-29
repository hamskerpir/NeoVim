local lsp = "harper-ls"

vim.lsp.config(lsp, {
	userDictPath = "~/.config/harper/userDict",
	workspaceDictPath = "",
	fileDictPath = "",
	linters = {
		SpellCheck = true,
		SpelledNumbers = false,
		AnA = true,
		SentenceCapitalization = true,
		UnclosedQuotes = true,
		WrongQuotes = false,
		LongSentences = true,
		RepeatedWords = true,
		Spaces = true,
		Matcher = true,
		CorrectNumberSuffix = true,
	},
	codeActions = {
		ForceStable = false,
	},
	markdown = {
		IgnoreLinkTitle = false,
	},
	diagnosticSeverity = "hint",
	isolateEnglish = false,
	dialect = "American",
	maxFileLength = 120000,
	ignoredLintsPath = {},
})

return {}
