a2sine
=====

[Open this project in 8bitworkshop](http://8bitworkshop.com/redir.html?platform=apple2&githubURL=https%3A%2F%2Fgithub.com%2Fmicahcowan%2Fa2sine&file=sine.s), and try it out!

This project is a library of 6502 assembly code (written in ca65) that provides an 8-bit signed trigonometric sine function.

It also provides a facility for managing sinusoidal animations, using an extremely crude (and currently completely undocumented) stack-based RPN expression language.

Both the library and the animation engine are written in portable 6502, though the demo program in `sine.s` is written specifically for the Apple II. The intention is to use this engine to create effects in [a2taki](https://github.com/micahcowan/a2taki), a WIP text-animation engine usable within AppleSoft BASIC.
