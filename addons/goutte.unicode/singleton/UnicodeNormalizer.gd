# SPDX-FileContributor: Antoine Goutenoir (antoine@goutenoir.com)
# SPDX-License-Identifier: MIT
@tool
extends Node
class_name UnicodeNormalizerClass

#  _    _       _               _        _   _                            _ _
# | |  | |     (_)             | |      | \ | |                          | (_)
# | |  | |_ __  _  ___ ___   __| | ___  |  \| | ___  _ __ _ __ ___   __ _| |_ _______ _ __
# | |  | | '_ \| |/ __/ _ \ / _` |/ _ \ | . ` |/ _ \| '__| '_ ` _ \ / _` | | |_  / _ \ '__|
# | |__| | | | | | (_| (_) | (_| |  __/ | |\  | (_) | |  | | | | | | (_| | | |/ /  __/ |
#  \____/|_| |_|_|\___\___/ \__,_|\___| |_| \_|\___/|_|  |_| |_| |_|\__,_|_|_/___\___|_|
#
# Helps normalizing unicode strings.
# - Decomposes and removes diacritics (NOËL → NOEL)
# - Applies substitution fallbacks (ß → ss)
# 
# Uses a huge CSV database straight from unicode.org.
# 
# Meant to be used as a singleton.
# If you don't use it that way, do remember to free() it.
# 
# Usage
# -----
# 
# 	print(UnicodeNormalizer.normalize("Daß œuf à Noël"))
# 	# "Dass oeuf a Noel"
# 


# This file was built from the CSV and JSON sources from unicode.org.
# It was stripped of unused information using a method in the test file,
# See:
# - res://addons/goutte.unicode/data/normalization_mapping.gd
# - res://addons/goutte.unicode/tests/UnicodeNormalizerTest.gd
var mapping: NormalizationMapping = preload("res://addons/goutte.unicode/data/normalization_mapping.res")


## Override this method to configure which characters the normalizer should skip.
## This helps supporting fonts with different capabilities.
func should_skip_character(_character: String, _character_code: int) -> bool:
	return false


func normalize(some_string: String) -> String:
	return remove_diacritics(substitute_with_fallbacks(some_string))


func remove_diacritics(some_string: String) -> String:
	var cleaned_string := ""
	
	var character_code: int
	for character in some_string:
		character_code = character.unicode_at(0)
		if should_skip_character(character, character_code):
			cleaned_string += character
			continue
		cleaned_string += self.mapping.get_decomposition(character_code)
	
	return cleaned_string


func substitute_with_fallbacks(some_string: String) -> String:
	var cleaned_string := ""
	
	var character_code: int
	for character in some_string:
		character_code = character.unicode_at(0)
		if should_skip_character(character, character_code):
			cleaned_string += character
			continue
		cleaned_string += self.mapping.get_substitution(character_code)
	
	return cleaned_string

