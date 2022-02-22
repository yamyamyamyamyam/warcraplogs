//
//  main.swift
//  warcraplogs
//
//  Created by big dam yam on 2/17/22.
//

import Foundation
import JavaScriptKit

let document = JSObject.global.document
let fileSelect = document.getElementById("log-select").object!
let outputArea = document.getElementById("output-area").object!
let juiceButton = document.getElementById("juicebutton").object!
let playerNameInputForm = document.getElementById("playername-input").object!
let dpsGainInputForm = document.getElementById("dpsgain-input").object!
let debugOutputArea = document.getElementById("debug-out-area").object!
let saveLogButtonArea = document.getElementById("savelogbutton").object!

func annoyingTimeSince(earliestTime: String, latestTime: String) -> Double {
    let earliestComponents = earliestTime.split(separator: ":")
    let latestComponents = latestTime.split(separator: ":")
    let earliestHours = Double(earliestComponents[0])!
    let earliestMinutes = Double(earliestComponents[1])!
    let earliestSeconds = Double(earliestComponents[2])!
    let earliestMilliseconds = Double(earliestTime.components(separatedBy: ".")[1])!
    let totalEarliestSeconds = earliestHours * 3600 + earliestMinutes * 60 + earliestSeconds + earliestMilliseconds / 1000
    let latestHours = Double(latestComponents[0])!
    let latestMinutes = Double(latestComponents[1])!
    let latestSeconds = Double(latestComponents[2])!
    let latestMilliseconds = Double(latestTime.components(separatedBy: ".")[1])!
    let totalLatestSeconds = latestHours * 3600 + latestMinutes * 60 + latestSeconds + latestMilliseconds / 1000
    if totalEarliestSeconds > totalLatestSeconds {
        return totalLatestSeconds + (86400 - totalEarliestSeconds)
    } else {
        return totalLatestSeconds - totalEarliestSeconds
    }
}

let fileSelectHandler = JSClosure { arguments in
    let file = fileSelect.files.item(0)
    handleFileSelect(file)
    return .undefined
}

let juiceClickHandler = JSClosure { arguments in
	handleJuiceClick()
	return .undefined
}

let saveClickHandler = JSClosure { arguments in
	handleSaveClick()
	return .undefined
}

class ContentWriter: TextOutputStream {
    private(set) var content: String = ""
    func write(_ string: String) {
        content += string
    }
}

func handleFileSelect(_ file: JSValue) {
    JSPromise(file.text().object!)!.then { value in
        let fileName = file.name.string!
		outputArea.innerHTML = .string("""
		        <div>
		            Whose parse you tryna juice?
		        </div>
		        """)
		print("reached here")
		initializeData(fileContents: value.string!)
		oldFileString = value.string!
		print("initialized data")
	    for damageInstance in damageInstances {
	        let instanceInformation = damageInstance.value
	        let source = instanceInformation.sourceName
	        if instanceInformation.sourceFlags.contains("0x5") {
	            sourceSet.insert(source)
	        }
	    }
		let sourceString = sourceSet.reduce("", {return $0.appending("\($1)<br>")})
		print(sourceString)
		outputArea.innerHTML = .string(sourceString)
        //logSelected(file: value.string!, playerNameInput: "Draklian-Faerlina", juiceFactorInput: "200")
        let baseName = String(fileName.split(separator: ".").dropLast().joined(separator: "."))
        var writer = ContentWriter()
        return JSValue.undefined
    }
    .catch { error in
        return JSValue.undefined
    }
}

func handleJuiceClick() {
    playerName = playerNameInputForm.value.string!
    juiceFactor = dpsGainInputForm.value.string!
	print(playerName)
	print(juiceFactor)
    print("juicing")
    getPlayerDPSEvents(playerName: playerName)
    fillPlayerAbilityStatsStorage()
    createModifiedDamageEvents()
    composeNewFileString(oldString: oldFileString)
}

func handleSaveClick() {
	var pom = document.createElement("a")
	var characterSet = NSMutableCharacterSet.alphanumerics
	characterSet.insert(charactersIn: "-_.!~*'()")
	pom.setAttribute("href", "data:text/plain;charset=utf-8," + newFileString.addingPercentEncoding(withAllowedCharacters: characterSet)!)
	pom.setAttribute("download", "newLog.txt")
	pom.click()
}

struct DamageEvent {
    let timestamp: String
    let type: String
    let sourceName: String
    let sourceFlags: String
    let spellName: String
    let damageAmount: Int
    let unmitigatedAmount: Int
    let didCrit: Int?
    let lineNumber: Int
    let didGlance: Int?
    let partialResistAmount: Int
    var changeEvent: ChangeEvent?
}

struct ChangeEvent {
    let changeType: String
    let oldDamage: Int
    let newDamage: Int
    let stdDev: Double
    let multiplier: Double
}

fileSelect.addEventListener!("change", fileSelectHandler)
juiceButton.addEventListener!("click", juiceClickHandler)
saveLogButtonArea.addEventListener!("click", saveClickHandler)

var oldFileString = ""
var actionSet = Set<String>()
let interestedActionTypes = ["SWING_DAMAGE_LANDED", "RANGE_DAMAGE", "SWING_DAMAGE", "SPELL_DAMAGE"]
var damageInstances = [Int : DamageEvent]()
var damageInstancesByPlayer = [String : [String : [DamageEvent]]]()
var damageInstancesToModify = [DamageEvent]()
let abilityWhitelist = ["\"Shadow Bolt\"", "\"Arcane Blast\"", "\"Starfire\"", "\"Lightning Bolt\"", "\"Heroic Strike\"", "\"Steady Shot\"", "\"Arcane Shot\"", "\"Shoot\"", "\"Auto Shot\"", "", "\"Shred\"", "\"Windfury Attack\"", "\"Sinister Strike\"", "\"Mind Blast\"", "\"Frostbolt\"", "\"Multi-Shot\"", "\"Mortal Strike\""]
let resistableSpells = ["\"Shadow Bolt\"", "\"Arcane Blast\"", "\"Starfire\"", "\"Lightning Bolt\"", "\"Mind Blast\"", "\"Frostbolt\""]
let critManipulableSpells = ["\"Mind Blast\"", "", "\"Sinister Strike\"", "\"Starfire\""]

var selectedPlayerDamageEvents = [DamageEvent]()
let dateFormatter = DateFormatter()
//dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//dateFormatter.dateFormat = "HH:mm:ss.SSS"
//	dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
//dateFormatter.setLocalizedDateFormatFromTemplate("")
var latestTime = "00:00:00.000"
var earliestTime = "23:59:59.999"
var maxDamage = 0
var totalDamage = 0
var playerDamageTypes = Set<String>()
var playerDamageDictionary = [String : [String : [DamageEvent]]]()
var playerName: String = ""
var juiceFactor: String = ""
var modificationsSummaryString = ""

var sourceSet = Set<String>()

var numEvents: Int = 0
var timeElapsed: TimeInterval = 0.0
var unJuicedDPS: Double = 0.0
var juicedDPS: Double = 0.0
var requiredDamage: Double = 0.0
var damageToJuice: Int = 0

var playerAbilityStatsStorage = [String : [String : Any]]()

var damageEventsCount: Int = 0
var damageJuiced: Int = 0
var damageLowered: Int = 0
var eventsAlreadyChecked = [Int]()
var modifiedDamageEvents = [DamageEvent]()

var indexCount: Int = 0
var indexArray: Array<Int> = [0]
var shuffledArray: Array<Int> = [0]
var randomIndex: Int = 0

var newFileString = ""

func initializeData(fileContents: String) {
    var currentLineNumber = 0
    let tokenizedFile = fileContents.components(separatedBy: .newlines).filter({$0 != ""})
    for line in tokenizedFile {
        let components = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: false)
        //let components = lineAsString.components(separatedBy: " ")
        //first element always day, second element always timestamp, third element subevent? fourth element what we want
        let action = components[3].components(separatedBy: ",")
        let actionType = action[0]
        if interestedActionTypes.contains(actionType) {
            let damageEvent: DamageEvent
            if actionType == "SPELL_DAMAGE" || actionType == "RANGE_DAMAGE" {
                damageEvent = DamageEvent(timestamp: String(components[1]),
                                          type: actionType,
                                          sourceName: action[2].replacingOccurrences(of: "\"", with: ""),
                                          sourceFlags: action[3],
                                          spellName: action[10],
                                          damageAmount: Int(action[28])!,
                                          unmitigatedAmount: Int(action[29])!,
                                          didCrit: Int(action[35]),
                                          lineNumber: currentLineNumber,
                                          didGlance: Int(action[36]),
                                          partialResistAmount: Int(action[32])!,
                                          changeEvent: nil)
            } else {
                damageEvent = DamageEvent(timestamp: String(components[1]),
                                          type: actionType,
                                          sourceName: action[2].replacingOccurrences(of: "\"", with: ""),
                                          sourceFlags: action[3],
                                          spellName: "",
                                          damageAmount: Int(action[25])!,
                                          unmitigatedAmount: Int(action[26])!,
                                          didCrit: Int(action[32]),
                                          lineNumber: currentLineNumber,
                                          didGlance: Int(action[33]),
                                          partialResistAmount: Int(action[29])!,
                                          changeEvent: nil)
            }
            if abilityWhitelist.contains(damageEvent.spellName) && damageEvent.sourceFlags.contains("0x5") {
                damageInstancesToModify.append(damageEvent)
            }
            damageInstances[currentLineNumber] = damageEvent
            let sourceName = action[2].replacingOccurrences(of: "\"", with: "")
            if damageInstancesByPlayer[sourceName] == nil {
                var newSpellEventMap = [String : [DamageEvent]]()
                newSpellEventMap[damageEvent.spellName] = [damageEvent]
                damageInstancesByPlayer[sourceName] = newSpellEventMap
            } else {
                var spellEventMap = damageInstancesByPlayer[sourceName]!
                if spellEventMap[damageEvent.spellName] == nil {
                    let events = [damageEvent]
                    spellEventMap[damageEvent.spellName] = events
                } else {
                    var events = spellEventMap[damageEvent.spellName]!
                    events.append(damageEvent)
                    spellEventMap[damageEvent.spellName] = events
                }
                damageInstancesByPlayer[sourceName] = spellEventMap
            }
        }
        currentLineNumber += 1
    }
}

func getPlayerDPSEvents(playerName: String) {
    let playerDamageEvents = damageInstancesByPlayer[playerName]!
    for playerDamageEventKey in playerDamageEvents.keys {
        let values = playerDamageEvents[playerDamageEventKey]!
        for playerDamageEvent in values {
            let time = playerDamageEvent.timestamp
            if time < earliestTime {
                earliestTime = time
            }
			if time > latestTime || time < earliestTime {
			    latestTime = time
			}
            let spellName = playerDamageEvent.spellName
            if playerDamageEvent.sourceName == playerName && playerDamageEvent.type != "SWING_DAMAGE_LANDED" {
                selectedPlayerDamageEvents.append(playerDamageEvent)
                if playerDamageEvent.damageAmount > maxDamage {
                    maxDamage = playerDamageEvent.damageAmount
                }
                totalDamage += playerDamageEvent.damageAmount
                playerDamageTypes.insert(spellName)
            }
        }
    }
    numEvents = selectedPlayerDamageEvents.count
    timeElapsed = annoyingTimeSince(earliestTime: earliestTime, latestTime: latestTime)
    unJuicedDPS = Double(totalDamage) / timeElapsed
    print("\(numEvents) events, max damage of \(maxDamage), total damage \(totalDamage), over \(timeElapsed) elapsed time, \(Double(totalDamage) / timeElapsed) DPS")
    print(" ")
    juicedDPS = unJuicedDPS + Double(juiceFactor)!
    requiredDamage = juicedDPS * timeElapsed
    damageToJuice = Int(requiredDamage - Double(totalDamage))
    print("Need to juice \(damageToJuice) damage")
    print("Damage breakdown:")
}

func fillPlayerAbilityStatsStorage() {
	var debugString = ""
    for player in damageInstancesByPlayer.keys {
		debugString += player + "<br>"
        print("\(player)")
        let currentPlayerDamageDictionary = damageInstancesByPlayer[player]!
        for damageType in currentPlayerDamageDictionary.keys {
            let values = currentPlayerDamageDictionary[damageType]!
            let totalDamage = values.reduce(0, {x, y in
                x + y.damageAmount
            })
            let crits = values.filter({return $0.didCrit == 1})
            let critMultipliers = crits.map({return (Double($0.damageAmount) / Double($0.unmitigatedAmount))})
            let critMultiplier = critMultipliers.reduce(0.0, +) / Double(critMultipliers.count)
            let meanDamage = Double(totalDamage) / Double(values.count)
            let differencesFromMean = values.map({return Double($0.damageAmount) - meanDamage})
            let squaredDifferencesFromMean = differencesFromMean.map({return pow($0, 2)})
            let sumOfSquaredDifferences = squaredDifferencesFromMean.reduce(0, +)
            let variance = sumOfSquaredDifferences / Double(values.count)
            let standardDeviation = sqrt(variance)
			debugString += "\(damageType): \(values.count) instances, \(meanDamage) average damage, \(standardDeviation) stdDev, avg crit multiplier \(critMultiplier)<br>"
            print("\(damageType): \(values.count) instances, \(meanDamage) average damage, \(standardDeviation) stdDev, avg crit multiplier \(critMultiplier)")
            let stats: [String : Any] = ["SD" : standardDeviation,
                                         "count" : values.count,
                                         "mean" : meanDamage,
                                         "critMultiplier" : critMultiplier]
            playerAbilityStatsStorage["\(player)-\(damageType)"] = stats
        }
        debugString += "<br><br>"
    }
	debugOutputArea.innerHTML = .string(debugString)
}

func changeResistOrGlance(alterableEventCandidate: DamageEvent) -> Bool {
    let raiseOrLower = alterableEventCandidate.sourceName == playerName ? 1 : -1
    if raiseOrLower == 1 && damageJuiced >= damageToJuice {
        return false
    } else if raiseOrLower == -1 && damageLowered <= (damageToJuice * -1) {
        return false
    }
    if raiseOrLower == 1 {
        if alterableEventCandidate.partialResistAmount > 0 {
            //undo partial resist
            let newDamageAmount = alterableEventCandidate.damageAmount + alterableEventCandidate.partialResistAmount
            let newDamageEvent = DamageEvent(timestamp: alterableEventCandidate.timestamp,
                                             type: alterableEventCandidate.type,
                                             sourceName: alterableEventCandidate.sourceName,
                                             sourceFlags: alterableEventCandidate.sourceFlags,
                                             spellName: alterableEventCandidate.spellName,
                                             damageAmount: newDamageAmount,
                                             unmitigatedAmount: alterableEventCandidate.unmitigatedAmount,
                                             didCrit: alterableEventCandidate.didCrit,
                                             lineNumber: alterableEventCandidate.lineNumber,
                                             didGlance: alterableEventCandidate.didGlance,
                                             partialResistAmount: 0,
                                             changeEvent: ChangeEvent(changeType: "partialResist", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamageAmount, stdDev: 0.0, multiplier: 0.0))
            modifiedDamageEvents.append(newDamageEvent)
			modificationsSummaryString += "Undid a partial resist by \(alterableEventCandidate.sourceName)'s \(alterableEventCandidate.spellName) at \(alterableEventCandidate.timestamp). Old damage was \(alterableEventCandidate.damageAmount), new damage is \(newDamageAmount)<br>"
            let amountDamageAdded = newDamageAmount - alterableEventCandidate.damageAmount
            damageJuiced += amountDamageAdded
            return true
        } else if alterableEventCandidate.didGlance != nil {
            //undo glancing blow
            let glanceModifier = Float.random(in: 0.0..<0.25)
            let oldDamageAmount = Float(alterableEventCandidate.damageAmount)
            let newDamageAmount = Int(oldDamageAmount + (oldDamageAmount * glanceModifier))
            //let newDamageAmount = alterableEventCandidate.damageAmount + alterableEventCandidate.partialResistAmount
            let newDamageEvent = DamageEvent(timestamp: alterableEventCandidate.timestamp,
                                             type: alterableEventCandidate.type,
                                             sourceName: alterableEventCandidate.sourceName,
                                             sourceFlags: alterableEventCandidate.sourceFlags,
                                             spellName: alterableEventCandidate.spellName,
                                             damageAmount: newDamageAmount,
                                             unmitigatedAmount: alterableEventCandidate.unmitigatedAmount,
                                             didCrit: alterableEventCandidate.didCrit,
                                             lineNumber: alterableEventCandidate.lineNumber,
                                             didGlance: nil,
                                             partialResistAmount: 0,
                                             changeEvent: ChangeEvent(changeType: "glanceUndo", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamageAmount, stdDev: 0.0, multiplier: 0.0))
            modifiedDamageEvents.append(newDamageEvent)
            let amountDamageAdded = newDamageAmount - alterableEventCandidate.damageAmount
            damageJuiced += amountDamageAdded
			modificationsSummaryString += "Undid a glancing blow by \(alterableEventCandidate.sourceName) at \(alterableEventCandidate.timestamp). Old damage was \(alterableEventCandidate.damageAmount), new damage is \(newDamageAmount)<br>"
			return true
        } else {
            return false
        }
    } else {
        if alterableEventCandidate.partialResistAmount > 0 {
            return false
        } else if alterableEventCandidate.didGlance != nil {
            return false
        } else {
            //if spell, resist, if melee, glance
            if alterableEventCandidate.spellName == "" {
                //glance
                let glanceModifier = Float.random(in: 0.0..<0.25)
                let oldDamageAmount = Float(alterableEventCandidate.damageAmount)
                let newDamageAmount = Int(oldDamageAmount - (oldDamageAmount * glanceModifier))
                //let newDamageAmount = alterableEventCandidate.damageAmount + alterableEventCandidate.partialResistAmount
                let newDamageEvent = DamageEvent(timestamp: alterableEventCandidate.timestamp,
                                                 type: alterableEventCandidate.type,
                                                 sourceName: alterableEventCandidate.sourceName,
                                                 sourceFlags: alterableEventCandidate.sourceFlags,
                                                 spellName: alterableEventCandidate.spellName,
                                                 damageAmount: newDamageAmount,
                                                 unmitigatedAmount: alterableEventCandidate.unmitigatedAmount,
                                                 didCrit: alterableEventCandidate.didCrit,
                                                 lineNumber: alterableEventCandidate.lineNumber,
                                                 didGlance: 1,
                                                 partialResistAmount: 0,
                                                 changeEvent: ChangeEvent(changeType: "glanceDo", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamageAmount, stdDev: 0.0, multiplier: 0.0))
                modifiedDamageEvents.append(newDamageEvent)
                let amountDamageReduced = newDamageAmount - alterableEventCandidate.damageAmount
                damageLowered += amountDamageReduced
				modificationsSummaryString += "Added a glancing blow by \(alterableEventCandidate.sourceName) at \(alterableEventCandidate.timestamp). Old damage was \(alterableEventCandidate.damageAmount), new damage is \(newDamageAmount)<br>"
				return true
            } else if resistableSpells.contains(alterableEventCandidate.spellName) {
                //partial resist
                let partialResistAmount = Int.random(in: 0..<3) + 1
                let resistFraction = (Double(partialResistAmount) * Double(25)) / 100.0
                let damageSubtrahend = resistFraction * Double(alterableEventCandidate.unmitigatedAmount)
                let newDamageAmount = Int(Double(alterableEventCandidate.damageAmount) - damageSubtrahend)
                let newDamageEvent = DamageEvent(timestamp: alterableEventCandidate.timestamp,
                                                 type: alterableEventCandidate.type,
                                                 sourceName: alterableEventCandidate.sourceName,
                                                 sourceFlags: alterableEventCandidate.sourceFlags,
                                                 spellName: alterableEventCandidate.spellName,
                                                 damageAmount: newDamageAmount,
                                                 unmitigatedAmount: alterableEventCandidate.unmitigatedAmount,
                                                 didCrit: alterableEventCandidate.didCrit,
                                                 lineNumber: alterableEventCandidate.lineNumber,
                                                 didGlance: nil,
                                                 partialResistAmount: Int(damageSubtrahend),
                                                 changeEvent: ChangeEvent(changeType: "addResist", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamageAmount, stdDev: 0.0, multiplier: 0.0))
                modifiedDamageEvents.append(newDamageEvent)
                damageLowered -= Int(damageSubtrahend)
				modificationsSummaryString += "Added a partial resist of \(alterableEventCandidate.sourceName)'s \(alterableEventCandidate.spellName) at \(alterableEventCandidate.timestamp). Old damage was \(alterableEventCandidate.damageAmount), new damage is \(newDamageAmount)<br>"
				return true
            } else {
                return false
            }
        }
    }
    return false
}

func raiseOrLowerDamageRoll(alterableEventCandidate: DamageEvent) -> Bool {
    let eventDamage = Double(alterableEventCandidate.damageAmount)
    if alterableEventCandidate.type == "SWING_DAMAGE_LANDED" {
        return false
    }
    let raiseOrLower = alterableEventCandidate.sourceName == playerName ? 1 : -1
    if raiseOrLower == 1 && damageJuiced >= damageToJuice {
        return false
    } else if raiseOrLower == -1 && damageLowered <= (damageToJuice * -1) {
        return false
    }
    let eventTypeStdDev = playerAbilityStatsStorage["\(alterableEventCandidate.sourceName)-\(alterableEventCandidate.spellName)"]!["SD"] as! Double
    let eventMean = playerAbilityStatsStorage["\(alterableEventCandidate.sourceName)-\(alterableEventCandidate.spellName)"]!["mean"] as! Double
    if abs(eventDamage - eventMean) <= eventTypeStdDev {
        if (eventDamage - eventMean) > 0 && raiseOrLower == 1 {
            return false
        }
        if (eventDamage - eventMean) < 0 && raiseOrLower == -1 {
            return false
        }
        let multiplier = Double.random(in: 0.5..<1.5)
        let addend = Int(multiplier * eventTypeStdDev) * raiseOrLower
        let unmitigatedAddend = Int((Double(alterableEventCandidate.unmitigatedAmount) / Double(alterableEventCandidate.damageAmount)) * Double(addend)) * raiseOrLower
        let newDamageEvent = DamageEvent(timestamp: alterableEventCandidate.timestamp,
                                         type: alterableEventCandidate.type,
                                         sourceName: alterableEventCandidate.sourceName,
                                         sourceFlags: alterableEventCandidate.sourceFlags,
                                         spellName: alterableEventCandidate.spellName,
                                         damageAmount: alterableEventCandidate.damageAmount + addend,
                                         unmitigatedAmount: alterableEventCandidate.unmitigatedAmount + unmitigatedAddend,
                                         didCrit: alterableEventCandidate.didCrit,
                                         lineNumber: alterableEventCandidate.lineNumber,
                                         didGlance: alterableEventCandidate.didGlance,
                                         partialResistAmount: alterableEventCandidate.partialResistAmount,
                                         changeEvent: ChangeEvent(changeType: "damageRoll", oldDamage: alterableEventCandidate.damageAmount, newDamage: alterableEventCandidate.damageAmount + addend, stdDev: eventTypeStdDev, multiplier: multiplier))
        modifiedDamageEvents.append(newDamageEvent)
		modificationsSummaryString += "Modified the damage roll of \(alterableEventCandidate.sourceName)'s \(alterableEventCandidate.spellName) at \(alterableEventCandidate.timestamp). Old damage was \(alterableEventCandidate.damageAmount), new damage is \(alterableEventCandidate.damageAmount + addend)<br>"
        let damageChange = newDamageEvent.damageAmount - alterableEventCandidate.damageAmount
        if damageChange < 0 {
            damageLowered += damageChange
        } else {
            damageJuiced += damageChange
        }
        if alterableEventCandidate.type == "SWING_DAMAGE" {
            var swingDamageLandedEventFound = false
            var nextIndexToCheck = randomIndex + 1
            while !swingDamageLandedEventFound, nextIndexToCheck < damageInstancesToModify.count {
                let candidateEvent = damageInstancesToModify[nextIndexToCheck]
                if candidateEvent.type == "SWING_DAMAGE_LANDED" && candidateEvent.sourceName == alterableEventCandidate.sourceName && candidateEvent.damageAmount == alterableEventCandidate.damageAmount {
                    let newDamageEvent = DamageEvent(timestamp: candidateEvent.timestamp,
                                                     type: candidateEvent.type,
                                                     sourceName: candidateEvent.sourceName,
                                                     sourceFlags: candidateEvent.sourceFlags,
                                                     spellName: candidateEvent.spellName,
                                                     damageAmount: candidateEvent.damageAmount + addend,
                                                     unmitigatedAmount: candidateEvent.unmitigatedAmount + unmitigatedAddend,
                                                     didCrit: candidateEvent.didCrit,
                                                     lineNumber: candidateEvent.lineNumber,
                                                     didGlance: candidateEvent.didGlance,
                                                     partialResistAmount: candidateEvent.partialResistAmount,
                                                     changeEvent: ChangeEvent(changeType: "swinglandedcorrection", oldDamage: alterableEventCandidate.damageAmount, newDamage: alterableEventCandidate.damageAmount + addend, stdDev: eventTypeStdDev, multiplier: multiplier))
                    modifiedDamageEvents.append(newDamageEvent)
                    eventsAlreadyChecked.append(nextIndexToCheck)
                    swingDamageLandedEventFound = true
                } else {
                    nextIndexToCheck += 1
            }
        }
        }
        return true
    } else {
        return false
    }
}

func makeOrUnMakeCrit(alterableEventCandidate: DamageEvent) -> Bool {
    let raiseOrLower = alterableEventCandidate.sourceName == playerName ? 1 : -1
    if raiseOrLower == 1 && damageJuiced >= damageToJuice {
        return false
    } else if raiseOrLower == -1 && damageLowered <= (damageToJuice * -1) {
        return false
    }
    if raiseOrLower == 1 {
        if Int.random(in: 0..<20) > 7 {
            return false
        }
        //if rogue auto or ability, or spriest mind blast
        if alterableEventCandidate.didCrit != 1 {
            if critManipulableSpells.contains(alterableEventCandidate.spellName) {
                if alterableEventCandidate.type == "SWING_DAMAGE_LANDED" {
                    return false
                }
                if alterableEventCandidate.spellName == "" {
                    //if not rogue, exit
                }
                if let critMultiplier = playerAbilityStatsStorage["\(playerName)-\(alterableEventCandidate.spellName)"]?["critMultiplier"] as? Double {
                    let newDamage = Int(Double(alterableEventCandidate.damageAmount) * critMultiplier)
                    let newDamageEvent = DamageEvent(timestamp: alterableEventCandidate.timestamp,
                                                     type: alterableEventCandidate.type,
                                                     sourceName: alterableEventCandidate.sourceName,
                                                     sourceFlags: alterableEventCandidate.sourceFlags,
                                                     spellName: alterableEventCandidate.spellName,
                                                     damageAmount: newDamage,
                                                     unmitigatedAmount: alterableEventCandidate.unmitigatedAmount,
                                                     didCrit: 1,
                                                     lineNumber: alterableEventCandidate.lineNumber,
                                                     didGlance: alterableEventCandidate.didGlance,
                                                     partialResistAmount: alterableEventCandidate.partialResistAmount,
                                                     changeEvent: ChangeEvent(changeType: "crit", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamage, stdDev: 0.0, multiplier: critMultiplier))
                    let damageDifference = newDamage - alterableEventCandidate.damageAmount
                    damageJuiced += damageDifference
                    modifiedDamageEvents.append(newDamageEvent)
					modificationsSummaryString += "Added a critical strike for \(alterableEventCandidate.sourceName)'s \(alterableEventCandidate.spellName) at \(alterableEventCandidate.timestamp). Old damage was \(alterableEventCandidate.damageAmount), new damage is \(newDamage)<br>"
                    if alterableEventCandidate.type == "SWING_DAMAGE" {
                        var swingDamageLandedEventFound = false
                        var nextIndexToCheck = randomIndex + 1
                        while !swingDamageLandedEventFound, nextIndexToCheck < damageInstancesToModify.count {
                            let candidateEvent = damageInstancesToModify[nextIndexToCheck]
                            if candidateEvent.type == "SWING_DAMAGE_LANDED" && candidateEvent.sourceName == alterableEventCandidate.sourceName && candidateEvent.damageAmount == alterableEventCandidate.damageAmount {
                                let newDamageEvent = DamageEvent(timestamp: candidateEvent.timestamp,
                                                                 type: candidateEvent.type,
                                                                 sourceName: candidateEvent.sourceName,
                                                                 sourceFlags: candidateEvent.sourceFlags,
                                                                 spellName: candidateEvent.spellName,
                                                                 damageAmount: newDamage,
                                                                 unmitigatedAmount: candidateEvent.unmitigatedAmount,
                                                                 didCrit: 1,
                                                                 lineNumber: candidateEvent.lineNumber,
                                                                 didGlance: candidateEvent.didGlance,
                                                                 partialResistAmount: candidateEvent.partialResistAmount,
                                                                 changeEvent: ChangeEvent(changeType: "crit", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamage, stdDev: 0.0, multiplier: critMultiplier))
                                modifiedDamageEvents.append(newDamageEvent)
                                eventsAlreadyChecked.append(nextIndexToCheck)
                                swingDamageLandedEventFound = true
                            } else {
                                nextIndexToCheck += 1
                        }
                    }
                    }
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        } else {
            return false
        }
    } else {
        if alterableEventCandidate.didCrit != 1 {
            return false
        } else {
            if critManipulableSpells.contains(alterableEventCandidate.spellName) {
                if alterableEventCandidate.type == "SWING_DAMAGE_LANDED" {
                    return false
                }
                if alterableEventCandidate.spellName == "" {
                    //if not rogue, exit
                }
                if let critMultiplier = playerAbilityStatsStorage["\(playerName)-\(alterableEventCandidate.spellName)"]?["critMultiplier"] as? Double {
                    let newDamage = Int(Double(alterableEventCandidate.damageAmount) / critMultiplier)
                    let newDamageEvent = DamageEvent(timestamp: alterableEventCandidate.timestamp,
                                                     type: alterableEventCandidate.type,
                                                     sourceName: alterableEventCandidate.sourceName,
                                                     sourceFlags: alterableEventCandidate.sourceFlags,
                                                     spellName: alterableEventCandidate.spellName,
                                                     damageAmount: newDamage,
                                                     unmitigatedAmount: alterableEventCandidate.unmitigatedAmount,
                                                     didCrit: nil,
                                                     lineNumber: alterableEventCandidate.lineNumber,
                                                     didGlance: alterableEventCandidate.didGlance,
                                                     partialResistAmount: alterableEventCandidate.partialResistAmount,
                                                     changeEvent: ChangeEvent(changeType: "crit", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamage, stdDev: 0.0, multiplier: critMultiplier))
                    let damageDifference = newDamage - alterableEventCandidate.damageAmount
                    damageLowered += damageDifference
                    modifiedDamageEvents.append(newDamageEvent)
					modificationsSummaryString += "Removed a critical strike from \(alterableEventCandidate.sourceName)'s \(alterableEventCandidate.spellName) at \(alterableEventCandidate.timestamp). Old damage was \(alterableEventCandidate.damageAmount), new damage is \(newDamage)<br>"
                    if alterableEventCandidate.type == "SWING_DAMAGE" {
                        var swingDamageLandedEventFound = false
                        var nextIndexToCheck = randomIndex + 1
                        while !swingDamageLandedEventFound {
                            let candidateEvent = damageInstancesToModify[nextIndexToCheck]
                            if candidateEvent.type == "SWING_DAMAGE_LANDED" && candidateEvent.sourceName == alterableEventCandidate.sourceName && candidateEvent.damageAmount == alterableEventCandidate.damageAmount {
                                let newDamageEvent = DamageEvent(timestamp: candidateEvent.timestamp,
                                                                 type: candidateEvent.type,
                                                                 sourceName: candidateEvent.sourceName,
                                                                 sourceFlags: candidateEvent.sourceFlags,
                                                                 spellName: candidateEvent.spellName,
                                                                 damageAmount: newDamage,
                                                                 unmitigatedAmount: candidateEvent.unmitigatedAmount,
                                                                 didCrit: nil,
                                                                 lineNumber: candidateEvent.lineNumber,
                                                                 didGlance: candidateEvent.didGlance,
                                                                 partialResistAmount: candidateEvent.partialResistAmount,
                                                                 changeEvent: ChangeEvent(changeType: "crit", oldDamage: alterableEventCandidate.damageAmount, newDamage: newDamage, stdDev: 0.0, multiplier: critMultiplier))
                                modifiedDamageEvents.append(newDamageEvent)
                                eventsAlreadyChecked.append(nextIndexToCheck)
                                swingDamageLandedEventFound = true
                            } else {
                                nextIndexToCheck += 1
                        }
                    }
                    }
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
}


func createModifiedDamageEvents() {
    damageEventsCount = damageInstancesToModify.count
    damageJuiced = 0
    damageLowered = 0
    eventsAlreadyChecked = [Int]()
    modifiedDamageEvents = [DamageEvent]()

    indexCount = 0
    indexArray = Array(0..<damageEventsCount)
    shuffledArray = indexArray.shuffled()

    while (damageJuiced < damageToJuice || damageLowered > (damageToJuice * -1)) && indexCount < damageEventsCount {
        randomIndex = shuffledArray[indexCount]
        while eventsAlreadyChecked.contains(randomIndex) {
            indexCount += 1
            randomIndex = shuffledArray[indexCount]
        }
        eventsAlreadyChecked.append(randomIndex)
        let alterableEventCandidate = damageInstancesToModify[randomIndex]
        let choice = Int.random(in: 0..<100)
        
        switch choice {
        case 0..<33:
            var result = changeResistOrGlance(alterableEventCandidate: alterableEventCandidate)
            if !result {
                result = raiseOrLowerDamageRoll(alterableEventCandidate: alterableEventCandidate)
                if !result {
                    result = makeOrUnMakeCrit(alterableEventCandidate: alterableEventCandidate)
                }
            }
        case 33..<66:
            var result = raiseOrLowerDamageRoll(alterableEventCandidate: alterableEventCandidate)
            if !result {
                result = makeOrUnMakeCrit(alterableEventCandidate: alterableEventCandidate)
                if !result {
                    result = changeResistOrGlance(alterableEventCandidate: alterableEventCandidate)
                }
            }
        default:
            var result = makeOrUnMakeCrit(alterableEventCandidate: alterableEventCandidate)
            if !result {
                result = changeResistOrGlance(alterableEventCandidate: alterableEventCandidate)
                if !result {
                    result = raiseOrLowerDamageRoll(alterableEventCandidate: alterableEventCandidate)
                }
            }
        }
        indexCount += 1
		debugOutputArea.innerHTML = .string(modificationsSummaryString)
    }
}

func composeNewFileString(oldString: String) {
    var fileComponents = oldString.components(separatedBy: .newlines).filter({$0 != ""})
    for damageEvent in modifiedDamageEvents {
        print(damageEvent.lineNumber)
        let originalString = fileComponents[damageEvent.lineNumber]
        var lineComponents = originalString.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: false).map({return String($0)})
        var actionComponents = lineComponents[3].components(separatedBy: ",")
        if damageEvent.type == "SPELL_DAMAGE" || damageEvent.type == "RANGE_DAMAGE" {
            actionComponents[28] = String(damageEvent.damageAmount)
            actionComponents[29] = String(damageEvent.unmitigatedAmount)
            actionComponents[35] = damageEvent.didCrit == nil ? "nil" : String(damageEvent.didCrit!)
            actionComponents[36] = damageEvent.didGlance == nil ? "nil" : String(damageEvent.didGlance!)
            actionComponents[32] = String(damageEvent.partialResistAmount)
        } else {
            actionComponents[25] = String(damageEvent.damageAmount)
            actionComponents[26] = String(damageEvent.unmitigatedAmount)
            actionComponents[32] = damageEvent.didCrit == nil ? "nil" : String(damageEvent.didCrit!)
            actionComponents[33] = damageEvent.didGlance == nil ? "nil" : String(damageEvent.didGlance!)
            actionComponents[29] = String(damageEvent.partialResistAmount)
        }
        let actionComponentsRecomposed = actionComponents.joined(separator: ",")
        lineComponents[3] = actionComponentsRecomposed
        let newString = lineComponents.joined(separator: " ")
        fileComponents[damageEvent.lineNumber] = String(newString)
    }
    let newString = fileComponents.joined(separator: "\n")
    //print(newString)
	newFileString = newString
}

func logSelected(file: String, playerNameInput: String, juiceFactorInput: String) {
    initializeData(fileContents: file)
    //console.log("Whose parse you tryna juice?")
    for damageInstance in damageInstances {
        let instanceInformation = damageInstance.value
        let source = instanceInformation.sourceName
        if instanceInformation.sourceFlags.contains("0x5") {
            sourceSet.insert(source)
        }
    }
    for item in sourceSet {
        print(item)
    }
    playerName = playerNameInput
    print("How much you tryna juice his DPS by?")
    juiceFactor = juiceFactorInput
    print("juicing")
    getPlayerDPSEvents(playerName: playerName)
    fillPlayerAbilityStatsStorage()
    createModifiedDamageEvents()
    composeNewFileString(oldString: file)
}

print("nuts")
