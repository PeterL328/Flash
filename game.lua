--Attack of the killer cubes

local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local utility = require( "utility" )
local myData = require( "mydata" )

-- 
-- define local variables here
--
local currentScore          -- used to hold the numeric value of the current score
local currentScoreDisplay   -- will be a display.newText() that draws the score on the screen
local levelText             -- will be a display.newText() to let you know what level you're on
local spawnTimer            -- will be used to hold the timer for the spawning engine
tileCount = 0
width = 2
length = 3
tiles = {}
level = 5
buttons = {}
edges = {} 

mirrorcount = 0

--
-- define local functions here
--
local function handleWin( event )
    --
    -- When you tap the "I Win" button, reset the "nextlevel" scene, then goto it.
    --
    -- Using a button to go to the nextlevel screen isn't realistic, but however you determine to 
    -- when the level was successfully beaten, the code below shows you how to call the gameover scene.
    --
    if event.phase == "ended" then
        composer.removeScene("nextlevel")
        composer.gotoScene("nextlevel", { time= 500, effect = "crossFade" })
    end
    return true
end

local function handleLoss( event )
    --
    -- When you tap the "I Loose" button, reset the "gameover" scene, then goto it.
    --
    -- Using a button to end the game isn't realistic, but however you determine to 
    -- end the game, the code below shows you how to call the gameover scene.
    --
    if event.phase == "ended" then
        composer.removeScene("gameover")
        composer.gotoScene("gameover", { time= 500, effect = "crossFade" })
    end
    return true
end

function generate(length, width)
	local x = 0
    local y = 0
    local count = 0
    for i = 1, (length * width) do
		local sizeX = (display.contentWidth * 0.80) / width
		local sizeY = (display.contentHeight * 0.80) / length
		local adjustmentFactorX = display.contentWidth / width
		local adjustmentFactorY = display.contentHeight / length
		
		if isMirror(i) == 1 then
			tiles[i] = display.newImageRect("mirror.png",sizeX,sizeY)
			tiles[i].X =  x + adjustmentFactorX
			tiles[i].Y = y + adjustmentFactorY
		elseif isMirror(i) == 2 then
			tiles[i] = display.newImageRect("mirror.png",sizeX,sizeY)
			tiles[i].X =  x + adjustmentFactorX
			tiles[i].Y = y + adjustmentFactorY			
		else
			tiles[i] = display.newImageRect("Tile.jpg",sizeX,sizeY)
			tiles[i].X =  x + adjustmentFactorX
			tiles[i].Y = y + adjustmentFactorY
			
		end
		
		tileCount = tileCount + 1
		tiles[i].strokeWidth = 1
		tiles[i]:setFillColor( 1, 1, 1 )
		tiles[i]:setStrokeColor( 0, 0, 0)
		
        x = x + sizeX
        count = count + 1
		
        if count == width then
            count = 0
            x = 0
            y = y + sizeY
        end



	end 
end

function setDimensions(level)
	if level % 5 == 0 then 
		factor = level / 5;
		width = width + factor
		length = length + factor
	end
end

function isMirror(gridCount)
	
	local minSpawn = math.ceil(level / 5) -- minSpawn is based on the level
	local maxSpawn = minSpawn * 4         -- maxSpwan based on minSpawn
	local r = math.random(1,3)			  -- random value to choose between 3 differnt types of tiles
	
	if  (gridCount >= math.floor(tileCount / 4) and mirrorcount < minSpawn and r == 3) then -- if game goes through first quarter of grid and mirrorcount is still less than minimum mirror spawn required then it must spawn a mirror
		r = math.random(1,2)	
	end
	-- 1 = orientation 1 --> \
	-- 2 = orientation 2 --> /
	-- 3 = no mirror     --> 
	if mirrorcount < maxSpawn then --only spawn mirrors if mirrorcount is less than maxSpawn  FOR FAIRNESS OF THE GAMe
		if r == 1 then
			mirrorcount = mirrorcount + 1
			return 1 
		end

		if r == 2 then
			mirrorcount = mirrorcount + 1
			return 2
		end
			
		if r == 3 then
			mirrorcount = mirrorcount + 1
			return 3
		end
	end
end

function scene:create( event )
    --
    -- self in this case is "scene", the scene object for this level. 
    -- Make a local copy of the scene's "view group" and call it "sceneGroup". 
    -- This is where you must insert everything (display.* objects only) that you want
    -- Composer to manage for you.
    local sceneGroup = self.view
	setDimensions(level)
	generate(width,length)
    local background = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor( 1, 1, 1 )
    --
    -- Insert it into the scene to be managed by Composer
    --
    sceneGroup:insert(background)

    --
    -- levelText is going to be accessed from the scene:show function. It cannot be local to
    -- scene:create(). This is why it was declared at the top of the module so it can be seen 
    -- everywhere in this module
    levelText = display.newText("Level" .. myData.settings.currentLevel , 0, 0, native.systemFontBold, 20 )
    levelText:setFillColor( 0 )
    levelText.x = 35
    levelText.y = 10
    --
    -- Insert it into the scene to be managed by Composer
    --
    sceneGroup:insert( levelText )

    -- 
    -- because we want to access this in multiple functions, we need to forward declare the variable and
    -- then create the object here in scene:create()
    --
    currentScoreDisplay = display.newText("000000", display.contentWidth - 50, 10, native.systemFont, 16 )
    sceneGroup:insert( currentScoreDisplay )

    --
    -- these two buttons exist as a quick way to let you test
    -- going between scenes (as well as demo widget.newButton)
end

--
-- This gets called twice, once before the scene is moved on screen and again once
-- afterwards as a result of calling composer.gotoScene()
--
function scene:show( event )
    --
    -- Make a local reference to the scene's view for scene:show()
    --
    local sceneGroup = self.view
    currentScore = 0
    currentScoreDisplay.text = string.format( "%06d", currentScore )

end

--
-- This function gets called everytime you call composer.gotoScene() from this module.
-- It will get called twice, once before we transition the scene off screen and once again 
-- after the scene is off screen.
function scene:hide( event )
    local sceneGroup = self.view
    
    if event.phase == "will" then
        -- The "will" phase happens before the scene is transitioned off screen. Stop
        -- anything you started elsewhere that could still be moving or triggering such as:
        -- Remove enterFrame listeners here
        -- stop timers, phsics, any audio playing
    end

end

--
-- When you call composer.removeScene() from another module, composer will go through and
-- remove anything created with display.* and inserted into the scene's view group for you. In
-- many cases that's sufficent to remove your scene. 
--
-- But there may be somethings you loaded, like audio in scene:create() that won't be disposed for
-- you. This is where you dispose of those things.
-- In most cases there won't be much to do here.
function scene:destroy( event )
    local sceneGroup = self.view
    
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
return scene