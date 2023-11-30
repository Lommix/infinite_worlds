extends Node
#----------------------------------
#signals to extend and interact with
#----------------------------------
##called before the final tile is decided [async]
# signal before_collapse(cell: WfcCell)
##called after the final tile is decided [async]
# signal after_collapse(cell: WfcCell)
##called on contradiction, a cell has 0 possible outcomes [async]
signal on_contradiction(cell: WfcCell)
#----------------------------------
##called when drawing to tilemap [mainthread]
signal on_cell_draw(cell: WfcCell)
#----------------------------------
#global cell storage
## key:Vector2i value: WfcCell
var loaded_cell := {}
