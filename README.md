# present.nvim

This is a markdown presentation for Neovim

# Feature

Can execute the codeblocks in current slide

## Execute lua

type `X` to execute the blow code

```lua
print("Hello World!")
```

## Even python

Same for python

```python
name = "Bob"
print(f"Hello {name}")
```

# Usage

for lazy.nvim

```lua
return {
    "buidai123/present",
    config = function()
        require("present")
    end
}
```

use `n` and `p` to navigate around slides

`q` for quite the presentation

# Credits

Teej_dv
