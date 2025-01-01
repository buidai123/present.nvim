local M = {}

local function create_floating_window(config)
  -- create a buffer
  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, config)

  return { buf = buf, win = win }
end

M.setup = function()
  -- do nothing
end

---@class present.Slides
---@field slides present.Slide[]: The slides after praseing the file

---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The body of slide

--- Pars markdown lines
---@param lines string[]; The lines in the buffer
---@return present.Slides
local parse_slides = function(lines)
  local sls = { slides = {} }

  local current_slide = {
    title = "",
    body = {},
  }

  local separator = "^#"
  for _, line in ipairs(lines) do
    if line:find(separator) then
      if #current_slide.title > 0 then
        table.insert(sls.slides, current_slide)
      end
      current_slide = {
        title = line,
        body = {},
      }
    else
      table.insert(current_slide.body, line)
    end
  end

  table.insert(sls.slides, current_slide)

  return sls
end

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed = parse_slides(lines)

  local width = vim.o.columns
  local height = vim.o.lines

  ---@type vim.api.keyset.win_config
  local window = {
    background = {
      relative = "editor",
      width = width,
      height = height,
      col = 0,
      row = 0,
      style = "minimal",
      zindex = 1,
    },
    header = {
      relative = "editor",
      width = width,
      height = 1,
      border = "rounded",
      col = 0,
      row = 0,
      style = "minimal",
      zindex = 100,
    },
    body = {
      relative = "editor",
      width = width - 8,
      height = height - 5,
      style = "minimal",
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      row = 4,
      col = 8,
    },
  }

  local background_float = create_floating_window(window.background)
  local header_float = create_floating_window(window.header)
  local body_float = create_floating_window(window.body)

  vim.bo[header_float.buf].filetype = "markdown"
  vim.bo[body_float.buf].filetype = "markdown"

  local set_slide_content = function(idx)
    local slide = parsed.slides[idx]

    local padding = string.rep(" ", (width - #slide.title) / 2)
    -- redefine the title with padding
    local title = padding .. slide.title
    vim.api.nvim_buf_set_lines(header_float.buf, 0, -1, false, { title })
    vim.api.nvim_buf_set_lines(body_float.buf, 0, -1, false, slide.body)
  end

  local current_slide = 1
  vim.keymap.set("n", "n", function()
    current_slide = math.min(current_slide + 1, #parsed.slides)
    set_slide_content(current_slide)
  end, { buffer = body_float.buf })

  vim.keymap.set("n", "p", function()
    current_slide = math.max(current_slide - 1, 1)
    set_slide_content(current_slide)
  end, { buffer = body_float.buf })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(body_float.win, true)
  end, { buffer = body_float.buf })

  local restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      present = 0,
    },
  }

  -- set the option when the presentation load
  for option, config in pairs(restore) do
    vim.opt[option] = config.present
  end

  -- autocommand to restore original option on leave
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = body_float.buf,
    callback = function()
      for option, config in pairs(restore) do
        vim.opt[option] = config.original
      end

      pcall(vim.api.nvim_win_close, background_float.win, true)
      pcall(vim.api.nvim_win_close, header_float.win, true)
    end,
  })

  set_slide_content(current_slide)
end

M.start_presentation({ bufnr = 47 })

return M
