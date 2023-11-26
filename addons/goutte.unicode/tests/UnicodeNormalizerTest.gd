# SPDX-FileContributor: Antoine Goutenoir (antoine@goutenoir.com)
# SPDX-License-Identifier: MIT
@tool
extends EditorScript


# Shameless test/benchmark file without any dependency on third-party test libs.
# Perhaps a script template with a bunch of assertions would be nice?
#
# Note: printerr() only prints in the CLI output of the Editor.


var status := OK
var normalizer: UnicodeNormalizerClass


func _run():
	var n_times := 100
	
	self.normalizer = get_normalizer()
	
	print("Running tests…")
	var start_time := Time.get_ticks_usec()
	run(n_times)
	var end_time := Time.get_ticks_usec()
	var total_time := end_time - start_time
	var average_time := total_time / n_times
	if self.status == OK:
		print("OK in %dµs (%d loops), average %dµs" % [total_time, n_times, average_time])
	
	self.normalizer.free()
	
	# Dev
	#build_normalization_mapping()


func run_once():
	test_remove_diacritics()
	test_normalize()


func run(n_times: int):
	for i in n_times:
		run_once()


func get_normalizer() -> UnicodeNormalizerClass:
	return preload("res://addons/goutte.unicode/singleton/UnicodeNormalizer.gd").new()


func test_remove_diacritics():
	var data := [
		# in, out
		['é', 'e'],
		['ê', 'e'],
		['ë', 'e'],
		['à', 'a'],
		['ç', 'c'],
		['Ç', 'C'],
		['a', 'a'],
		['E', 'E'],
		['Ş', 'S'],
		['NOËL', 'NOEL'],
	]
	
	for inout in data:
		var actual := self.normalizer.remove_diacritics(inout[0])
		var expected: String = inout[1]
		assert_equal(expected, actual, {'method': 'remove_diacritics', 'inout': inout})


func test_normalize():
	var data := [
		# in, out
		['e', 'e'],
		['é', 'e'],
		['è', 'e'],
		['ê', 'e'],
		['ë', 'e'],
		['à', 'a'],
		['ù', 'u'],
		['ç', 'c'],
		['Ç', 'C'],
		['a', 'a'],
		['E', 'E'],
		['Ş', 'S'],
		['Hétérogénéité', 'Heterogeneite'],
		['NOËL', 'NOEL'],
		['œuf', 'oeuf'],
		['Æsthetics', 'AEsthetics'],
		['daß', 'dass'],
		['©', '(C)'],
	]
	
	for inout in data:
		var actual := self.normalizer.normalize(inout[0])
		var expected: String = inout[1]
		assert_equal(expected, actual, {'method': 'normalize', 'inout': inout})


#                             _
#     /\                     | |
#    /  \   ___ ___  ___ _ __| |_
#   / /\ \ / __/ __|/ _ \ '__| __|
#  / ____ \\__ \__ \  __/ |  | |_
# /_/    \_\___/___/\___|_|   \__|
#
#

func fail(msg, context := {}):
	print_rich("[color=#FF4242]FAILURE:[/color] %s" % msg)
	if not context.is_empty():
		print(context)
	self.status = ERR_BUG


func assert_equal(expected, actual, context := {}):
	if expected != actual:
		fail("expected `%s` but got `%s`." % [expected, actual], context)


#  _____             _    _ _   _ _
# |  __ \           | |  | | | (_) |
# | |  | | _____   _| |  | | |_ _| |___
# | |  | |/ _ \ \ / / |  | | __| | / __|
# | |__| |  __/\ V /| |__| | |_| | \__ \
# |_____/ \___| \_/  \____/ \__|_|_|___/
#
# Tools we used to generate our datasets used in normalization, from raw data.

func build_normalization_mapping():
	var mapping := NormalizationMapping.from_sources()
	#ResourceSaver.save(mapping, "res://addons/goutte.unicode/data/normalization_mapping.tres")
	ResourceSaver.save(mapping, "res://addons/goutte.unicode/data/normalization_mapping.res", ResourceSaver.FLAG_COMPRESS)

