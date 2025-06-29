## Простой логгер с уровнями логирования
extends Node

## Уровни логов
enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR
}

## Текущий уровень логгирования
var current_level: LogLevel = LogLevel.INFO

## Запись лога с информацией и контекстом
func log(level: LogLevel, message: String, context: Dictionary = {}) -> void:
	if level < current_level:
		return
	
	var timestamp = Time.get_datetime_string_from_system()
	var level_str = LogLevel.keys()[level]
	var context_str = JSON.stringify(context) if !context.is_empty() else ""
	
	var log_message = "[%s] [%s] %s %s" % [timestamp, level_str, message, context_str]
	print(log_message)
