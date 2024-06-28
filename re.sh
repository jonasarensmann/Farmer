#!/bin/bash
rm $HOME/.local/bin/farmer
rm bundle.luau
lune run src/main bundle bundle.luau
lune build bundle.luau -o farmer
mv farmer $HOME/.local/bin