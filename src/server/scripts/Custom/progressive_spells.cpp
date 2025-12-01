/*
 * Progressive Spell Scripts
 * Spells that scale with progression tier
 */

#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "Player.h"
#include "DatabaseEnv.h"

// ============================================================
// PROGRESSIVE DAMAGE SPELL
// Damage scales 10% per tier
// Formula: baseDamage * (1.0 + tier * 0.1)
// ============================================================
class spell_progressive_damage : public SpellScriptLoader
{
public:
    spell_progressive_damage() : SpellScriptLoader("spell_progressive_damage") { }

    class spell_progressive_damage_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_progressive_damage_SpellScript);

        void HandleDamage(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            if (!caster || !caster->IsPlayer())
                return;

            // Get player's progression tier
            uint32 guid = caster->GetGUID().GetCounter();
            QueryResult result = CharacterDatabase.Query(
                "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);

            uint8 tier = 1;
            if (result)
            {
                tier = result->Fetch()[0].Get<uint8>();
            }

            // Scale damage: baseDamage * (1.0 + tier * 0.1)
            float damageMultiplier = 1.0f + (tier * 0.1f);
            int32 damage = GetHitDamage();
            SetHitDamage(int32(damage * damageMultiplier));
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_progressive_damage_SpellScript::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_progressive_damage_SpellScript();
    }
};

// ============================================================
// PROGRESSIVE HEAL SPELL
// Healing scales 15% per tier
// Formula: baseHeal * (1.0 + tier * 0.15)
// ============================================================
class spell_progressive_heal : public SpellScriptLoader
{
public:
    spell_progressive_heal() : SpellScriptLoader("spell_progressive_heal") { }

    class spell_progressive_heal_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_progressive_heal_SpellScript);

        void HandleHeal(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            if (!caster || !caster->IsPlayer())
                return;

            // Get player's progression tier
            uint32 guid = caster->GetGUID().GetCounter();
            QueryResult result = CharacterDatabase.Query(
                "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);

            uint8 tier = 1;
            if (result)
            {
                tier = result->Fetch()[0].Get<uint8>();
            }

            // Scale healing: baseHeal * (1.0 + tier * 0.15)
            float healMultiplier = 1.0f + (tier * 0.15f);
            int32 heal = GetHitHeal();
            SetHitHeal(int32(heal * healMultiplier));
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_progressive_heal_SpellScript::HandleHeal, EFFECT_0, SPELL_EFFECT_HEAL);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_progressive_heal_SpellScript();
    }
};

// ============================================================
// PROGRESSIVE BUFF SPELL
// Buff effectiveness scales 5% per tier
// Formula: baseAmount * (1.0 + tier * 0.05)
// ============================================================
class spell_progressive_buff : public SpellScriptLoader
{
public:
    spell_progressive_buff() : SpellScriptLoader("spell_progressive_buff") { }

    class spell_progressive_buff_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_progressive_buff_SpellScript);

        void HandleBuff(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            if (!caster || !caster->IsPlayer())
                return;

            // Get player's progression tier
            uint32 guid = caster->GetGUID().GetCounter();
            QueryResult result = CharacterDatabase.Query(
                "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);

            uint8 tier = 1;
            if (result)
            {
                tier = result->Fetch()[0].Get<uint8>();
            }

            // Scale buff: baseAmount * (1.0 + tier * 0.05)
            float buffMultiplier = 1.0f + (tier * 0.05f);
            int32 amount = GetHitDamage();
            SetHitDamage(int32(amount * buffMultiplier));
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_progressive_buff_SpellScript::HandleBuff, EFFECT_0, SPELL_EFFECT_APPLY_AURA);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_progressive_buff_SpellScript();
    }
};

void AddSC_progressive_spells()
{
    new spell_progressive_damage();
    new spell_progressive_heal();
    new spell_progressive_buff();
}

