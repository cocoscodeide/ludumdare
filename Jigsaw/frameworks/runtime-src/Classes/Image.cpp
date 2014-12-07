//
//  Image.cpp
//  Jigsaw
//
//  Created by Wensheng Yang on 12/7/14.
//
//

#include "Image.h"
#include "tolua_fix.h"
#include "cocos2d.h"
#include "LuaBasicConversions.h"

using namespace std;
using namespace cocos2d;

static RenderTexture* render = 0;
static Sprite* imgSprite = 0;
static DrawNode* drawBorder = 0;
static Color4F clrBorder = Color4F(0.f, 0.f, 0.f, 0.5f);

std::vector<Sprite*> ImageLoad(const std::string& imgPath, Rect& rect, int row, int col)
{
#if 1
    if (render) {
        render->release();
    }
    render = RenderTexture::create(rect.size.width + 1, rect.size.height + 1);
    render->retain();
    
    if (imgSprite)
    {
        imgSprite->release();
    }
    imgSprite = Sprite::create(imgPath.c_str());
    imgSprite->retain();
    imgSprite->setAnchorPoint(Vec2(0.f, 0.f));
    imgSprite->setFlippedY(true);
    
    if (drawBorder)
    {
        drawBorder->release();
    }
    drawBorder = DrawNode::create();
    drawBorder->retain();
    float tileW = rect.size.width / col;
    float tileH = rect.size.height / row;
    for(int i = 0; i < row; ++i)
    {
        drawBorder->drawLine(Vec2(0.f, i * tileH), Vec2(rect.size.width, i * tileH), clrBorder);
        drawBorder->drawLine(Vec2(0.f, i * tileH + 1), Vec2(rect.size.width, i * tileH + 1), clrBorder);
    }
    for(int j = 0; j < col; ++j)
    {
        drawBorder->drawLine(Vec2(j * tileW, 0.f), Vec2(j * tileW, rect.size.height), clrBorder);
        drawBorder->drawLine(Vec2(j * tileW + 1, 0.f), Vec2(j * tileW + 1, rect.size.height), clrBorder);
    }
    
    render->begin();
    imgSprite->visit();
    drawBorder->visit();
    render->end();
    auto tex = render->getSprite()->getTexture();
#else
    auto tex = Director::getInstance()->getTextureCache()->addImage(imgPath.c_str());
#endif
    auto texSize = tex->getContentSize();
    std::vector<Sprite*> sprites;
    
    auto tile_rect = Rect(0, 0, 0, 0);
    tile_rect.size.width = texSize.width / col;
    tile_rect.size.height = texSize.height / row;
    float scaleX = texSize.height / rect.size.height;
    float scaleY = texSize.width / rect.size.width;
    for(int i = 0; i < row; ++i)
    {
        for(int j = 0; j < col; ++j)
        {
            tile_rect.origin.x = j * tile_rect.size.width;
            tile_rect.origin.y = i * tile_rect.size.height;
            auto sprite = Sprite::createWithTexture(tex, tile_rect);
            sprite->setScale(scaleX, scaleY);
            sprites.push_back(sprite);
        }
    }
    return sprites;
}

static int lua_cocos2dx_LoadImage(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
    int argc = lua_gettop(L);
    if (4 != argc)
    {
        CCLOG("'lua_cocos2dx_LoadImage' function wrong number of arguments: %d, was expecting %d\n", argc, 4);
        return 0;
    }
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isstring(L, 1, 0, &tolua_err) ||
        !tolua_istable(L, 2, 0, &tolua_err) ||
        !tolua_isnumber(L, 3, 0, &tolua_err) ||
        !tolua_isnumber(L, 4, 0, &tolua_err))
    {
        tolua_error(L,"#ferror in function 'lua_cocos2dx_LoadImage'.",&tolua_err);
        return 0;
    }
#endif
    
    do
    {
        string imgPath = tolua_tostring(L, 1, "");
        Rect rect;
        if (false == luaval_to_rect(L, 2, &rect, "lua_cocos2dx_LoadImage")) break;
        int row = (int)tolua_tonumber(L, 3, 0);
        int col = (int)tolua_tonumber(L, 4, 0);
        vector<Sprite*> sprites = ImageLoad(imgPath, rect, row, col);
        
        lua_newtable(L);                                    /* L: table */
        int indexTable = 1;
        
        for (int i = 0; i < sprites.size(); i++)
        {
            lua_pushnumber(L, (lua_Number)indexTable);
            object_to_luaval<cocos2d::Sprite>(L, "cc.Sprite",sprites[i]);
            lua_rawset(L, -3);
            ++indexTable;
        }

        return 1;
    } while (false);

    return 0;
}

TOLUA_API int register_image(lua_State* L)
{
    tolua_open(L);
    tolua_module(L, NULL, 0);
    tolua_beginmodule(L, NULL);
      tolua_function(L, "ImageLoad", lua_cocos2dx_LoadImage);
    tolua_endmodule(L);
    return 0;
}