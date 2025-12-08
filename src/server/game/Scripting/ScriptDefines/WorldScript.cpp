/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Affero General Public License as published by the
 * Free Software Foundation; either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "WorldScript.h"
#include "ScriptMgr.h"
#include "ScriptMgrMacros.h"
#include "Log.h"
#include <exception>
#include <cstring>
#include <string>

void ScriptMgr::OnOpenStateChange(bool open)
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_OPEN_STATE_CHANGE, script->OnOpenStateChange(open));
}

void ScriptMgr::OnAfterConfigLoad(bool reload)
{
    LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: Starting, reload={}", reload);
    if (!ScriptRegistry<WorldScript>::EnabledHooks[WORLDHOOK_ON_AFTER_CONFIG_LOAD].empty())
    {
        size_t scriptCount = ScriptRegistry<WorldScript>::EnabledHooks[WORLDHOOK_ON_AFTER_CONFIG_LOAD].size();
        LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: Found {} modules with OnAfterConfigLoad hook", scriptCount);
        size_t index = 0;
        for (auto const& script : ScriptRegistry<WorldScript>::EnabledHooks[WORLDHOOK_ON_AFTER_CONFIG_LOAD])
        {
            index++;
            
            // Skip known problematic module 18 (azth_smartstone_world) that causes crashes
            // We skip by index to avoid calling GetName() which crashes
            if (index == 18)
            {
                LOG_WARN("server.loading", "ScriptMgr::OnAfterConfigLoad: Skipping module {}/{} (azth_smartstone_world) due to known crash issue", index, scriptCount);
                continue;
            }
            
            // Defensive check: ensure script pointer is valid
            if (!script)
            {
                LOG_ERROR("server.loading", "ScriptMgr::OnAfterConfigLoad: Module {}/{} has null pointer, skipping", index, scriptCount);
                continue;
            }
            
            std::string scriptName = "unknown";
            try
            {
                scriptName = script->GetName();
            }
            catch (...)
            {
                LOG_ERROR("server.loading", "ScriptMgr::OnAfterConfigLoad: Module {}/{} has invalid GetName(), skipping", index, scriptCount);
                continue;
            }
            
            LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: Processing module {}/{}: {}", index, scriptCount, scriptName);
            
            try
            {
                script->OnAfterConfigLoad(reload);
                LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: Module {} completed successfully", scriptName.c_str());
            }
            catch (std::exception const& e)
            {
                LOG_FATAL("server.loading", "Exception in module OnAfterConfigLoad ({}): {}. Continuing with other modules...", scriptName.c_str(), e.what());
            }
            catch (...)
            {
                LOG_FATAL("server.loading", "Unknown exception in module OnAfterConfigLoad ({}). Continuing with other modules...", scriptName.c_str());
            }
            LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: Finished processing module {}", scriptName.c_str());
        }
        LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: All modules processed, about to return");
    }
    else
    {
        LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: No modules with OnAfterConfigLoad hook");
    }
    LOG_INFO("server.loading", "ScriptMgr::OnAfterConfigLoad: Function returning");
}

void ScriptMgr::OnLoadCustomDatabaseTable()
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE, script->OnLoadCustomDatabaseTable());
}

void ScriptMgr::OnBeforeConfigLoad(bool reload)
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_BEFORE_CONFIG_LOAD, script->OnBeforeConfigLoad(reload));
}

void ScriptMgr::OnMotdChange(std::string& newMotd, LocaleConstant& locale)
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_MOTD_CHANGE, script->OnMotdChange(newMotd, locale));
}

void ScriptMgr::OnShutdownInitiate(ShutdownExitCode code, ShutdownMask mask)
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_SHUTDOWN_INITIATE, script->OnShutdownInitiate(code, mask));
}

void ScriptMgr::OnShutdownCancel()
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_SHUTDOWN_CANCEL, script->OnShutdownCancel());
}

void ScriptMgr::OnWorldUpdate(uint32 diff)
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_UPDATE, script->OnUpdate(diff));
}

void ScriptMgr::OnStartup()
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_STARTUP, script->OnStartup());
}

void ScriptMgr::OnShutdown()
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_SHUTDOWN, script->OnShutdown());
}

void ScriptMgr::OnAfterUnloadAllMaps()
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_AFTER_UNLOAD_ALL_MAPS, script->OnAfterUnloadAllMaps());
}

void ScriptMgr::OnBeforeFinalizePlayerWorldSession(uint32& cacheVersion)
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_BEFORE_FINALIZE_PLAYER_WORLD_SESSION, script->OnBeforeFinalizePlayerWorldSession(cacheVersion));
}

void ScriptMgr::OnBeforeWorldInitialized()
{
    CALL_ENABLED_HOOKS(WorldScript, WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED, script->OnBeforeWorldInitialized());
}

WorldScript::WorldScript(const char* name, std::vector<uint16> enabledHooks)
    : ScriptObject(name, WORLDHOOK_END)
{
    // If empty - enable all available hooks.
    if (enabledHooks.empty())
        for (uint16 i = 0; i < WORLDHOOK_END; ++i)
            enabledHooks.emplace_back(i);

    ScriptRegistry<WorldScript>::AddScript(this, std::move(enabledHooks));
}

template class AC_GAME_API ScriptRegistry<WorldScript>;
