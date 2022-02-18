//
//  main.swift
//  warcraplogs
//
//  Created by big dam yam on 2/17/22.
//

import Foundation

struct DamageEvent {
    let timestamp: String
    let type: String
    let sourceName: String
    let sourceFlags: String
    let spellName: String
    let damageAmount: Int
    let unmitigatedAmount: Int
    let lineNumber: Int
}

print("Enter log file path: ")
guard let path = readLine() else { exit(5) }
let url = URL(fileURLWithPath: path)

guard let filePointer:UnsafeMutablePointer<FILE> = fopen(url.path,"r") else {
    preconditionFailure("Could not open file at \(url.absoluteString)")
}

var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil

defer {
    fclose(filePointer)
    lineByteArrayPointer?.deallocate()
}

var actionSet = Set<String>()
let interestedActionTypes = ["SWING_DAMAGE_LANDED", "RANGE_DAMAGE", "SWING_DAMAGE", "SPELL_DAMAGE"]
var damageInstances = [Int : DamageEvent]()
var damageInstancesByPlayer = [String : [String : [DamageEvent]]]()

var lineCap: Int = 0
var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
var currentLineNumber = 0
while (bytesRead > 0) {
    let lineAsString = String.init(cString:lineByteArrayPointer!)
    let components = lineAsString.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: false)
    //let components = lineAsString.components(separatedBy: " ")
    //first element always day, second element always timestamp, third element subevent? fourth element what we want
    let action = components[3].components(separatedBy: ",")
    let actionType = action[0]
    if interestedActionTypes.contains(actionType) {
        let damageEvent: DamageEvent
        if actionType == "SPELL_DAMAGE" || actionType == "RANGE_DAMAGE" {
            damageEvent = DamageEvent(timestamp: String(components[1]), type: actionType, sourceName: action[2].replacingOccurrences(of: "\"", with: ""), sourceFlags: action[3], spellName: action[10], damageAmount: Int(action[28])!, unmitigatedAmount: Int(action[29])!, lineNumber: currentLineNumber)
        } else {
            damageEvent = DamageEvent(timestamp: String(components[1]), type: actionType, sourceName: action[2].replacingOccurrences(of: "\"", with: ""), sourceFlags: action[3], spellName: "", damageAmount: Int(action[25])!, unmitigatedAmount: Int(action[26])!, lineNumber: currentLineNumber)
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
    //actionSet.insert(actionType)
    bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
    currentLineNumber += 1
}

var sourceSet = Set<String>()

for damageInstance in damageInstances {
    let instanceInformation = damageInstance.value
    let source = instanceInformation.sourceName
    if instanceInformation.sourceFlags == "0x514" {
        sourceSet.insert(source)
    }
}
print("Whose parse you tryna juice?")
for item in sourceSet {
    print(item)
}
guard let playerName = readLine() else { preconditionFailure("invalid player name") }
print(playerName)
print("How much you tryna juice his DPS by?")
guard let juiceFactor = readLine() else { preconditionFailure("invalid juice factor") }
print("Juicing...")
var selectedPlayerDamageEvents = [DamageEvent]()
let playerDamageEvents = damageInstancesByPlayer[playerName]!
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "HH:mm:ss.SSS"
var latestTime = Date(timeIntervalSince1970: 0.0)
var earliestTime = Date()
var maxDamage = 0
var totalDamage = 0
var playerDamageTypes = Set<String>()
var playerDamageDictionary = [String : [String : [DamageEvent]]]()

for playerDamageEventKey in playerDamageEvents.keys {
    let values = playerDamageEvents[playerDamageEventKey]!
    for playerDamageEvent in values {
        let time = dateFormatter.date(from: playerDamageEvent.timestamp)!
        if time < earliestTime {
            earliestTime = time
        }
        if time > latestTime {
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
let numEvents = selectedPlayerDamageEvents.count
let timeElapsed = latestTime.timeIntervalSince(earliestTime)
let unJuicedDPS = Double(totalDamage) / timeElapsed
print("\(numEvents) events, max damage of \(maxDamage), total damage \(totalDamage), over \(timeElapsed) elapsed time, \(Double(totalDamage) / timeElapsed) DPS")
print(" ")
let juicedDPS = unJuicedDPS + Double(juiceFactor)!
let requiredDamage = juicedDPS * timeElapsed
let damageToJuice = requiredDamage - Double(totalDamage)
print("Need to juice \(damageToJuice) damage")
print("Damage breakdown:")
for player in damageInstancesByPlayer.keys {
    print("\(player)")
    let currentPlayerDamageDictionary = damageInstancesByPlayer[player]!
    for damageType in currentPlayerDamageDictionary.keys {
        let values = currentPlayerDamageDictionary[damageType]!
        let totalDamage = values.reduce(0, {x, y in
            x + y.damageAmount
        })
        let meanDamage = totalDamage / values.count
        let variance = Double(values.map({return abs($0.damageAmount - meanDamage)^2}).reduce(0, {x, y in
            x + y
        }) / values.count)
        let standardDeviation = sqrt(variance)
        print("\(damageType): \(values.count) instances, \(meanDamage) average damage, \(standardDeviation) stdDev")
        
    }
    print(" ")
    print(" ")
}
/*for damageType in playerDamageTypes {
    let values = selectedPlayerDamageEvents.filter({$0.spellName == damageType})
    let totalDamage = values.reduce(0, {x, y in
        x + y.damageAmount
    })
    let averageDamage = totalDamage / values.count
    print("\(damageType): \(values.count) instances, \(averageDamage) average damage")
}*/


