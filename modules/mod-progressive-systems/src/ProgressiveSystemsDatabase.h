/*
 * Progressive Systems Database Auto-Setup
 * Header file
 */

#ifndef PROGRESSIVE_SYSTEMS_DATABASE_H
#define PROGRESSIVE_SYSTEMS_DATABASE_H

#include "Define.h"
#include "DatabaseEnv.h"
#include "DatabaseWorkerPool.h"

class AC_GAME_API ProgressiveSystemsDatabase
{
public:
    static ProgressiveSystemsDatabase* instance();
    
    // Load all database tables
    void LoadAll();
    
private:
    ProgressiveSystemsDatabase() = default;
    ~ProgressiveSystemsDatabase() = default;
    ProgressiveSystemsDatabase(ProgressiveSystemsDatabase const&) = delete;
    ProgressiveSystemsDatabase& operator=(ProgressiveSystemsDatabase const&) = delete;
    
    // Load specific database
    void LoadCharacterDatabase();
    void LoadWorldDatabase();
    
    // Execute SQL file
    template<typename T>
    bool ExecuteSQLFile(const std::string& filePath, DatabaseWorkerPool<T>& database);
    
    // Fallback: Execute SQL directly
    void ExecuteCharacterSQL();
    void ExecuteWorldSQL();
};

#define sProgressiveSystemsDB ProgressiveSystemsDatabase::instance()

#endif

