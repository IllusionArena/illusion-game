/*
 * This file is part of Illusion Arena
 * Contains additional functions adapted from other places
 * and mods, such as CorkScrew.
 *
 */

#include "g_local.h"

/**
 * Cmd_Boots_f
 * Enables the player to perform longer jumps on demand
 * It can be toggled from the console, or bound to a key
 *
 * Note: if you use this on a level that already has low gravity
 * using these will get out of hand.
 *
 * @param ent argument of type gentity_t
 */

void Cmd_Boots_f( gentity_t *ent ) {
  char *msg;
  ent->flags ^= FL_BOOTS;

  if (!(ent->flags & FL_BOOTS)) {
	  msg = "Anti-gravity boots OFF\n";
  } else {
	  msg = "Anti-gravity boots ON\n";
  }

  trap_SendServerCommand( ent-g_entities, va("print \"%s\"", msg));
}

/**
 * Cmd_AddItem_f
 * Inserts a power-up on the player's current location at a given map
 * Adapted from CorkScrew (Firestarter)
 *
 * @param ent argument of type gentity_t
 */

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
