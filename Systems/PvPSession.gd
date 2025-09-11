# PvPSession.gd — глобальное хранилище данных для PvP
extends Node

var room_id: String = ""
var player_id: String = ""
var opponent_id: String = ""
var player_index: int = 0
var wave_data: Array = []
var game_started: bool = false
