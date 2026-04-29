extends Node
class_name SaveSettings

const SETTINGS_PATH := "user://settings.cfg"

var post_effect_enabled := true


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "post_effect_enabled", post_effect_enabled)
	config.save(SETTINGS_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	post_effect_enabled = bool(config.get_value("video", "post_effect_enabled", true))

