extends Label
class_name InteractionPrompt


func set_prompt(text: String) -> void:
	self.text = text
	visible = not text.is_empty()

