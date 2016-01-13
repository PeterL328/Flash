--=======================================================================================================
-- Project: Flash V1.0
-- Description: A IOS, Android puzzle game 
--               
-- Corona SDK v2015.2799
-- Date: Jan 9, 2015
--
-- Programmer: Peter Leng, Dylan Park, Josh Koza, Dane 
-- ======================================================================================================

-- Include required libraries
local composer = require( "composer" ) -- for scenes
local widget = require( "widget" ) -- buttons 
local json = require( "json" ) 
local utility = require( "utility" )
local myData = require( "mydata" )
local physics = require( "physics" )

-- Setting up the scene
local scene = composer.newScene()

-- Set up physics engine
physics.start() 
physics.setGravity( 0,0 ) -- gravity set to 0,0 since we do not need it
physics.setDrawMode( "normal" )

-- define local variables here 
local currentScore          -- used to hold the numeric value of the current score
local currentScoreDisplay   -- will be a display.newText() that draws the score on the screen
local levelText             -- will be a display.newText() to let you know what level you're on
local spawnTimer            -- will be used to hold the timer for the spawning engine
local tileCount = 0
local width = 2
local length = 3
local tiles = {}
local level = 20
local buttons = {}
local mirrors = {}
local mirrorcount = 0
local tilecount = 0 
local screenWidth = display.contentWidth;
local screenHeight = display.contentHeight;

local circleGroup = display.newGroup()
local tileGroup = display.newGroup()
local mirrorGroup = display.newGroup() 
local beamGroup = display.newGroup() -- group for laser objects
local maxBeams = 50  -- maximun beam count
local laserDirection -- in degrees eg. 0, 90, 180, -90


----------------
-- BEGIN Mirror   
----------------

local function isMirror(gridCount)
	
	local minSpawn = math.ceil(level / 5) -- minSpawn is based on the level
	local maxSpawn = minSpawn * 4         -- maxSpwan based on minSpawn
	local r = math.random(1,5)			  -- random value to choose between 3 differnt types of tiles
	
	if  (gridCount >= math.floor(tileCount / 4) and mirrorcount < minSpawn and r == 1) then -- if game goes through first quarter of grid and mirrorcount is still less than minimum mirror spawn required then it must spawn a mirror
		r = math.random(1,2)	
	end
	-- 1 = orientation 1 --> \
	-- 2 = orientation 2 --> /
	-- >=3 = no mirror     --> 
	if mirrorcount < maxSpawn then --only spawn mirrors if mirrorcount is less than maxSpawn  FOR FAIRNESS OF THE GAMe
		if r == 1 then
			mirrorcount = mirrorcount + 1
			return r 
		end

		if r == 2 then
			mirrorcount = mirrorcount + 1
			return r
		end

		if r >= 3 then
			return r
		end
	
	elseif mirrorcount >= maxSpawn then
			r = math.random(3,5)
			return r
	end
end
----------------
-- END Mirror   
----------------

------------------------
-- BEGIN Grid generation  
------------------------

local function spawnTile( sizeX, sizeY, xPos, yPos, tileType)
	if tileType  == "tile" then
		local tile = display.newImageRect( "Tile.png", sizeX, sizeY )
        tileGroup:insert(tile)
		tile.x = xPos
		tile.y = yPos
    end
	return tile
end
local function spawnButtons(startX, startY, length, width, radius,spacing)
    local x = 0
    local y = 0
    local count = 0
    for i = 0, length-1 do
        x = startX + (i) * spacing
        y = startY - spacing
        buttons[count] = display.newCircle( x, y, radius)
        circleGroup:insert(buttons[count])
        count = count + 1
    end
    x = x + spacing 
    for i = 0, width-1 do
        y = startY + ((i) * spacing)
        buttons[count] = display.newCircle( x, y, radius)
        circleGroup:insert(buttons[count])
        count = count + 1
    end
    y = y + spacing
    startX = x - spacing
    for i = 0, length - 1 do
        x = startX - (i) * spacing
        buttons[count] = display.newCircle( x, y, radius)
        circleGroup:insert(buttons[count])
        count = count + 1
    end
    x = x - spacing
    startY = y - spacing
    for i = 0, width - 1 do
        y = startY - (i) * spacing
        buttons[count] = display.newCircle( x, y, radius)
        circleGroup:insert(buttons[count])
        count = count + 1
    end
end
local function generate(length, width)
	local sizeX = (screenWidth * 0.8) / length
	local sizeY = sizeX
	local startX = display.contentCenterX - (length * sizeX)/2 + sizeX/2
	local startY = display.contentCenterY - (width * sizeY)/2 + sizeY/2
	for i = 1, length do
		for j = 1, width do
			tiles[tilecount]=spawnTile(sizeX, sizeY, startX + (i-1) * sizeX,  startY + (j-1) * sizeY, "tile")
			tilecount = tilecount + 1
		end
	end
	for i = 1, length do
		for j = 1, width do
			local check = isMirror(i*j)
			if check == 2 then
				local mirror = display.newImageRect( "left.png", sizeX, sizeY )
                mirrorGroup:insert(mirror)
				mirror.x = startX + (i-1) * sizeX
				mirror.y =  startY + (j-1) * sizeY
				physics.addBody( mirror, "static", {shape = {sizeX* 0.8, 0, sizeY, sizeX*0.2, sizeX*0.2, sizeY, 0, sizeY*0.8} })
			elseif check == 3 then
				local mirror = display.newImageRect( "right.png", sizeX, sizeY )
                mirrorGroup:insert(mirror)
				mirror.x = startX + (i-1) * sizeX
				mirror.y =  startY + (j-1) * sizeY
				physics.addBody( mirror, "static", {shape = {sizeX*0.2, 0, sizeX, sizeY*0.8, sizeX*0.8, sizeY, 0, sizeY*0.2} })
			end
		end
	end
	spawnButtons(startX,startY, length,width, sizeX * 0.2,sizeX)
end

local function setDimensions(level)
	if level % 5 == 0 then 
		factor = level / 5;
		width = width + factor
		length = length + factor
	end
end

------------------------
-- END Grid generation  
------------------------


----------------------
-- BEGIN laser code
----------------------

-- for the burst effect when laser hits
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

-- Perform ray cast
local function castRay( startX, startY, endX, endY )
    -- hits array contains all hit locations
    local hits = physics.rayCast( startX, startY, endX, endY, "sorted" ) 
    -- "sorted" — Return all results, sorted from closest to farthest.
    -- objects hit can be accessed by the following: hits[i].object 
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
        -- This may be an overkill since all of the mirrors will just be at 45 degree. But future updates may need it
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

local function laserStartingPosition()
    local maxPos = width*2 + length*2 
    -- number of possible starting positions is based on the generated grid
    -- we will count from the top left corner to the right and so on.
    local startPos = math.random(0, maxPos-1) 
    local startx = buttons[startPos].x
    local starty = buttons[startPos].y
    local sizeX = (screenWidth * 0.8) / width
    local sizeY = sizeX

    -- First case: The random is at the top 
    if (startPos >= 0 and startPos < width) then
        laserDirection = -90
        -- Shot the laser from the top circle to the bottom circle
        castRay(startx, starty, startx , starty + ((length+1)*sizeY))
    -- Second case: The random is at the right
    elseif (startPos >= width and startPos < (width + length)) then
        laserDirection = 180
        -- Shot the laser from the right circle to the left circle
        castRay(startx, starty, startx - ((width+1)*sizeX) , starty)
    -- Third case: The random is at the bottom
    elseif (startPos >= (width + length) and (startPos < (width*2) + length)) then
        laserDirection = 90
        -- Shot the laser from the bottom circle to the top circle
        castRay(startx, starty, startx , starty - ((length+1)*sizeY))
    -- Fourth case: The random is at the left
    elseif (startPos >= width*2 + length and startPos < maxPos) then
        laserDirection = 0
        -- Shot the laser from the left circle to the right circle
        castRay(startx, starty, startx + ((width+1)*sizeX) , starty)
    end
end

----------------------
-- END laser code
----------------------

local function gameStart()
    --1) generate level based on difficulty
    setDimensions(level)
    generate(width,length)
    --2) spawn mirror
    --3) spawn laser
    laserStartingPosition()
    --4) test if the number of mirrors hit corresponds the current difficulty
    --5) if 4) fails go back to 2)
    --6) if 4) works show mirror for 3-4 seconds
    --7) make mirror disappear
    --8) wait for user's tap respond
    --9) If correct: difficulty + 1, score goes up, repeat step 1. If wrong: difficulty - 1: repeat step 1
    --10) ...
end


function scene:create( event )
    -- self in this case is "scene", the scene object for this level. 
    -- Make a local copy of the scene's "view group" and call it "sceneGroup". 
    -- This is where you must insert everything (display.* objects only) that you want






    -- Composer to manage for you.
    local sceneGroup = self.view
    local background = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)


    background:setFillColor(0,0,0)

    --
    -- Insert it into the scene to be managed by Composer
    --

    --
    -- levelText is going to be accessed from the scene:show function. It cannot be local to
    -- scene:create(). This is why it was declared at the top of the module so it can be seen 
    -- everywhere in this module
    levelText = display.newText("Level " .. level , 0, 0, native.systemFontBold, 20 )
    levelText:setFillColor( 0 )
    levelText.x = 35
    levelText.y = 10

    currentScoreDisplay = display.newText("000000", display.contentWidth - 50, 10, native.systemFont, 16 )
    --
    -- these two buttons exist as a quick way to let you test
    -- going between scenes (as well as demo widget.newButton)
    
    -- insert into group (the order does matter, whatever is inserted first will be at the bottom)
    sceneGroup:insert(background)
    sceneGroup:insert(levelText)
    sceneGroup:insert(currentScoreDisplay)
    sceneGroup:insert(tileGroup)
    sceneGroup:insert(circleGroup)
    sceneGroup:insert(mirrorGroup)
    sceneGroup:insert(beamGroup)
    -- where the magic happens
    gameStart() 
    
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