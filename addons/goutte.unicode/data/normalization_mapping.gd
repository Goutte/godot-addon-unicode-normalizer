# SPDX-FileContributor: Antoine Goutenoir (antoine@goutenoir.com)
# SPDX-License-Identifier: MIT
@tool
extends Resource
class_name NormalizationMapping

# Unicode
#  _   _                            _ _          _   _
# | \ | |                          | (_)        | | (_)
# |  \| | ___  _ __ _ __ ___   __ _| |_ ______ _| |_ _  ___  _ __
# | . ` |/ _ \| '__| '_ ` _ \ / _` | | |_  / _` | __| |/ _ \| '_ \
# | |\  | (_) | |  | | | | | | (_| | | |/ / (_| | |_| | (_) | | | |
# |_| \_|\___/|_|  |_| |_| |_|\__,_|_|_/___\__,_|\__|_|\___/|_| |_|
#  __  __                   _
# |  \/  |                 (_)
# | \  / | __ _ _ __  _ __  _ _ __   __ _
# | |\/| |/ _` | '_ \| '_ \| | '_ \ / _` |
# | |  | | (_| | |_) | |_) | | | | | (_| |
# |_|  |_|\__,_| .__/| .__/|_|_| |_|\__, |
#              | |   | |             __/ |
#              |_|   |_|            |___/
#
# Holds the pairs of unicode characters to replace & their replacements.
# This script is meant to be atteched to a Resource used by UnicodeNormalizer.
#
# There are two operations:
# 1. Decomposition: (é → e), maps a character to another, removing diacritics
# 2. Substitution: (æ → ae), maps a tough character to a string
#
# The mapping data is imported from CSV and JSON data from unicode.org repos.
# Using Godot's resource format instead of the raw CSV or JSON is:
# - faster (when in Rome…)
# - binary & compressed (16Kio instead of about 1.9Mio for the sources)
# - less of a pain with exported builds (CSV and JSON are often ignored)
# - not translated automatically (like CSV is)
# - sorted (raw JSON is not), required for the quite efficient binary search
# 
# The data is stored in two array pairs, so we can use binary search.
# 
# Sources
# -------
# https://www.unicode.org/Public/UNIDATA/UnicodeData.txt
# https://github.com/unicode-org/cldr-json/tree/main/cldr-json/cldr-core/supplemental
# 
# Download Sources
# ----------------
# You don't need to do this. Do only if you want to regenerate this Resource:
#
#     curl https://www.unicode.org/Public/UNIDATA/UnicodeData.txt > addons/goutte.unicode/data/UnicodeData.txt
#     curl https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-core/supplemental/characterFallbacks.json > addons/goutte.unicode/data/characterFallbacks.json
# 
# Then run NormalizationMapping.from_sources() and ResourceSaver.save() it
# See the test file for a method build_normalization_mapping() doing this:
# res://addons/goutte.unicode/tests/UnicodeNormalizerTest.gd
# 

## Unicode character codes that are to be decomposed.
## This array is sorted, and must be, since we're using binary search.
@export var decomposables := PackedInt64Array()
## Character code that will replace each character in the above array.
## This is usually the first character of the actual decomposition.
## This array must be of the same size as the `decomposables` array.
@export var decompositions := PackedInt64Array()

## Unicode character codes that are to be substituted.
## This array is sorted, and must be, since we're using binary search.
@export var substitutables := PackedInt64Array()
## String that will replace each character in the above array.
## This array must be of the same size as the `substitutables` array.
@export var substitutions := PackedStringArray()


func get_decomposition(character_code: int) -> String:
	var index := self.decomposables.bsearch(character_code, true)
	
	if (
		index < self.decomposables.size()
		and
		self.decomposables[index] == character_code
	):
		return String.chr(self.decompositions[index])
	
	return String.chr(character_code)


func get_substitution(character_code: int) -> String:
	var index := self.substitutables.bsearch(character_code, true)
	
	if (
		index < self.substitutables.size()
		and
		self.substitutables[index] == character_code
	):
		return self.substitutions[index]
	
	return String.chr(character_code)


#  _    _           _       _
# | |  | |         | |     | |
# | |  | |_ __   __| | __ _| |_ ___
# | |  | | '_ \ / _` |/ _` | __/ _ \
# | |__| | |_) | (_| | (_| | ||  __/
#  \____/| .__/ \__,_|\__,_|\__\___|
#        | |
#        |_|
# Tools to add/remove pairs from the database.
# As they keep the mappings sorted, best use these methods instead of appending.
# You should only use this if you want to customize the default mappings.
# I personnaly use this to add stuff like '…' → '...'.
# Note that your changes won't be saved to file.  Use ResourceSaver.save().

func insert_decomposable(decomposable: int, decomposition: int):
	var index := self.decomposables.bsearch(decomposable, true)
	self.decomposables.insert(index, decomposable)
	self.decompositions.insert(index, decomposition)

func insert_substitutable(substitutable: int, substitution: String):
	var index := self.substitutables.bsearch(substitutable, true)
	self.substitutables.insert(index, substitutable)
	self.substitutions.insert(index, substitution)

func remove_decomposable(decomposable: int):
	var index := self.decomposables.bsearch(decomposable, true)
	if (
		index < self.decomposables.size()
		and
		self.decomposables[index] == decomposable
	):
		self.decomposables.remove_at(index)

func remove_substitutable(substitutable: int):
	var index := self.substitutables.bsearch(substitutable, true)
	if (
		index < self.substitutables.size()
		and
		self.substitutables[index] == substitutable
	):
		self.substitutables.remove_at(index)


#  _____                                      _
# |  __ \                                    | |
# | |__) |___  __ _  ___ _ __   ___ _ __ __ _| |_ ___
# |  _  // _ \/ _` |/ _ \ '_ \ / _ \ '__/ _` | __/ _ \
# | | \ \  __/ (_| |  __/ | | |  __/ | | (_| | ||  __/
# |_|  \_\___|\__, |\___|_| |_|\___|_|  \__,_|\__\___|
#              __/ |
#             |___/
# Below are tools to regenerate the mapping from sources.
# You do not need to do that.

# These files are not provided with the source tree.
# You do not need them unless you want to regenerate the Resource.
# You can easily download them yourselves, see the documentation at the top.
const DECOMPOSITION_DATA_PATH := "res://addons/goutte.unicode/data/UnicodeData.txt"
const SUBSTITUTION_DATA_PATH := "res://addons/goutte.unicode/data/characterFallbacks.json"


static func from_sources() -> NormalizationMapping:
	var mapping := NormalizationMapping.new()
	
	# I. Decomposition mapping
	var unicode_data := FileAccess.open(DECOMPOSITION_DATA_PATH, FileAccess.READ)
	if unicode_data.get_open_error() != OK:
		print("decomposition data was not found at %s" % [DECOMPOSITION_DATA_PATH])
		return mapping
	
	var line: PackedStringArray
	while not unicode_data.eof_reached():
		line = unicode_data.get_csv_line(";")
		if line.size() < 6:
			continue  # last line of the file is empty, and yields line == [""]
		if line[5] == "":
			continue  # Let's only keep lines with decomposition data
		if not line[0].is_valid_hex_number():
			continue  # should not happen unless our database gets corrupted
		# Let's keep only the first character of the decomposition.
		# (naive but kind of works)  Decomposition can be stuff like:
		# - 0113 0300
		# - <super> 0052
		var decomposition := line[5].split(" ")
		for something in decomposition:
			if not something.is_valid_hex_number():
				continue
			# All's OK, let's store the pair
			var code := line[0].hex_to_int()
			mapping.insert_decomposable(code, something.hex_to_int())
			break
	
	unicode_data.close()
	
	# II. Substitution mapping
	var substitution_data := FileAccess.open(SUBSTITUTION_DATA_PATH, FileAccess.READ)
	if substitution_data.get_open_error() != OK:
		print("substitution data was not found at %s" % [SUBSTITUTION_DATA_PATH])
		return mapping
	
	var sdj := JSON.parse_string(substitution_data.get_as_text())
	var fbd = sdj['supplemental']['characters']['character-fallback']
	for key in fbd:
		var hex: String = key.substr(2)  # it starts by U+…
		if not hex.is_valid_hex_number():
			continue
		var code := hex.hex_to_int()
		mapping.insert_substitutable(code, fbd[key][0]['substitute'])
	
	substitution_data.close()
	
	# III. Check consistency, it's not expensive
	assert(mapping.decomposables.size() == mapping.decompositions.size())
	assert(mapping.substitutables.size() == mapping.substitutions.size())
	
	return mapping
