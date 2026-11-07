-- UnBalatro: unbalanced Balatro. Custom jokers for Balatro3DS.
-- Each joker is its own 70x94 image in assets/1x (.png + .t3x, plus an optional _negative
-- version). Bump "version" in the .json when a change would break a run in progress
-- (adding/removing a joker, changing what `config` holds).
--
-- Jokers that create cards call the port's own game methods (G:add_joker_by_def,
-- G:add_consumable and friends), the same ones its built-in Riff-Raff, Cartomancer and
-- Perkeo use.

--------------------------------------------------------------------------------
-- Aces Up (Common, $4): $3 per Ace in your full deck at the end of each round.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "aces_up",
    loc_txt = {
        name = "Aces Up",
        text = {
            "Earn {C:money}$#1#{} at end of round",
            "for each {C:attention}Ace{} in your",
            "full deck",
        },
    },
    config = { extra = { dollars = 3 } },
    rarity = 1,
    cost = 4,
    sprite = "aces_up.png",
    negative_sprite = "aces_up_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calc_dollar_bonus = function(self, card)
        -- Same full-deck count the port's Cloud 9 uses (rank 14 is an Ace).
        local aces = G:count_cards_in_full_deck(function(c) return tonumber(c.rank) == 14 end)
        local total = aces * card.ability.extra.dollars
        if total > 0 then return total end
    end,
}

--------------------------------------------------------------------------------
-- Triggered Joker (Rare, $7): every played card and every card held in hand is retriggered
-- twice (3 passes in all). Held cards repeat their held-in-hand abilities (Steel, Gold,
-- Baron, ...), as Mime does: only when the first pass actually did something.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "triggered",
    loc_txt = {
        name = "Triggered Joker",
        text = {
            "Retrigger all played and",
            "held cards {C:attention}#1#X{}",
        },
    },
    config = { extra = { repetitions = 2 } },
    rarity = 3,
    cost = 7,
    sprite = "triggered.png",
    negative_sprite = "triggered_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.repetitions } }
    end,
    calculate = function(self, card, context)
        if not context.repetition then return end
        local port = context.port
        if port and port.held then
            -- Held card: repeat only if its first pass produced an effect.
            if port.held_first_pass_effect_applied == true then
                return { repetitions = card.ability.extra.repetitions }
            end
        elseif context.cardarea == G.play then
            return { repetitions = card.ability.extra.repetitions }
        end
    end,
}

--------------------------------------------------------------------------------
-- Wizard Joker (Common, $5): +25 Chips for every Tarot card used this run.
-- Uses the run's own Tarot-used counter (the one Fortune Teller reads), so the bonus
-- is cumulative over the whole run, survives saves, and counts Tarots used before
-- this joker was bought.
--------------------------------------------------------------------------------
local function tarots_used()
    return (G and tonumber(G.tarots_used)) or 0
end

SMODS.Joker {
    key = "wizard",
    loc_txt = {
        name = "Wizard Joker",
        text = {
            "Gains {C:chips}+#1#{} Chips for every",
            "{C:attention}Tarot{} card used this run",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 25 } },
    rarity = 1,
    cost = 5,
    sprite = "wizard_joker.png",
    negative_sprite = "wizard_joker_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chips * tarots_used() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local bonus = card.ability.extra.chips * tarots_used()
            if bonus > 0 then return { chips = bonus } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Bizarro Joker (Common, $7): creates 1 random Uncommon Negative Joker each round
-- (when the Blind is selected, like Riff-Raff). Never Eternal.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "bizarro",
    loc_txt = {
        name = "Bizarro Joker",
        text = {
            "Create {C:attention}#1#{} random {C:attention}Uncommon{}",
            "{C:purple}Negative{} Joker when",
            "a Blind is selected",
        },
    },
    config = { extra = { count = 1 } },
    rarity = 1,
    cost = 7,
    sprite = "bizarro_joker.png",
    negative_sprite = "bizarro_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.count } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local made, picked = 0, {}
            for _ = 1, card.ability.extra.count do
                -- Same call Riff-Raff uses: rarity 2 is Uncommon.
                local id = G:_pick_joker_id_shop_rarity_distribution(
                    function() return 2 end, "biz", picked, 1, false)
                if not id then break end
                picked[id] = true
                -- A Negative joker brings its own slot, so there is always room.
                if G:add_joker_by_def(id, { edition = "negative", eternal = false }) then
                    made = made + 1
                    -- The all-Eternal challenge forces the sticker on in add_joker_by_def,
                    -- so clear it on the joker that was just added.
                    local newest = G.jokers[#G.jokers]
                    if newest then newest.eternal = false end
                end
            end
            if made > 0 then SMODS.joker_message(card, "Bizarro!") end
        end
    end,
}

--------------------------------------------------------------------------------
-- Perkeo Jr. (Uncommon, $7): every time a Blind is selected, creates 1 Negative copy of
-- the last Tarot or Planet card used. Like The Fool, it does nothing until one has been used.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "perkeo_jr",
    loc_txt = {
        name = "Perkeo Jr.",
        text = {
            "When a {C:attention}Blind{} is selected,",
            "create a {C:purple}Negative{} copy of the",
            "last {C:attention}Tarot{} or {C:attention}Planet{} card used",
            "{C:inactive}(Must have room)",
        },
    },
    config = { extra = { count = 1 } },
    rarity = 2,
    cost = 7,
    sprite = "perkeo_jr.png",
    negative_sprite = "perkeo_jr_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.count } }
    end,
    calculate = function(self, card, context)
        -- Blueprint, Brainstorm and Kirby copies run this too, so each makes its own.
        if context.setting_blind then
            -- The last Tarot/Planet used (the same record The Fool reads). Until one has
            -- been used there is nothing to copy, so nothing happens.
            local id = G.last_consumable_use_id
            local def = id and CONSUMABLE_DEFS and CONSUMABLE_DEFS[id]
            if not (def and (def.kind == "tarot" or def.kind == "planet")) then return end

            local made = 0
            for _ = 1, card.ability.extra.count do
                -- A Negative consumable brings its own slot, so there is always room.
                if G:add_consumable(id, { edition = "negative" }) then made = made + 1 end
            end
            if made > 0 then SMODS.joker_message(card, "Perkeo!") end
        end
    end,
}

--------------------------------------------------------------------------------
-- Infinity Joker (Uncommon, $6): creates The Soul after defeating a Boss Blind
-- (must have consumable room).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "infinity",
    loc_txt = {
        name = "Infinity Joker",
        text = {
            "Create {C:purple}The Soul{} after",
            "defeating a {C:attention}Boss Blind{}",
            "{C:inactive}(Must have room)",
        },
    },
    rarity = 2,
    cost = 6,
    sprite = "infinity_joker.png",
    negative_sprite = "infinity_joker_negative.png",
    calculate = function(self, card, context)
        if context.blind_defeated and not context.blueprint
            and context.port and tonumber(context.port.blind_index) == 3 then
            if G:can_add_consumable() and G:add_consumable("spectral_soul") then
                SMODS.joker_message(card, "Soul!")
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Freedom Joker (Common, $4): gains +4 Mult for every King, Queen, 6 and 9 played, and
-- +20 Chips for every 4 played. Counts from the moment it is bought, and each copy
-- scales on its own. "Played" means scored, like the port's Wee Joker, so cards that
-- don't score (kickers) don't count.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "freedom",
    loc_txt = {
        name = "Freedom Joker",
        text = {
            "Gains {C:mult}+#1#{} Mult for every played",
            "{C:attention}King{}, {C:attention}Queen{}, {C:attention}6{} and {C:attention}9{}.",
            "Gains {C:chips}+#2#{} Chips for every played {C:attention}4{}",
            "{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult, {C:chips}+#4#{C:inactive} Chips)",
        },
    },
    config = { extra = { mult_gain = 4, chips_gain = 20, mult = 0, chips = 0 } },
    rarity = 1,
    cost = 4,
    sprite = "freedom_joker.png",
    negative_sprite = "freedom_joker_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult_gain, e.chips_gain, e.mult, e.chips } }
    end,
    calculate = function(self, card, context)
        local e = card.ability.extra
        -- Grow on each scored card (Blueprint/Brainstorm copies don't grow it).
        if context.individual and context.cardarea == G.play and not context.blueprint then
            local id = tonumber(context.other_card:get_id())
            if id == 13 or id == 12 or id == 6 or id == 9 then
                e.mult = e.mult + e.mult_gain
            elseif id == 4 then
                e.chips = e.chips + e.chips_gain
            end
            return
        end
        -- Pay out what it has stored.
        if context.joker_main and (e.mult > 0 or e.chips > 0) then
            return { mult = e.mult, chips = e.chips }
        end
    end,
}


--------------------------------------------------------------------------------
-- Sisyphus (Common, $6): retriggers every other Joker on the final hand of the round.
-- Uses the port's `retrigger_joker_check`: it is asked each time a Joker triggers, and
-- answering { repetitions = 1 } runs that Joker's effect once more. The final hand is the
-- one that leaves 0 hands (the same test the built-in Dusk uses). Only the Jokers' scoring
-- steps repeat (before, each scored card, the main scoring step, after), so end-of-round
-- payouts are not doubled.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "sisyphus",
    loc_txt = {
        name = "Sisyphus",
        text = {
            "Retrigger all other {C:attention}Jokers{}",
            "on the {C:attention}final hand{} of the round",
        },
    },
    config = {},
    rarity = 1,
    cost = 6,
    sprite = "sisyphus.png",
    negative_sprite = "sisyphus_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        if not context.retrigger_joker_check then return end
        if context.other_card == card then return end          -- never itself
        local oc = context.other_context
        if type(oc) ~= "table" then return end
        if not (oc.before or oc.individual or oc.joker_main or oc.after) then return end
        if (tonumber(G.hands) or 1) <= 0 then
            return { repetitions = 1 }
        end
    end,
}

--------------------------------------------------------------------------------
-- Hyperspace (Uncommon, $6): 1 in 3 chance to create a Black Hole when a Blind is selected
-- (must have consumable room). Black Hole is a Spectral card in this game. The roll goes
-- through the port's probability helper, so Oops! All 6s doubles the odds.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "hyperspace",
    loc_txt = {
        name = "Hyperspace",
        text = {
            "{C:green}#1# in #2#{} chance to create",
            "{C:spectral}Black Hole{} when a Blind",
            "is selected",
            "{C:inactive}(Must have room)",
        },
    },
    config = { extra = { odds = 3 } },
    rarity = 2,
    cost = 6,
    sprite = "hyperspace.png",
    negative_sprite = "hyperspace_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "unb_hyperspace")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            if not G:can_add_consumable() then return end
            local hit = SMODS.pseudorandom_probability(card, "unb_hyperspace", 1, card.ability.extra.odds, "unb_hyperspace")
            if hit and G:add_consumable("spectral_black_hole") then
                SMODS.joker_message(card, "Hyperspace!")
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mario (Rare, $10): +3 Joker slots.  Luigi (Rare, $10): +4 Joker slots.
-- `joker_slots` in `config` is one of the port's modifier keys (like h_size or hands): it is
-- read from every owned Joker's `card.ability` when the Joker capacity is worked out, so the
-- slots appear on purchase and go when the Joker is sold. They take up a slot themselves.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "mario",
    loc_txt = {
        name = "Mario",
        text = {
            "{C:attention}+#1#{} Joker slots",
        },
    },
    config = { joker_slots = 3 },
    rarity = 3,
    cost = 10,
    sprite = "mario.png",
    negative_sprite = "mario_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.joker_slots } }
    end,
}

SMODS.Joker {
    key = "luigi",
    loc_txt = {
        name = "Luigi",
        text = {
            "{C:attention}+#1#{} Joker slots",
        },
    },
    config = { joker_slots = 4 },
    rarity = 3,
    cost = 10,
    sprite = "luigi.png",
    negative_sprite = "luigi_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.joker_slots } }
    end,
}

--------------------------------------------------------------------------------
-- Link (Common, $5): X15 Mult. Gains +5 to that multiplier each time a Boss Blind is
-- defeated. The boss test is the one Infinity uses (blind_index 3 is the boss).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "link",
    loc_txt = {
        name = "Link",
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "Gains {X:mult,C:white}X#2#{} Mult when a",
            "{C:attention}Boss Blind{} is defeated",
        },
    },
    config = { extra = { xmult = 15, gain = 5 } },
    rarity = 1,
    cost = 5,
    sprite = "link.png",
    negative_sprite = "link_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.gain } }
    end,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.blind_defeated and not context.blueprint
            and context.port and tonumber(context.port.blind_index) == 3 then
            e.xmult = e.xmult + e.gain
            SMODS.joker_message(card, "Upgrade!")
            return
        end
        if context.joker_main then
            return { xmult = e.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Samus Aran (Common, $5): +99 Chips and X2 Mult on every hand. No scaling, no odds.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "samus",
    loc_txt = {
        name = "Samus Aran",
        text = {
            "{C:chips}+#1#{} Chips and",
            "{X:mult,C:white}X#2#{} Mult",
        },
    },
    config = { extra = { chips = 99, xmult = 2 } },
    rarity = 1,
    cost = 5,
    sprite = "samus.png",
    negative_sprite = "samus_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips, xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Kirby (Rare, $10): each time a Blind is selected he picks a random other Joker and
-- copies its ability for that round, the way Blueprint does (so Jokers that are not
-- Blueprint-compatible can't be picked, and copies never grow or consume their source).
-- The pick is stored as the target Joker's sort id, which the port saves with the run.
--------------------------------------------------------------------------------
local function unb_find_joker(sort_id)
    if not (sort_id and type(G.jokers) == "table") then return nil end
    for _, j in ipairs(G.jokers) do
        if tonumber(j._sort_id) == sort_id then return j end
    end
    return nil
end

local function unb_copy_effect(kirby, target, context)
    if target.def.blueprint_compat ~= true then return nil end
    local center = target.def.smods
    if center then
        -- Another mod joker: ask its own calculate, flagged as a copy.
        local c = {}
        for k, v in pairs(context) do c[k] = v end
        c.blueprint, c.blueprint_card = true, kirby
        return SMODS.call(center.mod, center.calculate, center, target, c)
    end
    -- A built-in joker: run its effect on the same event, the way the port's Blueprint does.
    local port = context.port
    if type(port) ~= "table" or type(target.apply_effect) ~= "function" then return nil end
    if port.event_name and type(target.matches_trigger) == "function"
        and target:matches_trigger(port.event_name, port) ~= true then return nil end
    local pb, pc, ps, pv = port.blueprint, port.blueprint_card, port._suppress_joker_apply_shake, port.VT
    port.blueprint, port.blueprint_card, port._suppress_joker_apply_shake = true, kirby, true
    target:apply_effect(port)
    port.blueprint, port.blueprint_card, port._suppress_joker_apply_shake, port.VT = pb, pc, ps, pv
    return nil
end

SMODS.Joker {
    key = "kirby",
    loc_txt = {
        name = "Kirby",
        text = {
            "Copies the ability of a",
            "random {C:attention}Joker{} each round",
        },
    },
    config = { extra = { target = false } },
    rarity = 3,
    cost = 10,
    sprite = "kirby.png",
    negative_sprite = "kirby_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.blueprint then return end
        local e = card.ability.extra
        if context.setting_blind then
            local pool = {}
            for _, j in ipairs(G.jokers) do
                if j ~= card and j.def and j.def.blueprint_compat == true then pool[#pool + 1] = j end
            end
            if #pool > 0 then
                local pick = pool[G:random("unbkirby" .. tostring(G.ante), 1, #pool)]
                e.target = tonumber(pick._sort_id) or false
                SMODS.joker_message(card, "Copy!")
            else
                e.target = false
            end
            return
        end
        local target = e.target and unb_find_joker(e.target)
        if target and target ~= card then
            return unb_copy_effect(card, target, context)
        end
    end,
}

--------------------------------------------------------------------------------
-- Donkey Kong (Legendary, $15): when a Boss Blind is defeated, creates a Negative copy of
-- the Joker to his left (its saved state comes along, like the port's Invisible Joker clone).
-- Nothing happens if he is the leftmost Joker. Never copies Eternal.
--------------------------------------------------------------------------------
local SKIP_KEYS = {
    def = true, params = true, effect_impl = true, _sort_id = true, T = true, VT = true,
    velocity = true, drag = true, hovering = true, _hover_last = true, _touch_state = true,
    children = true, parent = true, front_quads = true, back_quads = true, sprite_batch = true,
}

local function unb_clone_negative(src)
    if not G:add_joker_by_def(src.def.id, { edition = "negative", eternal = false }) then return false end
    local clone = G.jokers[#G.jokers]
    if not clone then return false end
    for k, v in pairs(src) do
        if type(v) ~= "function" and not SKIP_KEYS[k] then
            if type(v) == "table" then
                clone[k] = G.deep_copy_card_data and G:deep_copy_card_data(v) or v
            else
                clone[k] = v
            end
        end
    end
    clone.edition, clone.eternal = "negative", false
    -- A mod joker's state lives in `ability`; the copy above gave the clone its own table.
    if clone.ability then clone.effect_config = clone.ability end
    if clone.refresh_quads then clone:refresh_quads() end
    return true
end

SMODS.Joker {
    key = "donkey_kong",
    loc_txt = {
        name = "Donkey Kong",
        text = {
            "Creates a {C:purple}Negative{} copy of",
            "the {C:attention}Joker{} to its left when a",
            "{C:attention}Boss Blind{} is defeated",
        },
    },
    config = {},
    rarity = 4,
    cost = 15,
    sprite = "donkey_kong.png",
    negative_sprite = "donkey_kong_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.blind_defeated and not context.blueprint
            and context.port and tonumber(context.port.blind_index) == 3 then
            local left
            for i, j in ipairs(G.jokers) do
                if j == card then left = G.jokers[i - 1] break end
            end
            if left and left.def and left.def.id and unb_clone_negative(left) then
                SMODS.joker_message(card, "Barrel!")
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- DECKS
-- Each deck is a 72x95 card back in assets/1x (.png + .t3x, no negative version).
-- Decks that reshape the starting 52 do it in `apply`, which runs once at the start of a
-- run, before the deck is shuffled. (Bump "version" in the .json when you change one.)
--------------------------------------------------------------------------------

local UNB_SUITS = { "Clubs", "Diamonds", "Hearts", "Spades" }

--- A full 52-card list as the port's plain card tables (ranks 2-14; 11-13 are J/Q/K).
local function unb_standard_cards()
    local out = {}
    for _, suit in ipairs(UNB_SUITS) do
        for rank = 2, 14 do out[#out + 1] = { rank = rank, suit = suit } end
    end
    return out
end

local function unb_stone()
    return { rank = 2, suit = "Spades", enhancement = "stone" }
end

--------------------------------------------------------------------------------
-- Conjurer Deck: +2 hand size. Creates a random Spectral card at the end of each round.
--------------------------------------------------------------------------------
SMODS.Back {
    key = "conjurer",
    loc_txt = {
        name = "Conjurer Deck",
        text = {
            "{C:attention}+#1#{} hand size.",
            "Creates a random",
            "{C:spectral}Spectral{} card each {C:attention}round{}",
        },
    },
    config = { hand_size = 2 },
    sprite = "conjurer_back.png",
    loc_vars = function(self, info_queue, back)
        return { vars = { back.effect.config.hand_size } }
    end,
    calculate = function(self, back, context)
        if context.end_of_round and not context.game_over then
            if not G:can_add_consumable() then return end
            local id = G:random_consumable_id_of_kind("spectral", nil, "unbconj")
            if id then G:add_consumable(id) end
        end
    end,
}

--------------------------------------------------------------------------------
-- Vagabond Deck: Tarot cards and booster packs cost $0 in the shop. +2 consumable slots.
-- The port has no price hook for decks, so this wraps the two shop price functions once.
-- Prices that are already stored as 0 are left alone by the originals, and the wrapper only
-- acts while a Vagabond run is active, so no other deck is touched.
--------------------------------------------------------------------------------
local function unb_vagabond_active()
    return G and G.selected_deck_id == "b_unb_vagabond"
end

if Game and not Game._unb_vagabond_patched then
    Game._unb_vagabond_patched = true
    local orig_offer, orig_booster = Game.get_shop_offer_price, Game.get_shop_booster_price
    if orig_offer then
        Game.get_shop_offer_price = function(self, offer)
            if unb_vagabond_active() and type(offer) == "table" and offer.kind == "tarot" then
                return 0
            end
            return orig_offer(self, offer)
        end
    end
    if orig_booster then
        Game.get_shop_booster_price = function(self, offer)
            if unb_vagabond_active() and type(offer) == "table" and offer.pack == "arcana" then return 0 end
            return orig_booster(self, offer)
        end
    end
end

SMODS.Back {
    key = "vagabond",
    loc_txt = {
        name = "Vagabond Deck",
        text = {
            "{C:tarot}Tarot{} cards and {C:tarot}Arcana{}",
            "{C:attention}Packs{} are free.",
            "{C:attention}+#1#{} consumable slots",
        },
    },
    config = { consumable_slot = 2 },
    sprite = "vagabond_back.png",
    loc_vars = function(self, info_queue, back)
        return { vars = { back.effect.config.consumable_slot } }
    end,
}

--------------------------------------------------------------------------------
-- Stacked Deck: every scored card counts its chips twice. -1 hand per round.
-- (The extra chips are the card's rank value: 2-10 face value, J/Q/K 10, Ace 11;
-- Stone cards have no rank, so they are left out. Retriggers double again.)
--------------------------------------------------------------------------------
local function unb_nominal(rank)
    rank = tonumber(rank) or 0
    if rank == 14 then return 11 end
    if rank >= 11 then return 10 end
    return rank
end

SMODS.Back {
    key = "stacked",
    loc_txt = {
        name = "Stacked Deck",
        text = {
            "{C:chips}Chip{} value of all cards",
            "{C:attention}doubled{}. {C:blue}#1#{} hand",
        },
    },
    config = { hands = -1 },
    sprite = "stacked_back.png",
    loc_vars = function(self, info_queue, back)
        return { vars = { back.effect.config.hands } }
    end,
    calculate = function(self, back, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local data = context.other_card.card_data or {}
            if data.enhancement == "stone" then return end
            local chips = unb_nominal(context.other_card:get_id())
            if chips > 0 then return { chips = chips } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Adventurer Deck: +1 hand, +1 discard, +2 Joker slots, Telescope, $20 to start.
-- (The game starts every run with $4, so +16 makes it $20 in total.)
--------------------------------------------------------------------------------
SMODS.Back {
    key = "adventurer",
    loc_txt = {
        name = "Adventurer Deck",
        text = {
            "{C:blue}+#1#{} hand, {C:red}+#2#{} discard.",
            "{C:attention}Telescope{}, {C:money}$20{},",
            "{C:attention}+#3#{} Joker slots",
        },
    },
    config = { hands = 1, discards = 1, dollars = 16, joker_slot = 2, vouchers = { "v_telescope" } },
    sprite = "adventurer_back.png",
    loc_vars = function(self, info_queue, back)
        local c = back.effect.config
        return { vars = { c.hands, c.discards, c.joker_slot } }
    end,
}

--------------------------------------------------------------------------------
-- Faceoff Deck: 26 face cards and 26 tens.
-- Faces: two of each Jack/Queen/King in every suit (24) plus a King of Spades and a King of
-- Hearts. Tens: six of each suit (24) plus two more in Spades and Hearts.
--------------------------------------------------------------------------------
SMODS.Back {
    key = "faceoff",
    loc_txt = {
        name = "Faceoff Deck",
        text = {
            "{C:attention}26{} face cards and {C:attention}26{} 10s",
            "{C:inactive}(no other ranks){}",
        },
    },
    config = {},
    sprite = "faceoff_back.png",
    apply = function(self, back)
        if not G.deck then return end
        local cards = {}
        for _, suit in ipairs(UNB_SUITS) do
            for rank = 11, 13 do
                for _ = 1, 2 do cards[#cards + 1] = { rank = rank, suit = suit } end
            end
            for _ = 1, 6 do cards[#cards + 1] = { rank = 10, suit = suit } end
        end
        cards[#cards + 1] = { rank = 13, suit = "Spades" }
        cards[#cards + 1] = { rank = 13, suit = "Hearts" }
        cards[#cards + 1] = { rank = 10, suit = "Spades" }
        cards[#cards + 1] = { rank = 10, suit = "Hearts" }
        G.deck.cards = cards
    end,
}

--------------------------------------------------------------------------------
-- Patio Deck: every Club, every Diamond, and 26 Stone cards.
--------------------------------------------------------------------------------
SMODS.Back {
    key = "patio",
    loc_txt = {
        name = "Patio Deck",
        text = {
            "All {C:clubs}Clubs{} and {C:diamonds}Diamonds{},",
            "plus {C:attention}26{} {C:attention}Stone{} cards",
        },
    },
    config = {},
    sprite = "patio_back.png",
    apply = function(self, back)
        if not G.deck then return end
        local cards = {}
        for _, suit in ipairs({ "Clubs", "Diamonds" }) do
            for rank = 2, 14 do cards[#cards + 1] = { rank = rank, suit = suit } end
        end
        for _ = 1, 26 do cards[#cards + 1] = unb_stone() end
        G.deck.cards = cards
    end,
}

--------------------------------------------------------------------------------
-- Collector Deck: 26 random cards start as Foil (+50 Chips each).
--------------------------------------------------------------------------------
SMODS.Back {
    key = "collector",
    loc_txt = {
        name = "Collector Deck",
        text = {
            "Start with {C:attention}26{} random",
            "{C:chips}Foil{} cards",
        },
    },
    config = {},
    sprite = "collector_back.png",
    apply = function(self, back)
        if not G.deck then return end
        local cards = G.deck.cards
        local n = #cards
        -- Partial shuffle: the first 26 slots end up as 26 different random cards.
        for i = 1, math.min(26, n) do
            local j = G:random("unbcollector" .. i, i, n)
            cards[i], cards[j] = cards[j], cards[i]
            cards[i].modifier = { edition = "foil" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Hei Deck: start with 5 copies of Popcorn (they fill the 5 starting Joker slots).
--------------------------------------------------------------------------------
SMODS.Back {
    key = "hei",
    loc_txt = {
        name = "Hei Deck",
        text = {
            "Start with {C:attention}5{} bags",
            "of {C:attention}Popcorn{}",
        },
    },
    config = {},
    sprite = "hei_back.png",
    apply = function(self, back)
        for _ = 1, 5 do G:add_joker_by_def("j_popcorn") end
    end,
}

--------------------------------------------------------------------------------
-- Elevated Deck: no cards below a 5.
--------------------------------------------------------------------------------
SMODS.Back {
    key = "elevated",
    loc_txt = {
        name = "Elevated Deck",
        text = {
            "Deck has no cards below {C:attention}5{}",
            "{C:inactive}(no 2s, 3s or 4s){}",
        },
    },
    config = {},
    sprite = "elevated_back.png",
    apply = function(self, back)
        if not G.deck then return end
        local kept = {}
        for _, c in ipairs(G.deck.cards) do
            if tonumber(c.rank) >= 5 then kept[#kept + 1] = c end
        end
        G.deck.cards = kept
    end,
}

--------------------------------------------------------------------------------
-- Jockler Deck: +4 Joker slots, and 10 random cards start as Holographic (+10 Mult each).
--------------------------------------------------------------------------------
SMODS.Back {
    key = "jockler",
    loc_txt = {
        name = "Jockler Deck",
        text = {
            "{C:attention}+#1#{} Joker slots",
            "and {C:attention}10{} random",
            "{C:mult}Holographic{} cards",
        },
    },
    config = { joker_slot = 4 },
    sprite = "jockler_back.png",
    loc_vars = function(self, info_queue, back)
        return { vars = { back.effect.config.joker_slot } }
    end,
    apply = function(self, back)
        if not G.deck then return end
        local cards = G.deck.cards
        local n = #cards
        for i = 1, math.min(10, n) do
            local j = G:random("unbjockler" .. i, i, n)
            cards[i], cards[j] = cards[j], cards[i]
            cards[i].modifier = { edition = "holo" }
        end
    end,
}
