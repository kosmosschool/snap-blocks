extends Node

# global variables that are autoloaded

var CONTR_LEFT_NAME = "OQ_LeftController"
var CONTR_RIGHT_NAME = "OQ_RightController"

# node paths
var CONTR_RIGHT_PATH = "/root/Main/OQ_ARVROrigin/OQ_RightController"
var CONTR_LEFT_PATH = "/root/Main/OQ_ARVROrigin/OQ_LeftController"
var MOVABLE_WORLD_PATH = "/root/Main/MovableWorld/"

var ALL_BUILDING_BLOCKS_PATH = "/root/Main/MovableWorld/AllBuildingBlocks"
#var ALL_BLOCK_AREAS_PATH = "/root/Main/MovableWorld/AllBlockAreas"
#var OBJECT_REMOVER_SYSTEM_PATH = "/root/Main/ObjectRemoverSystem"
var CONTROLLER_SYSTEM_PATH = "/root/Main/ControllerSystem"
#var MULTI_MESH_PATH = "/root/Main/MovableWorld/AllMultiMeshes/MultiMeshInstance"
var AR_VR_ORIGIN_PATH = "/root/Main/OQ_ARVROrigin"
var AR_VR_CAMERA_PATH = AR_VR_ORIGIN_PATH + "/OQ_ARVRCamera"
var TABLET_PATH = CONTR_LEFT_PATH + "/Tablet"
var ALL_SCREENS_PATH = TABLET_PATH + "/Screens"
var WELCOME_CONTROLLER_PATH = "/root/Main/WelcomeController"
var BLOCK_CHUNKS_CONTROLLER_PATH = "/root/Main/MovableWorld/AllBlockChunks"

# resource paths
var BASIC_BUILDING_BLOCK_PATH = "res://scenes/building_blocks/block_base_cube.tscn"
var BLOCK_AREA_SCRIPT_PATH = "res://scripts/block_area.gd"
var CUBE_COLLISION_SHAPE_PATH = "res://shapes/cube_collision_shape.tres"
var BLOCK_CHUNK_SCENE_PATH = "res://scenes/block_chunk.tscn"
