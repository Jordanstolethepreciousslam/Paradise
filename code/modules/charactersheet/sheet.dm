
// Character sheet

/datum/charsheet

	var/mob/living/carbon/human/owner = null

	var/CharSTR = 10
	var/CharDEX = 10
	var/CharINT = 10



	var/ConstSTR = 10.0
	var/ConstDEX = 10.0
	var/ConstINT = 10.0

	var/Focus = 100.0
	var/Potential = 100.0

	var/skill_dodge = 1
	var/skill_melee = 1
	var/skill_ranged = 1
	var/skill_engi = 1
	var/skill_med = 1

	var/const_dodge = 1.0
	var/const_melee = 1.0
	var/const_ranged = 1.0
	var/const_engi = 1.0
	var/const_med = 1.0

	var/TacBar = 20.0
	var/TacBarMax = 20.0

	var/list/vulnerableTo = new/list()

/datum/charsheet/proc/adjustSTR(amt = 0, time = 0)
	if(amt == 0)
		return
	if(time > 0)
		addtimer(CALLBACK(src, PROC_REF(adjustSTR), -amt, 0), time SECONDS)
	CharSTR += amt
/datum/charsheet/proc/adjustDEX(amt = 0, time = 0)
	if(amt == 0)
		return
	if(time > 0)
		addtimer(CALLBACK(src, PROC_REF(adjustDEX), -amt, 0), time SECONDS)
	CharDEX += amt
	to_chat(world, "[owner] got DEX adjusted by [amt]")
/datum/charsheet/proc/adjustINT(amt = 0, time = 0)
	if(amt == 0)
		return
	if(time > 0)
		addtimer(CALLBACK(src, PROC_REF(adjustINT), -amt, 0), time SECONDS)
	CharINT += amt

	//if(time > 0)
	//	addtimer(CALLBACK(src, PROCREF(adjustSTR), -amt, 0), time SECONDS)


/datum/charsheet/proc/train(skill = "", amt = 1.0)
	if(amt > Potential && amt > 0)
		return
	Potential -= amt
	switch(skill)
		if("STR")
			ConstSTR += 0.02 * amt
		if("DEX")
			ConstDEX += 0.02 * amt
		if("INT")
			ConstINT += 0.02 * amt
		if("DODGE")
			const_dodge += 0.02 * amt
		if("MELEE")
			const_melee += 0.02 * amt
		if("RANGED")
			const_ranged += 0.02 * amt
		if("ENGI")
			const_engi += 0.02 * amt
		if("MED")
			const_med += 0.02 * amt
		else
			return
	to_chat(owner, "You improved your [skill] by [0.02 * amt] , you have lost [amt]] potential and now have [Potential]")


/datum/charsheet/proc/replenish()
	CharSTR = floor(ConstSTR)
	CharSTR = floor(ConstDEX)
	CharSTR = floor(ConstINT)

	skill_dodge = floor(const_dodge)
	skill_melee = floor(const_melee)
	skill_ranged = floor(const_ranged)
	skill_engi = floor(const_engi)
	skill_med = floor(const_med)

	Potential = 100.0

	updatebody(CharSTR, CharDEX, CharINT)










//datum/charsheet/New()


/datum/charsheet/proc/updatebody()
	var/strmod = (ConstSTR - 10) * 0.03
	owner.physiology.brute_mod = (1 - strmod)
	owner.physiology.burn_mod = (1 - strmod)
	owner.physiology.stamina_mod = (1 - strmod)
	owner.physiology.tox_mod = (1 - strmod)
	owner.physiology.stun_mod = (1 - strmod)

/datum/charsheet/proc/TransferTo(mob/living/carbon/human/recipient)
	owner = recipient

/datum/charsheet/proc/setTacBarMax()
	var/dexmod = (CharDEX - 10) * 5
	var/dodgemod = (skill_dodge * 10)
	TacBarMax = (10.0 + dexmod + dodgemod)


/datum/charsheet/proc/updateTacBar()
	if(TacBar < TacBarMax)
		TacBar += TacBarMax * 0.01
	if(TacBar > TacBarMax)
		TacBar -= TacBarMax * 0.005
	owner.update_hud_tac()

/datum/charsheet/proc/adjustTacBar(amt)
	TacBar += amt
	owner.update_hud_tac()

/datum/charsheet/proc/updateFocus()
	Focus += (100 - Focus) * 0.1


/datum/charsheet/proc/failedDodge(datum/charsheet/attacker, obj/item/projectile/boolet, bonus = 0)
	var/INTadv = 0
	if(attacker in vulnerableTo)
		INTadv = attacker.CharINT - CharINT
	var/attack = bonus + attacker.CharDEX + INTadv + (attacker.skill_ranged * 2) + (boolet.precision - 10)
	var/defence = CharDEX + skill_dodge * 2
	to_chat(world, "[attacker.owner.name] rolls ranged against [owner.name], attacker stat = [attack],  defender stat = [defence], int advantage = [INTadv]")
	if(attack > defence)
		train("DEX", 1)
		train("DODGE", 1)
		return TRUE
	var/DEXadv = (CharDEX - attacker.CharDEX - INTadv) * 0.02
	var/dodgeadv = (skill_dodge - attacker.skill_ranged - INTadv) * 1.0
	var/TacDamage = (max(boolet.damage, boolet.precision * 2) - dodgeadv) * (1 - DEXadv)
	if(TacBar > TacDamage && TacDamage > 0)
		if(TacDamage > 0)
			adjustTacBar(-(TacDamage))
		to_chat(world, "but misses dealing [TacDamage] tac damage instead, [TacBar] remains")
		return FALSE
	else
		return TRUE


/datum/charsheet/proc/failedDodgeMelee(datum/charsheet/attacker, obj/item/sord, bonus = 0)
	var/INTadv = 0
	if(attacker in vulnerableTo)
		INTadv = attacker.CharINT - CharINT
	to_chat(world, "[attacker.owner.name] rolls melee against [owner.name], attacker dex = [attacker.CharDEX], attacker skill = [attacker.skill_melee], defender dex = [CharDEX], defender dodge = [skill_dodge], int advantage = [INTadv]")

	var/attack = bonus + attacker.CharDEX + INTadv + (attacker.skill_ranged * 2)
	var/defence = CharDEX + skill_dodge * 2
	if(attack > defence)
		train("DEX", 1)
		train("DODGE", 1)
		return TRUE

	var/DEXadv = (CharDEX - attacker.CharDEX - INTadv) * 0.02
	var/dodgeadv = (skill_dodge - attacker.skill_melee * 4 - INTadv) * 1.0
	var/TacDamage = (sord.force - dodgeadv) * (1 - DEXadv)
	if(TacBar > TacDamage && sord.force > 0)
		if(TacDamage > 0)
			adjustTacBar(-(TacDamage))
		to_chat(world, "but misses dealing [TacDamage] tac damage instead, [TacBar] remains")
		return FALSE
	else
		return TRUE

/datum/charsheet/proc/failedGenericDodge(value, mod = 1.0)
	to_chat(world, "[owner.name] rolls dodge agains value [value] and modifier [mod]")
	if(CharDEX + skill_dodge * 2 > value * mod && TacBar > value * mod)
		adjustTacBar(-value * 2)
		to_chat(world, "[owner.name] dodges something, suffering [value * 2] tac damage instead")
		return FALSE
	return TRUE

/datum/charsheet/proc/addVulnerable(datum/charsheet/attacker)
	var/INTadv = (attacker.CharINT - CharINT)
	if(!do_after(attacker.owner, 10 SECONDS - max(4, INTadv), target = owner))
		return
	if(INTadv > 0 && Focus > 20 && !(attacker in vulnerableTo))
		Focus -= 75 * max(0.25, (1 - INTadv * 0.05))
		vulnerableTo.Add(attacker)
		addtimer(CALLBACK(src, PROC_REF(removeVulnerable), attacker), (INTadv * (INTadv * 2)) SECONDS)
		to_chat(attacker.owner, "You gain [INTadv] advantage against [owner.name], for [INTadv * (INTadv * 2)] seconds")


/datum/charsheet/proc/removeVulnerable(datum/charsheet/attacker)
	vulnerableTo.Remove(attacker)
	to_chat(world, "[attacker.owner.name] loses advantage against [owner.name]")



/datum/charsheet/proc/update()
	updateTacBar()
	setTacBarMax()
	updateFocus()
	owner.physiology.melee_bonus = (CharSTR - 10) + (skill_melee * 2)

/mob/living/carbon/human/verb/randomizeATT()
	set name = "Randomize Attributes"
	set category = "IC"

	CharSheet.CharSTR = rand(8, 16)
	CharSheet.CharDEX = rand(8, 16)
	CharSheet.CharINT = rand(8, 16)

	CharSheet.skill_dodge = rand(1, 6)
	CharSheet.skill_melee = rand(1, 6)
	CharSheet.skill_ranged = rand(1, 6)
	CharSheet.skill_engi = rand(1, 6)
	CharSheet.skill_med = rand(1, 6)

/mob/living/carbon/human/AltClickOn(A)
	if(ishuman(A) && do_after(src, 1 SECONDS, target = A) && a_intent == INTENT_HARM)
		var/mob/living/carbon/human/clicked = A
		var/datum/charsheet/victim = clicked.CharSheet
		victim.addVulnerable(CharSheet)
	if(a_intent == INTENT_GRAB && !incapacitated() && !IsSlowed() && !resting)
		playsound(loc, 'sound/effects/pressureplate.ogg', 50, 1, 1)
		if(do_after(src, 1 SECONDS, target = A))
			var/range =  1 + ceil((CharSheet.CharSTR - 10)/4)
			throw_at(A, range, 1, FALSE)
	..()

/mob/living/carbon/human/verb/restoreTacBar()
	set name = "Restore Tac"
	set category = "IC"
	CharSheet.TacBar = CharSheet.TacBarMax
	to_chat(src, "You restore your tac bar to your max value of [CharSheet.TacBarMax]")

/mob/living/carbon/human/verb/newroundattribute()
	set name = "Simulate New Round"
	set category = "IC"
	CharSheet.replenish()
	to_chat(src, "Winds of time replenish you, you restore your potential and bloom")
	new /obj/item/book/codex_gigas(loc)
	new /obj/item/book/manual/wiki/engineering_construction(loc)
	new /obj/item/book/manual/medical_cloning(loc)
	CharSheet.updatebody()

/obj/item/book/codex_gigas/read_book(mob/living/carbon/human/reader)
	reader.CharSheet.train("INT", 2)

/obj/item/book/manual/wiki/engineering_construction/read_book(mob/living/carbon/human/reader)
	reader.CharSheet.train("ENGI", 2)

/obj/item/book/manual/medical_cloning/read_book(mob/living/carbon/human/reader)
	reader.CharSheet.train("MED", 2)




/mob/living/carbon/human/proc/abstractProj(atom/A)
	changeNext_move(CLICK_CD_RANGE)
	changeNext_move(CLICK_CD_MELEE)
	var/turf/T = get_turf(src)
	var/turf/U = get_turf(A)

	var/obj/item/projectile/beam/LE = new /obj/item/projectile/intent(loc)

	LE.icon = null
//	LE.icon_state = "eyelasers"
	LE.hitsound = null

	LE.firer = src
	LE.firer_source_atom = src
	LE.def_zone = ran_zone(zone_selected)
	LE.original = A
	LE.current = T
	LE.yo = U?.y - T?.y
	LE.xo = U?.x - T?.x
	LE.fire()


/obj/item/projectile/intent
	name = "intent"
	hitscan = TRUE
	range = 1
	nodamage = TRUE
	hitsound = FALSE
	suppressed = TRUE
	damage = 0

/obj/item/projectile/intent/on_hit(atom/target)
	if(ishuman(target))
		target.attack_hand(firer)
	return
