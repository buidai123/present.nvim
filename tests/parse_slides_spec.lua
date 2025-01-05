local parse = require("present")._parse_slides
local eq = assert.are.same

describe("present.parse_slides", function()
  it("should parse an emtpty file", function()
    eq({
      slides = {},
    }, parse({}))
  end)

  it("should parse a file with one slide", function()
    eq(
      {
        slides = {
          {
            title = "# This is the first slide",
            body = { "this is the body" },
            blocks = {},
          },
        },
      },
      parse({
        "# This is the first slide",
        "this is the body",
      })
    )
  end)
  it("should parse a file with one slide having codeblocks", function()
    local results = parse({
      "# This is the first slide",
      "this is the body",
      "```lua",
      "print('Hello World!')",
      "```",
      " ",
      "```python",
      "name = 'Bob'",
      "print(f'Hello World! {name}')",
      "```",
    })

    eq(1, #results.slides)
    local slide = results.slides[1]

    eq("# This is the first slide", slide.title)

    eq({
      "this is the body",
      "```lua",
      "print('Hello World!')",
      "```",
      " ",
      "```python",
      "name = 'Bob'",
      "print(f'Hello World! {name}')",
      "```",
    }, slide.body)

    local blocks = {
      {
        language = "lua",
        body = vim.trim([[
print('Hello World!')
        ]]),
      },
      {
        language = "python",
        body = vim.trim([[
name = 'Bob'
print(f'Hello World! {name}')
        ]]),
      },
    }

    eq(blocks, slide.blocks)
  end)
end)
