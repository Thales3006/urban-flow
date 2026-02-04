extends Node

signal level_won()
signal building_placed()
signal progress_state_changed(new_state: float)
signal add_building(building: Building)
signal write_word(word: String, catalog: BuildingCatalog)
