/*
 * This file is part of Illusion Arena
 * Contents of this file were adapted from CorkScrew
 * Copyright (C) Arjen '[F]irestarter' van der Veen
 */

#include "g_local.h"

void Cmd_AddItem_f( gentity_t *ent ) {
	char buffer[1024];
	char buffer2[48];
	int len;
	fileHandle_t f;
	char filename[MAX_QPATH] = "powerups/";
	char map[MAX_QPATH];
	char serverinfo[MAX_INFO_STRING];

	if ( g_cheats.integer == 0 ) {
		return;
	}

	if ( trap_Argc() != 2 ) {
		trap_SendServerCommand( ent-g_entities, va("print \"usage: additem item\nexample: additem item_haste\n\""));
		return;
	}

	trap_GetServerinfo( serverinfo, sizeof(serverinfo) );
	Q_strncpyz( map, Info_ValueForKey( serverinfo, "mapname" ), sizeof(map) );

	strcat(filename, map);
	strcat(filename, ".txt");

	trap_FS_FOpenFile( filename, &f, FS_APPEND );

	trap_Argv( 1, buffer2, sizeof( buffer2 ) );


	if ( ent->s.groundEntityNum ) { // we're on the ground, so spawnflags = 0;
	  Com_sprintf( buffer, sizeof(buffer),
		       "\n\n{\nclassname \"%s\"\norigin \"%i %i %i\"\n}\n",
                        buffer2,
                        (int)ent->s.pos.trBase[0],
                        (int)ent->s.pos.trBase[1],
                        (int)ent->s.pos.trBase[2] );
	  trap_SendServerCommand( ent-g_entities, va("print \"%s added at %s\n\"", buffer2, vtos( ent->s.pos.trBase ) ) );
	} else {
	  Com_sprintf( buffer, sizeof(buffer),
		       "\n\n{\nclassname \"%s\"\norigin \"%i %i %i\"\nspawnflags \"1\"\n}\n",
                        buffer2,
                        (int)ent->s.pos.trBase[0],
                        (int)ent->s.pos.trBase[1],
                        (int)ent->s.pos.trBase[2] );
	  trap_SendServerCommand( ent-g_entities, va("print \"suspended %s added at %s\n\"", buffer2, vtos( ent->s.pos.trBase ) ) );
        }

        trap_FS_Write( buffer, strlen( buffer ), f );

        trap_FS_FCloseFile( f );
}
