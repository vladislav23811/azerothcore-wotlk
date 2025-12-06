/*
 * Progressive Systems Database Script
 * Handles database loading events - generates DBC entries automatically
 */

#include "ProgressiveSystemsWorldScript.h"
#include "DBCGenerator.h"
#include "DatabaseScript.h"
#include "ObjectMgr.h"
#include "World.h"
#include "ScriptMgr.h"
#include "Log.h"
#include "Config.h"
#include <filesystem>
#include <fstream>
#include <chrono>

class ProgressiveSystemsDatabaseScript : public DatabaseScript
{
public:
    ProgressiveSystemsDatabaseScript() : DatabaseScript("ProgressiveSystemsDatabaseScript") {}

    void OnAfterDatabasesLoaded(uint32 updateFlags) override
    {
        // This is called after all databases are loaded, including item templates
        // Perfect place to generate DBC entries for custom items!
        
        LOG_INFO("module", "Progressive Systems: Databases loaded, generating DBC entries for custom items...");
        
        // Initialize DBC Generator if not already done
        if (sDBCGenerator)
        {
            // Reload custom items and generate DBC entries
            sDBCGenerator->ReloadCustomItems();
            
            // Get paths from config
            std::string dbcDir = sConfigMgr->GetOption<std::string>("ProgressiveSystems.DBC.OutputDir", "dbc/custom");
            std::string outputMPQ = sConfigMgr->GetOption<std::string>("ProgressiveSystems.DBC.MPQOutput", "patches/patch-Z.MPQ");
            
            // Also copy to web server if configured
            std::string webServerPath = sConfigMgr->GetOption<std::string>("ProgressiveSystems.DBC.WebServerPath", "");
            if (!webServerPath.empty() && std::filesystem::exists(outputMPQ))
            {
                std::string webPatchPath = webServerPath + "/patches/patch-Z.MPQ";
                std::filesystem::create_directories(std::filesystem::path(webPatchPath).parent_path());
                std::filesystem::copy_file(outputMPQ, webPatchPath, std::filesystem::copy_options::overwrite_existing);
                LOG_INFO("module", "Progressive Systems: Patch copied to web server: {}", webPatchPath);
                
                // Update version.txt
                std::string versionPath = webServerPath + "/patches/version.txt";
                std::ofstream versionFile(versionPath);
                if (versionFile.is_open())
                {
                    auto now = std::chrono::system_clock::now();
                    auto time = std::chrono::system_clock::to_time_t(now);
                    versionFile << time;
                    versionFile.close();
                    LOG_INFO("module", "Progressive Systems: Version file updated: {}", versionPath);
                }
            }
            
            // Write DBC files
            if (sDBCGenerator->WriteDBCFiles(dbcDir))
            {
                LOG_INFO("module", "Progressive Systems: DBC files written successfully to {}", dbcDir);
                
                // Generate MPQ patch (optional - can be done manually)
                if (sDBCGenerator->GenerateMPQPatch(dbcDir, outputMPQ))
                {
                    LOG_INFO("module", "Progressive Systems: MPQ patch generated: {}", outputMPQ);
                    LOG_INFO("module", "Progressive Systems: Patch ready for client distribution");
                }
                else
                {
                    LOG_INFO("module", "Progressive Systems: MPQ generation skipped (install pympq: pip install pympq)");
                    LOG_INFO("module", "Progressive Systems: DBC CSV files available at: {}", dbcDir);
                }
            }
            else
            {
                LOG_WARN("module", "Progressive Systems: Failed to write DBC files");
            }
        }
        else
        {
            LOG_ERROR("module", "Progressive Systems: DBCGenerator not initialized!");
        }
    }
};

void AddSC_progressive_systems_world_script()
{
    // Register DatabaseScript for DBC generation
    new ProgressiveSystemsDatabaseScript();
}

