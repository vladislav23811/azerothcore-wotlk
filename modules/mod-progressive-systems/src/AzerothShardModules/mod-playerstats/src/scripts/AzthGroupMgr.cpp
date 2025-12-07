#include "AzthGroupMgr.h"
#include "DatabaseEnv.h"

AzthGroupMgr::AzthGroupMgr(Group* original)
{
    group = original;

    QueryResult result = CharacterDatabase.Query("SELECT `MaxlevelGroup`, `MaxGroupSize` FROM `azth_groups` WHERE `guid` = '%u'", group->GetGUID().GetCounter());
    if (!result)
    {
        levelMaxGroup = 0;
        groupSize = 1;
    }
    else
    {
        Field* fields = result->Fetch();

        levelMaxGroup = fields[0].Get<uint32>();
        groupSize = fields[1].Get<uint32>();
    }
}

AzthGroupMgr::~AzthGroupMgr()
{
}

void AzthGroupMgr::saveToDb()
{
    ASSERT(group);

    CharacterDatabase.DirectExecute("UPDATE azth_groups SET MaxLevelGroup = %u, MaxGroupSize = %u WHERE leaderGuid = %u", levelMaxGroup, groupSize, this->group->GetLeaderGUID().GetCounter());
}


