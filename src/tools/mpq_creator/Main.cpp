/*
 * MPQ Creator Tool
 * Creates patch-Z.MPQ from DBC files using StormLib
 * 
 * This tool creates MPQ archives for WoW client patches
 * Requires StormLib library to be linked
 */

// Define this BEFORE including StormLib.h to prevent auto-linking
// This disables the #pragma comment(lib, "StormLibRAD.lib") in the header
#define __STORMLIB_NO_STATIC_LINK__

#include <iostream>
#include <string>
#include <filesystem>
#include <vector>
#include <fstream>

// StormLib includes
#include "StormLib.h"

namespace fs = std::filesystem;

bool CreateMPQArchive(const std::string& dbcDir, const std::string& outputMPQ)
{
    std::cout << "MPQ Creator: Creating archive from DBC files..." << std::endl;
    std::cout << "  DBC Directory: " << dbcDir << std::endl;
    std::cout << "  Output MPQ: " << outputMPQ << std::endl;
    
    // Check if DBC directory exists
    if (!fs::exists(dbcDir))
    {
        std::cerr << "Error: DBC directory not found: " << dbcDir << std::endl;
        return false;
    }
    
    // Create output directory if needed
    fs::path outputPath(outputMPQ);
    fs::create_directories(outputPath.parent_path());
    
    // Collect DBC files
    std::vector<fs::path> dbcFiles;
    for (const auto& entry : fs::directory_iterator(dbcDir))
    {
        if (entry.is_regular_file())
        {
            std::string ext = entry.path().extension().string();
            // Accept both .dbc and .dbc.csv files
            if (ext == ".dbc" || ext == ".csv")
            {
                dbcFiles.push_back(entry.path());
                std::cout << "  Found file: " << entry.path().filename() << std::endl;
            }
        }
    }
    
    if (dbcFiles.empty())
    {
        std::cerr << "Error: No DBC files found in directory: " << dbcDir << std::endl;
        return false;
    }
    
    // Use StormLib to create MPQ
    HANDLE hMpq = NULL;
    
    // Create MPQ archive (MPQ format 1 for WoW 3.3.5)
    if (!SFileCreateArchive(outputMPQ.c_str(), MPQ_CREATE_ARCHIVE_V1, 4096, &hMpq))
    {
        DWORD error = GetLastError();
        std::cerr << "Error: Failed to create MPQ archive. Error code: " << error << std::endl;
        return false;
    }
    
    std::cout << "  Created MPQ archive: " << outputMPQ << std::endl;
    
    // Add each DBC file to the archive
    int addedFiles = 0;
    for (const auto& dbcFile : dbcFiles)
    {
        // Determine the internal path in MPQ
        // For WoW, DBC files go in DBFilesClient/
        std::string filename = dbcFile.filename().string();
        std::string internalPath = "DBFilesClient/" + filename;
        
        // Remove .csv extension if present (convert back to .dbc)
        size_t csvPos = filename.rfind(".csv");
        if (csvPos != std::string::npos && csvPos == filename.length() - 4)
        {
            internalPath = "DBFilesClient/" + filename.substr(0, csvPos) + ".dbc";
        }
        
        // Add file to archive
        if (SFileAddFile(hMpq, dbcFile.string().c_str(), internalPath.c_str(), MPQ_FILE_COMPRESS | MPQ_FILE_REPLACEEXISTING))
        {
            std::cout << "  Added: " << filename << " -> " << internalPath << std::endl;
            addedFiles++;
        }
        else
        {
            DWORD error = GetLastError();
            std::cerr << "  Warning: Failed to add " << filename << " (error: " << error << ")" << std::endl;
        }
    }
    
    // Close archive
    SFileCloseArchive(hMpq);
    
    if (addedFiles > 0)
    {
        std::cout << "Successfully created MPQ archive with " << addedFiles << " file(s)" << std::endl;
        return true;
    }
    else
    {
        std::cerr << "Error: No files were added to the archive" << std::endl;
        return false;
    }
}

void PrintUsage(const char* programName)
{
    std::cout << "Usage: " << programName << " <dbc_directory> <output_mpq>" << std::endl;
    std::cout << "Example: " << programName << " dbc/custom patches/patch-Z.MPQ" << std::endl;
    std::cout << std::endl;
    std::cout << "This tool creates an MPQ archive from DBC files for WoW client patches." << std::endl;
}

int main(int argc, char* argv[])
{
    if (argc < 3)
    {
        PrintUsage(argv[0]);
        return 1;
    }
    
    std::string dbcDir = argv[1];
    std::string outputMPQ = argv[2];
    
    // Convert relative paths to absolute if needed
    if (!fs::path(dbcDir).is_absolute())
    {
        dbcDir = (fs::current_path() / dbcDir).string();
    }
    if (!fs::path(outputMPQ).is_absolute())
    {
        outputMPQ = (fs::current_path() / outputMPQ).string();
    }
    
    if (CreateMPQArchive(dbcDir, outputMPQ))
    {
        std::cout << "✓ Successfully created MPQ archive: " << outputMPQ << std::endl;
        return 0;
    }
    else
    {
        std::cerr << "✗ Failed to create MPQ archive." << std::endl;
        return 1;
    }
}
