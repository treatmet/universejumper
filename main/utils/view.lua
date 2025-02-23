local view = {}


-- ╭ --------- ╮ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- | Variables | -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- ╰ --------- ╯ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local viewWidth = nil
local viewHeight = nil
local windowWidth = nil
local windowHeight = nil
local scale = nil
local offsetX = nil
local offsetY = nil


-- ╭ ------- ╮ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- | Private | -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- ╰ ------- ╯ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local function updateOffsets()
  scale = math.min(windowWidth / viewWidth, windowHeight / viewHeight)
  offsetX = (windowWidth - viewWidth * scale) / 2.0
  offsetY = (windowHeight - viewHeight * scale) / 2.0
end

local function updateWindow()
  local oldWidth = windowWidth
  local oldHeight = windowHeight
  windowWidth, windowHeight = love.graphics.getDimensions()
  if oldWidth ~= windowWidth or oldHeight ~= windowHeight then
    updateOffsets()
  end
end


-- ╭ ------ ╮ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- | Public | -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- ╰ ------ ╯ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function view.setDimensions(width, height)
  viewWidth = width
  viewHeight = height
  windowWidth, windowHeight = love.graphics.getDimensions()
  updateOffsets()
end

function view.getDimensions()
  return viewWidth, viewHeight
end

function view.getMousePosition()
  updateWindow()
  local mouseX, mouseY = love.mouse.getPosition()
  local x = (mouseX - offsetX) / scale
  local y = (mouseY - offsetY) / scale
  return x, y
end

function view.getMouseX()
  updateWindow()
  local mouseX = love.mouse.getX()
  local x = (mouseX - offsetX) / scale
  return x
end

function view.getMouseY()
  updateWindow()
  local mouseY = love.mouse.getY()
  local y = (mouseY - offsetY) / scale
  return y
end

-- Scale and center the coordinate system to adjust for different window sizes.
function view.origin()
  updateWindow()
  love.graphics.origin()
  if offsetX and offsetY then love.graphics.translate(offsetX, offsetY) end
  if scale then love.graphics.scale(scale) end
end

return view
