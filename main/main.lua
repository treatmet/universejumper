local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()

local circles = {}
local numCircles = 15
local maxRadius = 120 -- Configurable maximum size for circles
local minExpansionRate = 3  -- Minimum expansion rate
local maxExpansionRate = 15 -- Maximum expansion rate
local redThreshold = 50
local redThreshold2 = 3
local circlePushForce = 0.1
local overlapAllow = 5
local allowGenerationInCurrentCircle = false

local numChildren = 1
local childSpeed = 150
local bottomGenThresh = 5
local upperGenThresh = 3000

local debugVal = 0

local timeScore = 0
local hightTimeScore = 0
local savedScore = 0
local highSavedScore = 0
local elapsedTime = 0
local circleEdgeForgiveness = 3
local spaceFont

-- Character properties
local character = {
  x = 0,
  y = 0,
  radius = 5,
  vx = 0,
  vy = 0,
  acceleration = 100 -- Configurable acceleration amount
}
local keysHeld = { up = false, down = false, left = false, right = false }
local charColor = {0.5, 1, 0.5}

-- Function to calculate the distance between two points
local function distance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy), dx, dy
end


-- Function to generate children inside a circle
local maxNumChildren = 25
local function generateChildren(circle)
  local children = {}
  nextId = 1
  for _, child in ipairs(circle.children) do
    if not child.collected then                    
      nextId = nextId + 1
      table.insert(children, { x = child.x, y = child.y, radius = 3, collected = false, id = nextId })
    end
  end
  
  doProduceChild = false
  if (math.random(0, upperGenThresh) <= bottomGenThresh + #children and #children < maxNumChildren) then
    doProduceChild = true
  end

  if doProduceChild == true then
      nextId = nextId + 1
      table.insert(children, { x = circle.x, y = circle.y, radius = 2, collected = false, id = nextId })
  end
  return children
end
local childrenColor = {1, 1, 0}

-- Function to generate stars inside a circle
local function generateStars(circle)
  local stars = {}
  for _ = 1, math.random(10, 20) do -- Random number of stars
      local angle = math.random() * 2 * math.pi
      local dist = math.random() * circle.radius
      local starX = circle.x + math.cos(angle) * dist
      local starY = circle.y + math.sin(angle) * dist
      local size = math.random(1, 2) -- Star size between 1-3 pixels
      local color = math.random() > 0.5 and {0.5, 0, 0.5} or {0, 0, 1} -- Purple or Blue
      table.insert(stars, {x = starX, y = starY, size = size, color = color})
  end
  return stars
end

-- Function to create a new circle at a random position
local circId = 0
local function createCircle()
  local x = math.random(50, screenWidth - 50)
  local y = math.random(50, screenHeight - 50)
  local initialExpansionRate = math.random() * (maxExpansionRate - minExpansionRate) + minExpansionRate
  local expansionRate = initialExpansionRate
  circId = circId + 1
  local circle = { 
      id = circId,
      x = x, 
      y = y, 
      radius = 10, 
      vx = 0, 
      vy = 0, 
      expansionRate = expansionRate, 
      initialExpansionRate = initialExpansionRate, 
      circlesTouching = 0,
      color = {1, 1, 1},
      children = {},
      stars = {} -- Add stars array
  }
  circle.children = {}
  circle.stars = generateStars(circle) -- Initialize stars
  return circle
end

-- Function to find the circle closest to the center
local function findClosestToCenter()
  local centerX, centerY = screenWidth / 2, screenHeight / 2
  local closestCircle, closestDistance = nil, math.huge
  for _, circle in ipairs(circles) do
      local dist = distance(centerX, centerY, circle.x, circle.y)
      if dist < closestDistance then
          closestDistance = dist
          closestCircle = circle
      end
  end
  return closestCircle
end

-- Reset the game state
local function resetGame()  
  timeScore = 0
  savedScore = 0
  circles = {}
  for i = 1, numCircles do
      table.insert(circles, createCircle())
  end
  local closestCircle = findClosestToCenter()
  character.x = closestCircle.x
  character.y = closestCircle.y
  character.vx, character.vy = 0, 0
  gameOver = 0
end

-- Initialize circles and character position
function love.load()
  spaceFont = love.graphics.newFont("space age.ttf", 20)
  math.randomseed(os.time())
  childImage = love.graphics.newImage("happy.png") 
  resetGame()
end

local gameOver = 0
local gamePaused = 0
-- Update circle sizes and apply physics
function love.update(dt)
  if gameOver == 1 then
    return -- Exit the function early
  end
    
    -- Increment elapsed time
    elapsedTime = elapsedTime + dt

    -- Update the time score every second
    local scoreRate = 0.5
    if elapsedTime >= scoreRate then
        timeScore = timeScore + 1
        if hightTimeScore <= timeScore then
          hightTimeScore = timeScore
        end
        elapsedTime = elapsedTime - scoreRate -- Reset elapsedTime while retaining fractional seconds
    end


    -- HANDLE CIRCLES 
    for i = #circles, 1, -1 do
        local c1 = circles[i]
        -- Expand the circle based on its unique expansion rate


        if (c1.circlesTouching > 0) then
          c1.expansionRate = c1.initialExpansionRate / (c1.circlesTouching + 1)
        end 
        c1.radius = c1.radius + c1.expansionRate * dt

        c1.circlesTouching = 0
        c1.expansionRate = c1.initialExpansionRate

        debugVal = (c1.radius - (maxRadius - redThreshold))

        local redVal = ((c1.radius - (maxRadius - redThreshold)) / redThreshold)
        if (redVal < 0) then
          redVal = 0
        end
        redVal = 1 - redVal
        c1.color = {1, redVal, redVal}

        c1.stars = generateStars(c1)

        local dist = distance(character.x, character.y, c1.x, c1.y)
        if dist > c1.radius + circleEdgeForgiveness and not allowGenerationInCurrentCircle then
          c1.children = generateChildren(c1)
        end

        -- Remove the circle if it exceeds the maximum radius
        if c1.radius >= maxRadius then
            table.remove(circles, i)
            table.insert(circles, createCircle()) -- Add a new circle
        else
            -- Check collisions with other circles and apply forces
            for _, c2 in ipairs(circles) do
                if c1 ~= c2 then
                    local dist, dx, dy = distance(c1.x, c1.y, c2.x, c2.y)
                    local overlap = (c1.radius + c2.radius - dist) - overlapAllow
                    if overlap > 0 then
                        c1.circlesTouching = c1.circlesTouching + 1
                        -- Push circles away with reduced force
                        local pushForce = overlap * circlePushForce
                        local pushX = (dx / dist) * pushForce
                        local pushY = (dy / dist) * pushForce
                        c1.vx = c1.vx - pushX
                        c1.vy = c1.vy - pushY
                        c2.vx = c2.vx + pushX
                        c2.vy = c2.vy + pushY
                    end
                end
            end

            -- Keep the circles inside the screen
            if c1.x - c1.radius < 0 then c1.vx = c1.vx + 10 * dt end
            if c1.x + c1.radius > screenWidth then c1.vx = c1.vx - 10 * dt end
            if c1.y - c1.radius < 0 then c1.vy = c1.vy + 10 * dt end
            if c1.y + c1.radius > screenHeight then c1.vy = c1.vy - 10 * dt end
        end
    end

    -- Apply velocity to positions and add damping to slow movement
    for _, c in ipairs(circles) do
        c.x = c.x + c.vx * dt
        c.y = c.y + c.vy * dt
        c.vx = c.vx * 0.95 -- Damping factor
        c.vy = c.vy * 0.95 -- Damping factor
    end

    -- Update character velocity based on held keys
  if keysHeld.up then
      character.vy = character.vy - character.acceleration * dt
  end
  if keysHeld.down then
      character.vy = character.vy + character.acceleration * dt
  end
  if keysHeld.left then
      character.vx = character.vx - character.acceleration * dt
  end
  if keysHeld.right then
      character.vx = character.vx + character.acceleration * dt
  end

  -- Update character position
  character.x = character.x + character.vx * dt
  character.y = character.y + character.vy * dt

    -- Check if the character is inside any circle and handle children collection
    local insideCircle = false
    for _, circle in ipairs(circles) do
        local dist = distance(character.x, character.y, circle.x, circle.y)
        if dist <= circle.radius + circleEdgeForgiveness then
            insideCircle = true

            -- Update children movement towards player
            for _, child in ipairs(circle.children) do
                if not child.collected then
                    local distToPlayer, dx, dy = distance(child.x, child.y, character.x, character.y)
                    if distToPlayer <= character.radius then
                        child.collected = true
                        savedScore = savedScore + 1
                    else
                        -- Move child towards player
                        local speed = childSpeed * dt
                        child.x = child.x + dx / distToPlayer * speed
                        child.y = child.y + dy / distToPlayer * speed
                    end
                end
            end
        else
          for _, child in ipairs(circle.children) do
            if not child.collected then                    
              local angle = (2 * math.pi / #circle.children) * child.id
              local dist = circle.radius * 0.5 -- Position children near the edge
              child.x= circle.x + math.cos(angle) * dist
              child.y = circle.y + math.sin(angle) * dist
            end
          end
        end         
    end

    -- Reset game if character is outside all circles
    if not insideCircle then
      gameOver = 1
    end
end --end update

-- Draw all circles timer1 tiemer1
local scaleFactor = 0.5
function love.draw()

      
      -- scoreboard
      if gameOver == 0 then
        love.graphics.setColor(1, 1, 1) -- White color
        love.graphics.setFont(love.graphics.newFont(15))
        if highSavedScore <= savedScore then 
          love.graphics.setColor(1, 1, 0) --yellow
          highSavedScore = savedScore 
        end 
        love.graphics.print("High Score: " .. highSavedScore, 5, 5)
        love.graphics.setColor(1, 1, 1) -- White color
        love.graphics.print("Saved: " .. savedScore, 5, 25)
       love.graphics.print("Time: " .. timeScore, 5, 45)
  
      end
      
 
      for _, circle in ipairs(circles) do

        -- Draw the stars
        for _, star in ipairs(circle.stars) do
          love.graphics.setColor(star.color)
          love.graphics.circle("fill", star.x, star.y, star.size)
        end

        -- Draw the circle
        love.graphics.setColor(circle.color)
        love.graphics.circle("line", circle.x, circle.y, circle.radius)
        if (circle.radius >= maxRadius - redThreshold2) then
          love.graphics.setColor(0.5,0,0)
          love.graphics.circle("fill", circle.x, circle.y, circle.radius)
        end


        -- Draw the children
        for _, child in ipairs(circle.children) do
          if not child.collected then
              love.graphics.setColor(childrenColor) -- Yellow
              love.graphics.circle("fill", child.x, child.y, child.radius)

--[[               local dist = distance(character.x, character.y, circle.x, circle.y) -- Happy emojis
              if dist <= circle.radius + circleEdgeForgiveness then
                love.graphics.setColor(1, 1, 1)
                local imageWidth = childImage:getWidth() * scaleFactor
                local imageHeight = childImage:getHeight() * scaleFactor
                local imageX = child.x - imageWidth / 2
                local imageY = child.y - child.radius - imageHeight - 5 -- Slight gap above
                love.graphics.draw(childImage, imageX, imageY, 0, scaleFactor, scaleFactor)
              end ]]
          end
      end
    end    
    -- Draw the character
    if gameOver == 0 then
      love.graphics.setColor(charColor) -- Green
    else 
      love.graphics.setColor(1, 0, 0) -- Red
    end
    love.graphics.circle("fill", character.x, character.y, character.radius)


    if gameOver == 1 then 
      --END GAME STATS
      love.graphics.setFont(spaceFont)
      local lines = {
        "GAME OVER",
        "",
        "Saved: " .. savedScore,
        "Saved High Score: " .. highSavedScore,
        "",
        "Time Survived: " .. timeScore,
        "Time High Score: " .. hightTimeScore
    }
      local font = love.graphics.getFont()
      local lineHeight = font:getHeight()
      local totalHeight = #lines * lineHeight
  
      -- Starting Y position to center vertically
      local startY = (screenHeight - totalHeight) / 2

            -- Calculate the dimensions of the background rectangle
      local padding = 20 -- Padding around the text
      local rectWidth = 400 -- Fixed width for the rectangle
      local rectHeight = totalHeight + padding * 2
      local rectX = (screenWidth - rectWidth) / 2
      local rectY = startY - padding

      -- Draw the semi-transparent black rectangle
      love.graphics.setColor(0, 0, 0, 0.2) -- 50% transparent black
      love.graphics.rectangle("fill", rectX, rectY, rectWidth, rectHeight)

      -- Reset color to white for text
      love.graphics.setColor(1, 1, 1, 1)
  
      -- Draw each line centered
      for i, line in ipairs(lines) do
          local textWidth = font:getWidth(line)
          local x = (screenWidth - textWidth) / 2
          local y = startY + (i - 1) * lineHeight
          love.graphics.print(line, x, y)
      end
    end

    love.graphics.setColor(1, 1, 1) -- Reset color
end

-- Handle key press and release events
function love.keypressed(key)
  if key == "up" or key == "w" then
      keysHeld.up = true
  elseif key == "down" or key == "s" then
      keysHeld.down = true
  elseif key == "left" or key == "a" then
      keysHeld.left = true
  elseif key == "right" or key == "d" then
      keysHeld.right = true
  elseif key == "space" or key == "escape" or key == "return" or key == "enter" then
    if gameOver == 1 then
      gameOver = 0
      resetGame()
    end
  end
end

function love.keyreleased(key)
  if key == "up" or key == "w" then
      keysHeld.up = false
  elseif key == "down" or key == "s" then
      keysHeld.down = false
  elseif key == "left" or key == "a" then
      keysHeld.left = false
  elseif key == "right" or key == "d" then
      keysHeld.right = false
  end
end
