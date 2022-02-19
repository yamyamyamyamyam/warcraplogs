# WarcrapLogs

WarcrapLogs is a tool designed for use with WarcraftLogs. WarcrapLogs uses statistical analysis to edit your combat logs, increasing the DPS and parse of a targeted character while keeping the combat log internally consistent. WarcrapLogs aims to create logs that are undetectable as fraudulent without significant statistical analysis.

WarcrapLogs manipulates combat logs in several ways. It modifies the damage rolls of attacks with variable damage, decreasing the damage of certain attacks by other players in your raid while increasing the damage of some attacks performed by the character whose parse you are increasing. Secondly, it removes a sampling of glancing blows or partial resists by the targeted character, while adding partial resists and glancing blows to other players' attacks. Lastly, it turns some attacks by the targeted character into critical strikes and others by non-targeted characters into normal hits.

The rate of damage and total damage done by the raid remains the same before and after manipulation.

# Usage

./warcraplogs

WarcrapLogs will prompt you at the command line for a file path, then subsequently for a character name in the form 'Name-Realm,' followed lastly by the desired increase in DPS for that character.

# Notes

The DPS added, as recorded on WarcraftLogs, may be slightly higher or lower than the amount actually added to the log by WarcrapLogs.
