---
layout: post
title: Customize vscode keybinding
tags: ['windows', 'vscode', 'python', 'keybinding', 'virtualenv']
---

## Key binding example

| `Ctrl+p` -> `keybindings.json` |

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
        "when": "!terminalFocus"
    }
    
]
```
###### keybindings.json

위 코드는 제가 필요한 부분을 커스텀한 것입니다.

VSCode에서 에디터에서 터미널로 커서를 옮기기가 불편해서 `Ctrl+방향키`로 활성화 창을 옮깁니다.
되돌아오는 경우는 기본적으로 `Ctrl+1`로 기본 설정이 되어 있었습니다.

많은 단축키가 기본으로 설정되어 있으며 커스터마이즈 할 수 있습니다.
하단의 홈페이지들을 참고하시면 됩니다.

## Python Interpreter Setting

- Marketplace에서 Python 설치 [pythonVSCode](//github.com/DonJayamanne/pythonVSCode/wiki)

| `Ctrl+p` -> `settings.json` |

```json
{
    "python.pythonPath": "%WORKDIR%/test/_tf/Scripts/python.exe"
}
```
###### settings.json

위는 기본 설정된 Python 외에 virtualenv를 설정할 경우의 경로를 인식합니다.
이렇게 설정하여 코드 자동완성을 따라갈 수 있습니다.

## Reference

- [GitHub vscode-tips-and-tricks](//github.com/Microsoft/vscode-tips-and-tricks?wt.mc_id=DX_881390#extension-recommendations)
- [Key Bindings for VSCode](//code.visualstudio.com/docs/getstarted/keybindings)
- [Integrated Terminal](//code.visualstudio.com/docs/editor/integrated-terminal)
- [Select Python Interpreter](//github.com/DonJayamanne/pythonVSCode/wiki/Miscellaneous#select-an-interpreter)
- [Virtual Environments](//github.com/DonJayamanne/pythonVSCode/wiki/Python-Path-and-Version#virtual-environments)