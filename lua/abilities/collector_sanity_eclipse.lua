collector_sanity_eclipse = class({})
LinkLuaModifier( "modifier_collector_sanity_eclipse_thinker", "abilities/collector_sanity_eclipse.lua", LUA_MODIFIER_MOTION_NONE )

function collector_sanity_eclipse:GetAOERadius()
	return self:GetSpecialValueFor( "area_of_effect" )
end

function collector_sanity_eclipse:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local delay = self:GetSpecialValueFor("delay")

	-- create modifier thinker
	CreateModifierThinker(
		caster, -- player source
		self, -- ability source
		"modifier_collector_sanity_eclipse_thinker", -- modifier name
		{ duration = delay },
		point,
		caster:GetTeamNumber(),
		false
	)

	EmitSoundOn( "Hero_Invoker.EMP.Cast", self:GetCaster() )
end

modifier_collector_sanity_eclipse_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_collector_sanity_eclipse_thinker:IsHidden()
	return true
end

function modifier_collector_sanity_eclipse_thinker:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_collector_sanity_eclipse_thinker:OnCreated( kv )
    if IsServer() then 
        self.damage_pct = self:GetAbility():GetOrbSpecialValueFor("damage_by_int", "w")
        self.radius = self:GetAbility():GetSpecialValueFor("area_of_effect")
		self:PlayEffects1()
	end
end

function modifier_collector_sanity_eclipse_thinker:OnDestroy( kv )
	if IsServer() then
		-- find caught units
		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),	
			self:GetParent():GetOrigin(),	
			nil,	
			self.radius,	
			DOTA_UNIT_TARGET_TEAM_ENEMY,	
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MANA_ONLY,
			0,	
			false	
		)
        
        for _,enemy in pairs(enemies) do
            if not enemy:GetIntellect() or enemy:GetIntellect() == 0 then 
                enemy:Kill(self:GetAbility(), self:GetCaster())
            else 
                local int = self:GetCaster():GetIntellect() - enemy:GetIntellect()
                if int > 0 then
					local damage = int * self.damage_pct
				
					local desiredMana = enemy:GetMaxMana() * 0.6
					enemy:SetMana(desiredMana)

                    local damageTable = {
                        attacker = self:GetCaster(),
                        damage_type = DAMAGE_TYPE_MAGICAL,
                        ability = self:GetAbility(),
                        damage =  damage,
                        victim = enemy
                    }

					ApplyDamage(damageTable)
                end 
            end

            iNtdx = ParticleManager:CreateParticle( "particles/collector/collector_sanity_eclipse_enemy.vpcf", PATTACH_WORLDORIGIN, enemy )
            ParticleManager:ReleaseParticleIndex( iNtdx )

            EmitSoundOn("Hero_ObsidianDestroyer.AstralImprisonment.End", enemy)
        end
        
		self:PlayEffects2()
	end
end

function modifier_collector_sanity_eclipse_thinker:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_emp.vpcf"
	local sound_cast = "Hero_Invoker.EMP.Charge"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )
	self:AddParticle(effect_cast, false, false, -1, false, false)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_collector_sanity_eclipse_thinker:PlayEffects2()
	-- Get Resources
    local sound_cast = "Hero_ObsidianDestroyer.SanityEclipse.TI8"
    
    local nFXIndex = ParticleManager:CreateParticle( "particles/galactus/galactus_seed_of_ambition_eternal_item.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl(nFXIndex, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(nFXIndex, 2, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(nFXIndex, 3, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(nFXIndex, 6, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl (nFXIndex, 1, Vector (self.radius, self.radius, 0))
    ParticleManager:ReleaseParticleIndex( nFXIndex )

	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end