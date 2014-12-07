-- 图片模块
-- 功能：
--     加载图片，把图片按行列拆开

Image = {}

------
--@param imgPath String
--@param rect cc.rect the draw rectangle
--@param row Number
--@param col Number column
--@return #boolean
function Image.load(imgPath, rect, row, col)
--    local tex = cc.Director:getInstance():getTextureCache():addImage(imgPath)
--    local texSize = tex:getContentSize()
--    local sprites = {}
--    
--    -- calculate every tile's frame rect, and create sprite from it
--    local tile_rect = cc.rect(0, 0, 0, 0)
--    tile_rect.width = texSize.width / col
--    tile_rect.height = texSize.height / row
--    local scaleX = texSize.height / rect.height
--    local scaleY = texSize.width / rect.width
--    for i=0, row - 1 do
--    	for j=1, col do
--            tile_rect.x = (j - 1) * tile_rect.width
--            tile_rect.y = i * tile_rect.height
--            local sprite = cc.Sprite:createWithTexture(tex,tile_rect);
--            sprite:setScale(scaleX,scaleY)
--            sprites[i * col + j] = sprite;
--    	end
--    end
--    return sprites
    return ImageLoad(imgPath, rect, row, col)
end

------
--@param row Number 
--@param col Number
--@param stepNum Number: the execution number of random
--@return table#table dstTable 
function Image.randomImageOrder(row, col, stepNum)
    local dstTable = {}
    dstTable[1] = -1
    for i = 2, row * col + 1 do
        dstTable[i] = i - 1
    end

    local leftStep = stepNum
    math.randomseed(os.time())
    --init:switch col -> 1
    dstTable[1] = col
    dstTable[col + 1] = -1
    leftStep = leftStep - 1
    local spacePlace = col + 1
    local lastSpacePlace = col + 1
    while leftStep ~= 0 do
        local adjoining = {}
        --set adjoining

        --left
        if (spacePlace - 1) % col ~= 1 and lastSpacePlace ~= (spacePlace - 1) then
            adjoining[#adjoining+1] = spacePlace - 1
        end

        --bottom
        if spacePlace + col <= row * col + 1 and lastSpacePlace ~= (spacePlace + col) then
            adjoining[#adjoining+1] = spacePlace + col
        end

        --right
        if (col == 2 and spacePlace % 2 == 0) or (col ~= 2 and (spacePlace + 1) % col ~= 2) and lastSpacePlace ~= (spacePlace + 1) then
            adjoining[#adjoining+1] = spacePlace + 1
        end

        --top
        if spacePlace - col > 1 and lastSpacePlace ~= (spacePlace - col)then
            adjoining[#adjoining+1] = spacePlace - col
        end

        if #adjoining ~= 0 then
            --random to switch the space place
            local dstSpacePlace = adjoining[1]
            if #adjoining ~= 1 then
                dstSpacePlace = adjoining[math.random(#adjoining)]
            end
            dstTable[spacePlace] = dstTable[dstSpacePlace]
            dstTable[dstSpacePlace] = -1
            lastSpacePlace = spacePlace
            spacePlace = dstSpacePlace
        end

        leftStep = leftStep - 1
    end

    return dstTable
end
