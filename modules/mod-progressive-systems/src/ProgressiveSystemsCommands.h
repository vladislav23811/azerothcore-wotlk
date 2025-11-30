/*
 * Progressive Systems Debug Commands
 * Provides in-game commands for debugging and testing
 */

#ifndef PROGRESSIVE_SYSTEMS_COMMANDS_H
#define PROGRESSIVE_SYSTEMS_COMMANDS_H

#include "Define.h"
#include "Optional.h"

class ChatHandler;

class ChatHandler;

class AC_GAME_API ProgressiveSystemsCommands
{
public:
    static bool HandleProgressiveSystemsInfoCommand(ChatHandler* handler);
    static bool HandleProgressiveSystemsPointsCommand(ChatHandler* handler, Optional<uint32> points);
    static bool HandleProgressiveSystemsTierCommand(ChatHandler* handler, Optional<uint8> tier);
    static bool HandleProgressiveSystemsResetCommand(ChatHandler* handler);
    static bool HandleProgressiveSystemsDebugCommand(ChatHandler* handler, Optional<bool> enable);
    static bool HandleProgressiveSystemsCacheCommand(ChatHandler* handler);
};

#endif // PROGRESSIVE_SYSTEMS_COMMANDS_H

