---
layout: post
title: Customize vscode keybinding
tags: ['windows', 'vscode', 'keybinding']
---

## Key binding example

`Ctrl+p` -> `keybindings.json`

```json
[
    {
        "key": "ctrl+y",
        "command": "redo",
        "when": "editorTextFocus"
    },
    {
        "key": "ctrl+right",
        "command": "workbench.action.terminal.focusNext",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+left",
        "command": "workbench.action.terminal.focusPrevious",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+down",
        "command": "workbench.action.terminal.focus",
        "when": "editorTextFocus"
    }
    
]
```
###### keybindings.json

위 코드는 제가 필요한 부분을 커스텀한 것입니다.

VSCode에서 에디터에서 터미널로 커서를 옮기기가 불편해서 `Ctrl+방향키`로 활성화 창을 옮깁니다.
되돌아오는 경우는 기본적으로 `Ctrl+1`로 기본 설정이 되어 있었습니다.

많은 단축키가 기본으로 설정되어 있으며 커스터마이즈 할 수 있습니다.
하단의 홈페이지들을 참고하시면 됩니다.

## Reference

- [GitHub vscode-tips-and-tricks](//github.com/Microsoft/vscode-tips-and-tricks?wt.mc_id=DX_881390#extension-recommendations)
- [Key Bindings for VSCode](//code.visualstudio.com/docs/getstarted/keybindings)
- [Integrated Terminal](//code.visualstudio.com/docs/editor/integrated-terminal)