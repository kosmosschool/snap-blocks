extends Node

# global variables that are autoloaded

var CONTR_LEFT_NAME = "OQ_LeftController"
var CONTR_RIGHT_NAME = "OQ_RightController"

# node paths
var CONTR_RIGHT_PATH = "/root/Main/OQ_ARVROrigin/OQ_RightController"
var CONTR_LEFT_PATH = "/root/Main/OQ_ARVROrigin/OQ_LeftController"
var AMMETER_CONTR_PATH = CONTR_RIGHT_PATH + "/Feature_ControllerModel_Right/AmmeterController"
var VOLTMETER_CONTR_PATH = CONTR_RIGHT_PATH + "/Feature_ControllerModel_Right/VoltmeterController"
var SCHEMATIC_PATH = "/root/Main/Schematic"
var ALL_MEASURE_POINTS_PATH = "/root/Main/AllMeasurePoints"
var TABLET_PATH = CONTR_LEFT_PATH + "/Feature_ControllerModel_Left/Tablet"
var ALL_BUILDING_BLOCKS_PATH = "/root/Main/AllBuildingBlocks"
var OBJECT_REMOVER_SYSTEM_PATH = "/root/Main/ObjectRemoverSystem"
var ALL_SCREENS_PATH = TABLET_PATH + "/Screens"
var CHALLENGE_SYSTEM_PATH = "/root/Main/ChallengeSystem"
var CONTROLLER_SYSTEM_PATH = "/root/Main/ControllerSystem"
var SPACE_TEXT_PATH = "/root/Main/SpaceText"
var MULTI_MESH_PATH = "/root/Main/AllMultiMeshes/MultiMeshInstance"

# resource paths
var MEASURE_POINT_FILE_PATH = "res://scenes/measure_point.tscn"
