# Вспомогательные математические функции
extends Node

static func round_to_dec(num: float, digit: int) -> float:
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
