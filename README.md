# present.nvim

> [!WARNING]
>
> WIP

[](https://github.com) A markdown presentation for Neovim

![image](https://github.com/user-attachments/assets/1f0c1fc9-4a8b-4153-affc-3a4e6f0ae52b)

# Feature

- Beautiful markdown support
- Execute simple code block in current slide
- Support lua, python by default

## Execute lua

Type `X` to execute the lua code

```lua
print("Hello World!")
```

## Even python

Type `X` to execute python code

```python
# this is a python comment
name = "Bob"
print(f"Hello {name}")
```

# Usage

For lazy.nvim

```lua
return {
    "buidai123/present.nvim",
    config = function()
    end
}
```

Run `PresentStart` to start presentation

Use `n` and `p` to navigate around slides

`q` for quite the presentation

# Credits

Teej_dv
