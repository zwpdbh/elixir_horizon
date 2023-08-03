# Current VScode settings 
```json 
{
  "security.workspace.trust.untrustedFiles": "open",
  // For F#
  "FSharp.codeLenses.signature.enabled": false,
  "FSharp.pipelineHints.enabled": false,
  "FSharp.lineLens.enabled": "never",
  "FSharp.enableTreeView": true,
  "FSharp.inlayHints.enabled": false,
  "FSharp.inlayHints.typeAnnotations": false,
  "FSharp.inlayHints.parameterNames": false,
  "FSharp.smartIndent": true,
  "[fsharp]": {
    "editor.formatOnSave": false,
    "editor.defaultFormatter": "Ionide.Ionide-fsharp"
  },
  "terminal.integrated.enableMultiLinePasteWarning": false,
  "editor.fontFamily": "'Cascadia Mono', Consolas, 'Courier New', 'Anonymous Pro', monospace",
  "editor.fontSize": 13,
  "editor.fontLigatures": false,
  "editor.bracketPairColorization.enabled": false,
  "git.confirmSync": false,
  "workbench.editorAssociations": {
    "*.pdf": "latex-workshop-pdf-hook"
  },
  "explorer.confirmDelete": false,
  "extensions.confirmedUriHandlerExtensionIds": [
    "ms-dotnettools.dotnet-interactive-vscode",
    "ms-dotnettools.vscode-dotnet-pack"
  ],
  "editor.wordWrap": "on",
  "editor.mouseWheelZoom": true,
  "git.enableSmartCommit": true,
  "terminal.integrated.fontSize": 13,
  "workbench.iconTheme": "material-icon-theme",
  "workbench.sideBar.location": "right",
  "editor.quickSuggestionsDelay": 10,
  // Set on windows, how to configure some terminal
  "terminal.integrated.profiles.windows": {
    "Command Prompt": {
      "path": "C:\\WINDOWS\\System32\\cmd.exe",
      "args": [],
      "icon": "terminal-cmd"
    },
    "Git Bash": {
      "path": "C:\\Program Files\\Git\\bin\\bash.exe",
      "args": ["--login", "-i"]
    },
    "Ubuntu-20.04 (WSL)": null
  },
  // Set on windows, the default terminal
  "terminal.integrated.defaultProfile.windows": "Git Bash",
  "terminal.integrated.profiles.linux": {
    "Command Prompt": {
      "path": "/usr/bin/bash"
    }
  },
  "indentRainbow.ignoreErrorLanguages": [
    "elixir",
    "fsharp",
    "json",
    "javascript"
  ],

  "editor.insertSpaces": true,
  "editor.tabSize": 2,
  "editor.formatOnSave": false,
  "prettier.tabWidth": 2,
  "prettier.useTabs": false,
  "[jsonc]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "indentRainbow.colorOnWhiteSpaceOnly": true,
  // For Elixir
  "[phoenix-heex]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "JakeBecker.elixir-ls"
  },
  "tailwindCSS.includeLanguages": {
    "phoenix-heex": "html",
    "elixir": "html"
  },
  "files.associations": {
    "*.heex": "phoenix-heex",
    "*.eex": "phoenix-heex"
  },
  "emmet.includeLanguages": {
    "phoenix-heex": "html",
    "html-eex": "html"
  },
  "emmet.triggerExpansionOnTab": true,

  "editor.suggestSelection": "recentlyUsedByPrefix",
  "editor.wordBasedSuggestions": true,
  "editor.quickSuggestions": {
    "comments": "inline",
    "strings": "on",
    "other": "on"
  },
  "AllAutocomplete.minWordLength": 2,
  "AllAutocomplete.maxLines": 1000,
  "AllAutocomplete.showCurrentDocument": true,
  "editor.suggest.filterGraceful": true,
  "editor.snippetSuggestions": "bottom",
  "editor.suggest.showSnippets": true,
  "editor.suggest.showKeywords": true,
  "editor.suggest.matchOnWordStartOnly": true,
  "editor.snippets.codeActions.enabled": false,
  "editor.suggest.snippetsPreventQuickSuggestions": false,
  "editor.suggest.preview": true,
  "editor.suggestOnTriggerCharacters": true,
  "editor.acceptSuggestionOnCommitCharacter": true,
  "editor.acceptSuggestionOnEnter": "on",
  "editor.suggest.localityBonus": true,
  "editor.parameterHints.enabled": true,
  "editor.wordBasedSuggestionsMode": "allDocuments",
  "elixirLS.dialyzerEnabled": true,
  "elixirLS.signatureAfterComplete": false,
  "elixirLS.fetchDeps": false,
  "elixirLS.trace.server": "off",
  "elixirLS.suggestSpecs": false,
  "[elixir]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "JakeBecker.elixir-ls"
  },
  "files.autoSave": "afterDelay",

  // MUST set this for OCaml development!
  "files.eol": "\n",
  "explorer.confirmDragAndDrop": false,
  "[python]": {
    "editor.formatOnType": true
  },
  // Set indent width in the explorer
  "workbench.tree.indent": 15,
  "Paket.autoInstall": true,
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "settingsSync.ignoredSettings": ["-window.zoomLevel"]
}
```