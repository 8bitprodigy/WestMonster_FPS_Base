extends Resource
class_name LoadoutCategory

@export var category_name : String = ""
@export var loadout_items : Array[LoadoutItem]
@export var MAX_ITEMS : int = 0
@export var ignore_start_picked_up : bool = false
@export var no_duplicates : bool = true


func register_item(loadout_item:LoadoutItem,index:int=0):
	if MAX_ITEMS == 0:
		if no_duplicates:
			for item in loadout_items:
				if item == loadout_item: return
		loadout_items.append(loadout_item)
	else:
		if loadout_items.size() < MAX_ITEMS:
			loadout_items.append(loadout_item)
			return
	return replace_item(index,loadout_item)

func register_items(_loadout_items:Array[LoadoutItem]):
	if _loadout_items.size() + loadout_items.size() > MAX_ITEMS: return MAX_ITEMS - _loadout_items.size()+loadout_items.size()
	loadout_items.append_array(_loadout_items)
	return MAX_ITEMS - loadout_items.size()

func remove_item(index:int):
	loadout_items.pop_at(index)

func replace_item(index:int,new_item:LoadoutItem):
	var popped_item = loadout_items[index]
	loadout_items[index] = new_item
	return popped_item
