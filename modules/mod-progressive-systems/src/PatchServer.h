/*
 * Patch Server - HTTP server for serving MPQ patches to clients
 * Allows clients to auto-download patches via addon
 */

#ifndef PATCH_SERVER_H
#define PATCH_SERVER_H

#include "Define.h"
#include <string>
#include <cstdint>

class PatchServer
{
public:
    static PatchServer* instance()
    {
        static PatchServer instance;
        return &instance;
    }
    
    // Initialize HTTP server for patch distribution
    bool Initialize(uint16_t port = 8080);
    
    // Shutdown server
    void Shutdown();
    
    // Get patch version (for version checking)
    std::string GetPatchVersion() const;
    
    // Check if patch file exists
    bool PatchExists() const;
    
    // Get patch file path
    std::string GetPatchPath() const;
    
private:
    PatchServer() : m_port(0), m_initialized(false) {}
    ~PatchServer() {}
    
    uint16_t m_port;
    bool m_initialized;
    std::string m_patchPath;
    std::string m_patchVersion;
    
    // HTTP request handler
    void HandleRequest(const std::string& path, std::string& response, std::string& contentType);
};

#define sPatchServer PatchServer::instance()

#endif // PATCH_SERVER_H

