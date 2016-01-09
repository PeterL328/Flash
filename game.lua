--Attack of the killer cubes

local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local utility = require( "utility" )
local myData = require( "mydata" )


-- Set up physics engine
local physics = require("physics")
physics.start()
physics.setGravity( 0,0 )
physics.setDrawMode( "normal" )
-- 

-- define local variables here
--
local currentScore          -- used to hold the numeric value of the current score
local currentScoreDisplay   -- will be a display.newText() that draws the score on the screen
local levelText             -- will be a display.newText() to let you know what level you're on
local spawnTimer            -- will be used to hold the timer for the spawning engine


screenWidth = display.contentWidth;
screenHeight = display.contentHeight;
tileCount = 0
width = 2
length = 3
local tiles = {}
local buttons = {}
local level = 5
mirrorcount = 0

local beamGroup = display.newGroup() -- group for laser objects
local maxBeams = 50  
--mirror = display.newImageRect( "mirror.png", 20, 100 )

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
local function spawnTile( sizeX, sizeY, xPos, yPos, tileType)
	if tileType  == "tile" then
		local tile = display.newImageRect( "Tile.png", sizeX, sizeY )
		tile.x = xPos
		tile.y = yPos
	elseif  tileType  == "left" then
		local tile = display.newImageRect( "left.png", sizeX, sizeY )
		tile.x = xPos
		tile.y = yPos
	elseif  tileType  == "right" then
		local tile = display.newImageRect( "right.png", sizeX, sizeY )
		tile.x = xPos
		tile.y = yPos
	end
	return tile
end
function generate(length, width)
	local sizeX = (screenWidth * 0.6) / width
	local sizeY = (screenHeight * 0.6) / length
	local startX = display.contentCenterX - (width * sizeX)/2 + sizeX/2
	local startY = display.contentCenterY - (length * sizeY)/2 + sizeY/2
	for i = 1, width do
		for j = 1, length do
			r = math.random(1,3)
			if r == 1 then
				tiles[mirrorcount]=spawnTile(sizeX, sizeY, startX + (i-1) * sizeX,  startY + (j-1) * sizeY, "tile")
			elseif r == 2 then
				tiles[mirrorcount]=spawnTile(sizeX, sizeY, startX + (i-1) * sizeX,  startY + (j-1) * sizeY, "left")
			elseif r == 3 then
				tiles[mirrorcount]=spawnTile(sizeX, sizeY, startX + (i-1) * sizeX,  startY + (j-1) * sizeY, "right")
			end
			mirrorcount = mirrorcount + 1
		end
	end
	spawnButtons(startX,startY, length,width,(sizeX + sizeY) * 0.12)
end
function spawnButtons(startX, startY, length, width, radius)
	local sizeX = (screenWidth * 0.6) / width
	local sizeY = (screenHeight * 0.6) / length
	local x = 0
	local y = 0
	local count = 0
	for i = 0, width-1 do
		x = startX + (i) * sizeX
		y = startY - sizeY
		buttons[count] = display.newCircle( x, y, radius)
		count = count + 1
	end
	x = x + sizeX 
	for i = 0, length-1 do
		y = startY + ((i) * sizeY)
		buttons[count] = display.newCircle( x, y, radius)
		count = count + 1
	end
	y = y + sizeY
	startX = x - sizeX
	for i = 0, width-1 do
		x = startX - (i) * sizeX
		buttons[count] = display.newCircle( x, y, radius)
		count = count + 1
	end
	x = x - sizeX
	startY = y - sizeY
	for i = 0, length-1 do
		y = startY - (i) * sizeY
		buttons[count] = display.newCircle( x, y, radius)
		count = count + 1
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

----------------------
-- BEGIN laser code
----------------------

local function clearObject( object )
    display.remove( object )
    object = nil
end


local function resetBeams()

    -- Clear all beams/bursts from display
    for i = beamGroup.numChildren,1,-1 do
        local child = beamGroup[i]
        display.remove( child )
        child = nil
    end

    -- Reset beam group alpha
    beamGroup.alpha = 1

end

local function drawBeam( startX, startY, endX, endY )

    -- Draw a series of overlapping lines to represent the beam
    local beam1 = display.newLine( beamGroup, startX, startY, endX, endY )
    beam1.strokeWidth = 2 ; beam1:setStrokeColor( 1, 0.312, 0.157, 1 ) ; beam1.blendMode = "add" ; beam1:toBack()
    local beam2 = display.newLine( beamGroup, startX, startY, endX, endY )
    beam2.strokeWidth = 4 ; beam2:setStrokeColor( 1, 0.312, 0.157, 0.706 ) ; beam2.blendMode = "add" ; beam2:toBack()
    local beam3 = display.newLine( beamGroup, startX, startY, endX, endY )
    beam3.strokeWidth = 6 ; beam3:setStrokeColor( 1, 0.196, 0.157, 0.392 ) ; beam3.blendMode = "add" ; beam3:toBack()
end

local function castRay( startX, startY, endX, endY )

    -- Perform ray cast
    local hits = physics.rayCast( startX, startY, endX, endY, "closest" ) 
    -- Return only the closest hit from the starting point, if any. 
    -- There is a hit; calculate the entire ray sequence (initial ray and reflections)
    if ( hits and beamGroup.numChildren <= maxBeams ) then

        -- Store first hit to variable (just the "closest" hit was requested, so use 'hits[1]')
        local hitFirst = hits[1]

        -- Store the hit X and Y position to local variables
        local hitX, hitY = hitFirst.position.x, hitFirst.position.y

        -- Place a visual "burst" at the hit point and animate it
        local burst = display.newImageRect( beamGroup, "burst.png", 64, 64 )
        burst.x, burst.y = hitX, hitY
        burst.blendMode = "add"
        transition.to( burst, { time=1000, rotation=45, alpha=0, transition=easing.outQuad, onComplete=clearObject } )

        -- Draw the next beam
        drawBeam( startX, startY, hitX, hitY )

        -- Check for and calculate the reflected ray
        local reflectX, reflectY = physics.reflectRay( startX, startY, hitFirst )
        local reflectLen = 1600
        local reflectEndX = ( hitX + ( reflectX * reflectLen ) )
        local reflectEndY = ( hitY + ( reflectY * reflectLen ) )

        -- If the ray is reflected, cast another ray
        if ( reflectX and reflectY) then
            timer.performWithDelay( 40, function() castRay( hitX, hitY, reflectEndX, reflectEndY ); end )
        end

    -- Else, ray casting sequence is complete
    else

        -- Draw the final beam
        drawBeam( startX, startY, endX, endY )

        -- Fade out entire beam group after a short delay
        transition.to( beamGroup, { time=800, delay=400, alpha=0, onComplete=resetBeams } )
    end
end


local function fireOnTimer( event )

    -- Ensure that all previous beams/bursts are cleared/complete before firing
    if beamGroup.numChildren == 0 then

        -- Stop rotating turret as it fires
        turret.angularVelocity = 0

        -- Play laser sound
        audio.play( sndLaserHandle )

        -- Calculate ending x/y of beam
        local xDest = turret.x - (math.cos(math.rad(turret.rotation+90)) * 1600 )
        local yDest = turret.y - (math.sin(math.rad(turret.rotation+90)) * 1600 )

        -- Cast the initial ray
        castRay( turret.x, turret.y, xDest, yDest )
    end
end

----------------------
-- END laser code
----------------------

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
    background:setFillColor( 1, 0, 1 )
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
    
    
    --physics.addBody( mirror, "static", { shape={-9,-49,9,-49,9,49,-9,49} } )
   -- mirror.x = display.contentCenterX
    --mirror.y = display.contentCenterY
   -- sceneGroup:insert( mirror)
   -- castRay(0,0,1100,700 )
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