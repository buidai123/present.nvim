local M = {}

local function create_floating_window(config, enter)
  if enter == nil then
    enter = false
  end
  -- create a buffer
  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, enter or false, config)

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

  local header_height = 1 + 2 -- its height + borders
  local footer_height = 1 + 1 -- its height + the uper border
  local body_height = height - header_height - footer_height

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
      -- height = height - 5,
      height = body_height,
      style = "minimal",
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      row = 4,
      col = 8,
    },
    footer = {
      relative = "editor",
      width = width,
      height = 1,
      -- TODO: make it only uper border
      -- border = "rounded",
      col = 0,
      row = height - 1, -- the last row
      style = "minimal",
      zindex = 100,
    },
  }
end

local state = {
  parsed = {},
  current_slide = 1,
  floats = {},
}

local foreach_float = function(cb)
  for name, float in pairs(state.floats) do
    cb(name, float)
  end
end

local present_keymap = function(mode, key, callback)
  vim.keymap.set(mode, key, callback, {
    buffer = state.floats.body.buf,
  })
end

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  state.parsed = parse_slides(lines)
  state.current_slide = 1
  state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  local windows = create_window_configuration()

  state.floats.background = create_floating_window(windows.background)
  state.floats.header = create_floating_window(windows.header)
  state.floats.body = create_floating_window(windows.body, true)
  state.floats.footer = create_floating_window(windows.footer)

  foreach_float(function(_, float)
    vim.bo[float.buf].filetype = "markdown"
  end)

  local set_slide_content = function(idx)
    local width = vim.o.columns
    local slide = state.parsed.slides[idx]

    local padding = string.rep(" ", (width - #slide.title) / 2)
    -- redefine the title with padding
    local title = padding .. slide.title
    vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })
    vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)

    local footer = string.format(" %d / %d | %s", state.current_slide, #state.parsed.slides, state.title)
    vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
  end

  present_keymap("n", "n", function()
    state.current_slide = math.min(state.current_slide + 1, #state.parsed.slides)
    set_slide_content(state.current_slide)
  end)

  present_keymap("n", "p", function()
    state.current_slide = math.max(state.current_slide - 1, 1)
    set_slide_content(state.current_slide)
  end)

  present_keymap("n", "q", function()
    vim.api.nvim_win_close(state.floats.body.win, true)
  end)

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
    buffer = state.floats.body.buf,
    callback = function()
      for option, config in pairs(restore) do
        vim.opt[option] = config.original
      end

      foreach_float(function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
      end)
    end,
  })

  set_slide_content(state.current_slide)

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if
        not (
          vim.api.nvim_win_is_valid(state.floats.background.win)
          and vim.api.nvim_win_is_valid(state.floats.header.win)
          and vim.api.nvim_win_is_valid(state.floats.body.win)
          and vim.api.nvim_win_is_valid(state.floats.footer.win)
        )
      then
        return
      end

      local updated = create_window_configuration()

      foreach_float(function(name, float)
        local config_name = name:gsub("_float", "")
        vim.api.nvim_win_set_config(float.win, updated[config_name])
      end)

      -- re-calculate the slide content
      set_slide_content(state.current_slide)
    end,
  })
end

-- M.start_presentation({ bufnr = 291 })

M._parse_slides = parse_slides

return M
