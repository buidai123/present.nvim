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
          },
        },
      },
      parse({
        "# This is the first slide",
        "this is the body",
      })
    )
  end)
end)
