extends Node

signal level_won()
signal building_placed()
signal progress_state_changed(new_state: float)
signal write_word(word: String, catalog: BuildingCatalog)
signal hint_executed()
signal disable_others(nodes: Array[Node])
signal enable_all()
signal create_front_catalog_button(button: Button)
signal volume_changed(volume_level: float)
