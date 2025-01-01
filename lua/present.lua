local M = {}

local function create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or vim.o.columns
  local height = opts.height or vim.o.lines

  -- make it center
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- create a buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- window configuration
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = { " ", " ", " ", " ", " ", " ", " ", " " },
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

M.setup = function()
  -- do nothing
end

---@class present.Slides
---@fields slides string[]: The slides after praseing the file

--- Pars markdown lines
---@param lines string[]; The lines in the buffer
---@return present.Slides
local prase_slides = function(lines)
  local sls = { slides = {} }

  local current_slide = {}

  local separator = "^#"
  for _, line in ipairs(lines) do
    print(line, "find: ", line:find(separator), "|")

    if line:find(separator) then
      if #current_slide > 0 then
        table.insert(sls.slides, current_slide)
      end
      current_slide = {}
    end

    table.insert(current_slide, line)
  end

  table.insert(sls.slides, current_slide)

  return sls
end

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed = prase_slides(lines)
  local float = create_floating_window()

  local current_slide = 1
  vim.keymap.set("n", "n", function()
    current_slide = math.min(current_slide + 1, #parsed.slides)
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[current_slide])
  end, { buffer = float.buf })

  vim.keymap.set("n", "p", function()
    current_slide = math.max(current_slide - 1, 1)
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[current_slide])
  end, { buffer = float.buf })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(float.win, true)
  end, { buffer = float.buf })

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
    buffer = float.buf,
    callback = function()
      for option, config in pairs(restore) do
        vim.opt[option] = config.original
      end
    end,
  })

  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[1])
end

-- M.start_presentation({ bufnr = 71 })

return M
