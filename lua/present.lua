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

--- Parse markdown lines
---@param lines string[]; The lines in the buffer
---@return present.Slides
local parse_slides = function(lines)
  local sls = { slides = {} }

  local current_slide = nil

  local pattern = "^#"
  for _, line in ipairs(lines) do
    if line:find(pattern) then
      -- when find a new slide title, add current slide to sls.slides
      if current_slide then
        table.insert(sls.slides, current_slide)
      end
      -- and create a new one
      current_slide = { title = line, body = {} }
    elseif current_slide then
      table.insert(current_slide.body, line)
    end
  end

  -- add the last slide to sls.slides
  table.insert(sls.slides, current_slide)

  return sls
end

local create_window_configuration = function()
  local width = vim.o.columns
  local height = vim.o.lines

  return {
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
end

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed = parse_slides(lines)
  local current_slide = 1

  local windows = create_window_configuration()

  local background_float = create_floating_window(windows.background)
  local header_float = create_floating_window(windows.header)
  local body_float = create_floating_window(windows.body)

  vim.bo[header_float.buf].filetype = "markdown"
  vim.bo[body_float.buf].filetype = "markdown"

  local set_slide_content = function(idx)
    local width = vim.o.columns
    local slide = parsed.slides[idx]

    local padding = string.rep(" ", (width - #slide.title) / 2)
    -- redefine the title with padding
    local title = padding .. slide.title
    vim.api.nvim_buf_set_lines(header_float.buf, 0, -1, false, { title })
    vim.api.nvim_buf_set_lines(body_float.buf, 0, -1, false, slide.body)
  end

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

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if
        not (
          vim.api.nvim_win_is_valid(background_float.win)
          and vim.api.nvim_win_is_valid(header_float.win)
          and vim.api.nvim_win_is_valid(body_float.win)
        )
      then
        return
      end

      local updated = create_window_configuration()
      vim.api.nvim_win_set_config(header_float.win, updated.header)
      vim.api.nvim_win_set_config(body_float.win, updated.body)
      vim.api.nvim_win_set_config(background_float.win, updated.background)

      -- re-calculate the slide content
      set_slide_content(current_slide)
    end,
  })
end

M.start_presentation({ bufnr = 39 })

return M
