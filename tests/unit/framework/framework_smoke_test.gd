# Proves the test toolchain itself works: gdUnit4 loads, discovers this suite,
# runs it headless and reports. Delete once the first real Logic test exists.
class_name FrameworkSmokeTest
extends GdUnitTestSuite


func test_assert_equal_passes_on_equal_ints() -> void:
	assert_int(2 + 2).is_equal(4)


func test_typed_array_round_trip_keeps_string_names() -> void:
	var steps: Array[StringName] = [&"cup", &"serve"]
	assert_array(steps).contains_exactly([&"cup", &"serve"])
