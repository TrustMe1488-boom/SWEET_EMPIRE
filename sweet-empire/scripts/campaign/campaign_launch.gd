class_name CampaignLaunch
extends RefCounted
static var requested: bool = false
static func consume() -> bool:
 var result := requested
 requested = false
 return result
