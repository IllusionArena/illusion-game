/*
===========================================================================
Copyright (C) 1999-2005 Id Software, Inc.

This file is part of Quake III Arena source code.

Quake III Arena source code is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

Quake III Arena source code is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Quake III Arena source code; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
===========================================================================
*/
//
/*
=======================================================================

CREDITS

=======================================================================
*/


#include "ui_local.h"


typedef struct {
	menuframework_s	menu;
	int frame;
} creditsmenu_t;

static creditsmenu_t	s_credits;

/*
===============
UI_CreditMenu_Draw
===============
*/
static void UI_CreditMenu_Draw( void ) {
	int		y;

	y = 12;
	UI_DrawProportionalString( 320, y, "Illusion Arena Team is:", UI_CENTER|UI_SMALLFONT, color_white );
	
	y += 1.42 * PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Programming", UI_CENTER|UI_SMALLFONT, color_purple );
	
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Izuru Yakumo, Nishi", UI_CENTER|UI_SMALLFONT, color_white );
	y += 1.42 * PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	
	UI_DrawProportionalString( 320, y, "Art", UI_CENTER|UI_SMALLFONT, color_red );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Izuru Yakumo", UI_CENTER|UI_SMALLFONT, color_white );

	y += 1.42 * PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Thanks to:", UI_CENTER|UI_SMALLFONT, color_green );
	
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Arjen \"Firestarter\" van der Veen (CorkScrew)", UI_CENTER|UI_SMALLFONT, color_white );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Bishop-333 (OmegA)", UI_CENTER|UI_SMALLFONT, color_white );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Burning (from Code3Arena)", UI_CENTER|UI_SMALLFONT, color_white );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "id Software for id Tech 3", UI_CENTER|UI_SMALLFONT, color_white );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "Neil \"haste\" Toronto (Alternate Fire, Unlagged)", UI_CENTER|UI_SMALLFONT, color_white );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "OpenArena Team", UI_CENTER|UI_SMALLFONT, color_white );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "[Runo] (@runo14 at ModDB)", UI_CENTER|UI_SMALLFONT, color_white );
	y += PROP_HEIGHT * PROP_SMALL_SIZE_SCALE;
	UI_DrawProportionalString( 320, y, "You!", UI_CENTER|UI_SMALLFONT, color_white );
	
	UI_DrawString( 320, 440, "Visit our website at:", UI_CENTER|UI_SMALLFONT, color_yellow );
	UI_DrawString( 320, 460, "http://illusion-arena.twilightparadox.com/", UI_CENTER|UI_SMALLFONT, color_yellow );
}

/*
=================
UI_CreditMenu_Key
=================
*/
static sfxHandle_t UI_CreditMenu_Key( int key ) {
        if( key & K_CHAR_FLAG ) {
                return 0;
        }
        s_credits.frame++;

        if (s_credits.frame == 1) {
                s_credits.menu.draw = UI_CreditMenu_Draw;
        } else {
                trap_Cmd_ExecuteText( EXEC_APPEND, "quit\n" );
        }
        return 0;
}

/*
===============
UI_CreditMenu
===============
*/
void UI_CreditMenu( void ) {
	memset( &s_credits, 0 ,sizeof(s_credits) );

	s_credits.menu.draw = UI_CreditMenu_Draw;
	s_credits.menu.key = UI_CreditMenu_Key;
	s_credits.menu.fullscreen = qtrue;
	UI_PushMenu ( &s_credits.menu );
}
