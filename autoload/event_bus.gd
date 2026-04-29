extends Node

signal battle_state_changed(state: Dictionary)
signal map_state_changed(state: Dictionary)
signal player_input_requested(choices: Array)
signal message_logged(text: String)
signal run_ended(result: Dictionary)
