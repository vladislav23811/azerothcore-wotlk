/**
    This plugin can be used for common player customizations
 */

#include "ScriptMgr.h"
#include "InstanceScript.h"
#include "InstanceSaveMgr.h"
#include "Player.h"
#include "Map.h"
#include "WorldSession.h"
#include "AchievementMgr.h"
#include "AzthGroupMgr.h"
#include "AzthPlayer.h"
#include "azth_custom_hearthstone_mode.h"
#include "AZTH.h"

class AzthPlayerPlg : public PlayerScript
{
public:
    AzthPlayerPlg() : PlayerScript("AzthPlayerPlg") { }

    void OnPlayerLogin(Player* pl) override
    {
        uint32 accId = pl->GetSession()->GetAccountId();
        //                                                    0
        QueryResult res = LoginDatabase.Query("SELECT custom_lang FROM azth_account_info WHERE id = '%d';", accId);

        if (res != nullptr && res->GetRowCount() > 0)
        {
            Field* info = res->Fetch();
            sAZTH->GetAZTHPlayer(pl)->setCustLang(AzthCustomLangs(info[0].Get<uint8>()));
        }

        //------------------------------AZTH BANK ITEMS----------------------------------------------

        QueryResult itemInBankQuery = CharacterDatabase.Query("SELECT item,itemEntry FROM azth_items_bank where guid = %u", pl->GetGUID().GetCounter()); //retrieve all items from db

        if (itemInBankQuery)
        {
            do
            {
                Field* itemInBankField = itemInBankQuery->Fetch();

                if (!itemInBankField)
                    break;

                uint32 itemGUID = itemInBankField[0].Get<uint32>();
                uint32 itemEntry = itemInBankField[1].Get<uint32>();

                sAZTH->GetAZTHPlayer(pl)->AddBankItem(itemEntry, itemGUID);

            } while (itemInBankQuery->NextRow());
        }

        // GM mods, see anything
        if (pl->HasFlag(PLAYER_FLAGS, PLAYER_FLAGS_DEVELOPER) /*[/AZTH]*/)
        {
            pl->SetPhaseMask(PHASEMASK_ANYWHERE, false);
            pl->GetSession()->SendSetPhaseShift(PHASEMASK_ANYWHERE);
        }
    }

    // void OnLevelChanged(Player* player, uint8 oldLevel) override
    // {
    //     if (!player)
    //         return;

    //     if (oldLevel == 9 && !sAZTH->GetAZTHPlayer(player)->isTimeWalking() && sConfigMgr->GetOption<bool>("Azth.LevelBonus.10.Enable", false))
    //         sAZTH->SendGameMail(player, "Well done!", "You reached level 10, a small present for you by AzerothShard!", 10 * GOLD);
    // }

    // // logger for custom extended costs
    // void OnBeforeStoreOrEquipNewItem(Player* player, uint32 /*vendorslot*/, uint32 &item, uint8 /*count*/, uint8 /*bag*/, uint8 /*slot*/, ItemTemplate const* /*pProto*/, Creature* pVendor, VendorItem const* crItem, bool /*bStore*/) override
    // {
    //     long price = 0;

    //     if (crItem->ExtendedCost)
    //     {
    //         if (crItem->ExtendedCost <= 2997)
    //             return;

    //         price = crItem->ExtendedCost;
    //         price = price * (-1);
    //     }
    //     else
    //     {
    //         /*ItemTemplate const* pProto = sObjectMgr->GetItemTemplate(item);
    //         if (!pProto)
    //         {
    //             return;
    //         }

    //         if (crItem->IsGoldRequired(pProto))
    //         {
    //             price = pProto->BuyPrice;
    //         }*/
    //         return;
    //     }

    //     uint32 guid = pVendor ? pVendor->GetEntry() : 0;

    //     CharacterDatabase.DirectExecute("INSERT INTO `azth_buy_log` (`playerGuid`, `item`, `vendor`, `price`) VALUES (%u, %u, %u, %ld);",
    //         player->GetGUID().GetCounter(), item, guid, price);
    // }

};



void AddSC_azth_player_plg() {
    new AzthPlayerPlg();
}

