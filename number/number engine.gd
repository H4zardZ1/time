extends RefCounted
class_name BigNumRef
## A class that holds a number that can be larger or smaller than the floating point limit.
##
## A [RefCounted] that stores a single number that uses 2 values (Layer, Magnitude) to represent it, 
## with the sign of the number stored on either the layer or the magnitude, depending on the number's size. [br]
## [br]
## In addition, this library supports operations with the bare 2 values, in [PackedFloat64Array] form, as following: [br]
## [codeblock]
## [layer, magnitude]
## [/codeblock]
## [br]
## Based on [url]https://github.com/Patashu/break_eternity.js[/url][br]
## [b]Note:[/b] All static/singleton methods on this class that returns a PackedFloat64Array, excluding [method normalize_n],
## do not mutate the old Array.

enum BigNumArrayIndices {
	LAYER = 0,
	MAG
}
# see BigNumArrayIndices
enum In {
	L = 0,
	M
}
# signals
signal n_changed()

# constants
const MAX_FLOAT_PRECISION = 17
## [code]2**-1022[/code].
## [br][b]Note:[/b] This number appears as zero in [method @GlobalScope.is_zero_approx], and also when stringified.
const LOWEST_POSITIVE_NORMAL_FLOAT = 2.0 ** -1022
# 2**53 - 1
const LAYER_UP: float = 2 ** 53 - 1
# the lowest number Godot will write in exponent notations
const EXPONENT_WRITTEN: float = 1e15
const LAYER_DOWN =  15.9545897702 #log(2 ** 53 - 1)/log(10) # Godot doesn't support log10() or log2()
const FIRST_NEG_LAYER: float = 1 / LAYER_UP
# floor(log(2**1023 * (1 + (1 - 2**-52)))/log(10))
const NUMBER_EXP_MAX = 308

const NUMBER_EXP_MIN = -324
## Lambert W(1,0). Also known as Omega Constant.
const LAMBERTW_ONE_ZERO = 0.56714329040978387299997

const CRITICAL_HEADERS: PackedFloat64Array = [2.0, exp(1), 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

const CRITICAL_TETR_VALUES: Array[PackedFloat64Array] = [[
	# Base 2 (using http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html )
	1.0, 1.0891180521811202527, 1.1789767925673958433, 1.2701455431742086633, 1.3632090180450091941, 1.4587818160364217007, 1.5575237916251418333, 1.6601571006859253673, 1.7674858188369780435, 1.8804192098842727359, 2.0], [
	# Base E (using http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html )
	1.0, 1.1121114330934078681, 1.2310389249316089299, 1.3583836963111376089, 1.4960519303993531879, 1.6463542337511945810, 1.8121385357018724464, 1.9969713246183068478, 2.2053895545527544330, 2.4432574483385252544, exp(1)
	], [
	# Base 3
	1.0, 1.1187738849693603, 1.2464963939368214, 1.38527004705667, 1.5376664685821402, 1.7068895236551784, 1.897001227148399, 2.1132403089001035, 2.362480153784171, 2.6539010333870774, 3.0], [
	# Base 4
	1.0, 1.1367350847096405, 1.2889510672956703, 1.4606478703324786, 1.6570295196661111, 1.8850062585672889, 2.1539465047453485, 2.476829779693097, 2.872061932789197, 3.3664204535587183, 4.0], [
	# Base 5
	1.0, 1.1494592900767588, 1.319708228183931, 1.5166291280087583, 1.748171114438024, 2.0253263297298045, 2.3636668498288547, 2.7858359149579424, 3.3257226212448145, 4.035730287722532, 5.0], [
	# Base 6
	1.0, 1.159225940787673, 1.343712473580932, 1.5611293155111927, 1.8221199554561318, 2.14183924486326, 2.542468319282638, 3.0574682501653316, 3.7390572020926873, 4.6719550537360774, 6.0], [
	# Base 7
	1.0, 1.1670905356972596, 1.3632807444991446, 1.5979222279405536, 1.8842640123816674, 2.2416069644878687, 2.69893426559423, 3.3012632110403577, 4.121250340630164, 5.281493033448316, 7.0], [
	# Base 8
	1.0, 1.1736630594087796, 1.379783782386201, 1.6292821855668218, 1.9378971836180754, 2.3289975651071977, 2.8384347394720835, 3.5232708454565906, 4.478242031114584, 5.868592169644505, 8.0], [
	# Base 9
	1.0, 1.1793017514670474, 1.394054150657457, 1.65664127441059, 1.985170999970283, 2.4069682290577457, 2.9647310119960752, 3.7278665320924946, 4.814462547283592, 6.436522247411611, 9.0], [
	# Base 10 (using http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html )
	1.0, 1.1840100246247336579, 1.4061375836156954169, 1.6802272208863963918, 2.026757028388618927, 2.4770056063449647580, 3.0805252717554819987, 3.9191964192627283911, 5.1351528408331864230, 6.9899611795347148455, 10.0]]

const CRITICAL_SLOG_VALUES: Array[PackedFloat64Array] = [[
  # Base 2
  -1.0, -0.9194161097107025, -0.8335625019330468, -0.7425599821143978, -0.6466611521029437, -0.5462617907227869, -0.4419033816638769, -0.3342645487554494, -0.224140440909962, -0.11241087890006762, 0.0], [
  # Base E
  -1.0, -0.90603157029014, -0.80786507256596, -0.7064666939634, -0.60294836853664, -0.49849837513117, -0.39430303318768, -0.29147201034755, -0.19097820800866, -0.09361896280296, 0.0 # 1.0
  ], [
  # Base 3
  -1.0, -0.9021579584316141, -0.8005762598234203, -0.6964780623319391, -0.5911906810998454, -0.486050182576545, -0.3823089430815083, -0.28106046722897615, -0.1831906535795894, -0.08935809204418144, 0.0], [
  # Base 4
  -1.0, -0.8917227442365535, -0.781258746326964, -0.6705130326902455, -0.5612813129406509, -0.4551067709033134, -0.35319256652135966, -0.2563741554088552, -0.1651412821106526, -0.0796919581982668, 0.0], [
  # Base 5
  -1.0, -0.8843387974366064, -0.7678744063886243, -0.6529563724510552, -0.5415870994657841, -0.4352842206588936, -0.33504449124791424, -0.24138853420685147, -0.15445285440944467, -0.07409659641336663, 0.0], [
  # Base 6
  -1.0, -0.8786709358426346, -0.7577735191184886, -0.6399546189952064, -0.527284921869926, -0.4211627631006314, -0.3223479611761232, -0.23107655627789858, -0.1472057700818259, -0.07035171210706326, 0.0], [
  # Base 7
  -1.0, -0.8740862815291583, -0.7497032990976209, -0.6297119746181752, -0.5161838335958787, -0.41036238255751956, -0.31277212146489963, -0.2233976621705518, -0.1418697367979619, -0.06762117662323441, 0.0], [
  # Base 8
  -1.0, -0.8702632331800649, -0.7430366914122081, -0.6213373075161548, -0.5072025698095242, -0.40171437727184167, -0.30517930701410456, -0.21736343968190863, -0.137710238299109, -0.06550774483471955, 0.0], [
  # Base 9
  -1.0, -0.8670016295947213, -0.7373984232432306, -0.6143173985094293, -0.49973884395492807, -0.394584953527678, -0.2989649949848695, -0.21245647317021688, -0.13434688362382652, -0.0638072667348083, 0.0], [
  # Base 10
  -1.0, -0.8641642839543857, -0.732534623168535, -0.6083127477059322, -0.4934049257184696, -0.3885773075899922, -0.29376029055315767, -0.2083678561173622, -0.13155653399373268, -0.062401588652553186, 0.0]
]
## Zero.
const BIGNUM_ZERO: PackedFloat64Array = [0, 0]
## One.
const BIGNUM_ONE: PackedFloat64Array = [0, 1]
## Negative one.
const BIGNUM_NEG_ONE: PackedFloat64Array = [0, -1]
## Invalid number.
const BIGNUM_NAN: PackedFloat64Array = [NAN, NAN]
## Euler's Number.
const BIGNUM_E: PackedFloat64Array = [0, exp(1)]
## Infinity.
const BIGNUM_INF: PackedFloat64Array = [INF, INF]
## Negative infinity.
const BIGNUM_NEG_INF: PackedFloat64Array = [-INF, INF]
## Lookup table for powers of 10, from [code]1e-323[/code] to [code]1e308[/code].
const POWERS_OF_TEN: PackedFloat64Array = [1e-323, 1e-322, 1e-321, 1e-320, 1e-319, 1e-318, 1e-317, 1e-316, 1e-315, 1e-314, 1e-313, 1e-312, 
1e-311, 1.00000000000005e-310, 1.00000000000003e-309, 9.999999999999994e-309, 9.999999999999995e-308, 9.999999999999994e-307, 
9.999999999999995e-306, 9.999999999999994e-305, 9.999999999999994e-304, 9.999999999999996e-303, 9.999999999999994e-302, 9.999999999999994e-301, 
9.999999999999993e-300, 9.999999999999995e-299, 9.999999999999994e-298, 9.999999999999995e-297, 9.999999999999994e-296, 9.999999999999995e-295,
9.999999999999994e-294, 9.999999999999993e-293, 9.999999999999994e-292, 9.999999999999994e-291, 9.999999999999993e-290, 9.999999999999995e-289, 
9.999999999999996e-288, 9.999999999999996e-287, 9.999999999999995e-286, 9.999999999999996e-285, 9.999999999999995e-284, 9.999999999999994e-283, 
9.999999999999993e-282, 9.999999999999996e-281, 9.999999999999995e-280, 9.999999999999995e-279, 9.999999999999995e-278, 9.999999999999995e-277, 
9.999999999999995e-276, 9.999999999999995e-275, 9.999999999999995e-274, 9.999999999999994e-273, 9.999999999999994e-272, 9.999999999999994e-271, 
9.999999999999995e-270, 9.999999999999994e-269, 9.999999999999996e-268, 9.999999999999995e-267, 9.999999999999994e-266, 9.999999999999996e-265, 
9.999999999999995e-264, 9.999999999999994e-263, 9.999999999999994e-262, 9.999999999999996e-261, 9.999999999999993e-260, 9.999999999999995e-259, 
9.999999999999994e-258, 9.999999999999995e-257, 9.999999999999997e-256, 9.999999999999995e-255, 9.999999999999996e-254, 9.999999999999997e-253, 
9.999999999999994e-252, 9.999999999999996e-251, 9.999999999999993e-250, 9.999999999999994e-249, 9.999999999999995e-248, 9.999999999999996e-247, 
9.999999999999995e-246, 9.999999999999994e-245, 9.999999999999996e-244, 9.999999999999996e-243, 9.999999999999995e-242, 9.999999999999996e-241, 
9.999999999999996e-240, 9.999999999999995e-239, 9.999999999999996e-238, 9.999999999999994e-237, 9.999999999999996e-236, 9.999999999999994e-235, 
9.999999999999996e-234, 9.999999999999995e-233, 9.999999999999996e-232, 9.999999999999997e-231, 9.999999999999995e-230, 9.999999999999996e-229, 
9.999999999999997e-228, 9.999999999999994e-227, 9.999999999999994e-226, 9.999999999999997e-225, 9.999999999999996e-224, 9.999999999999994e-223, 
9.999999999999998e-222, 9.999999999999996e-221, 9.999999999999994e-220, 9.999999999999995e-219, 9.999999999999995e-218, 9.999999999999997e-217, 
9.999999999999995e-216, 9.999999999999995e-215, 9.999999999999996e-214, 9.999999999999996e-213, 9.999999999999997e-212, 9.999999999999997e-211, 
9.999999999999995e-210, 9.999999999999997e-209, 9.999999999999996e-208, 9.999999999999996e-207, 9.999999999999996e-206, 9.999999999999996e-205, 
9.999999999999996e-204, 9.999999999999995e-203, 9.999999999999996e-202, 9.999999999999995e-201, 9.999999999999995e-200, 9.999999999999995e-199, 
9.999999999999997e-198, 9.999999999999997e-197, 9.999999999999997e-196, 9.999999999999996e-195, 9.999999999999996e-194, 9.999999999999995e-193, 
9.999999999999996e-192, 9.999999999999998e-191, 9.999999999999997e-190, 9.999999999999998e-189, 9.999999999999998e-188, 9.999999999999997e-187, 
9.999999999999995e-186, 9.999999999999997e-185, 9.999999999999998e-184, 9.999999999999997e-183, 9.999999999999998e-182, 9.999999999999998e-181, 
9.999999999999997e-180, 9.999999999999995e-179, 9.999999999999997e-178, 9.999999999999996e-177, 9.999999999999997e-176, 9.999999999999997e-175, 
9.999999999999997e-174, 9.999999999999996e-173, 9.999999999999996e-172, 9.999999999999996e-171, 9.999999999999997e-170, 9.999999999999997e-169, 
9.999999999999996e-168, 9.999999999999997e-167, 9.999999999999996e-166, 9.999999999999998e-165, 9.999999999999998e-164, 9.999999999999997e-163, 
9.999999999999996e-162, 9.999999999999997e-161, 9.999999999999997e-160, 9.999999999999997e-159, 1e-157, 9.999999999999998e-157, 
9.999999999999998e-156, 9.999999999999996e-155, 9.999999999999996e-154, 9.999999999999996e-153, 9.999999999999998e-152, 9.999999999999996e-151, 
9.999999999999998e-150, 9.999999999999996e-149, 9.999999999999997e-148, 9.999999999999996e-147, 9.999999999999997e-146, 9.999999999999998e-145, 
9.999999999999997e-144, 9.999999999999997e-143, 9.999999999999998e-142, 9.999999999999998e-141, 9.999999999999997e-140, 9.999999999999998e-139, 
9.999999999999997e-138, 9.999999999999996e-137, 9.999999999999997e-136, 9.999999999999997e-135, 9.999999999999997e-134, 9.999999999999997e-133, 
9.999999999999997e-132, 9.999999999999997e-131, 9.999999999999998e-130, 9.999999999999997e-129, 9.999999999999998e-128, 9.999999999999998e-127, 
9.999999999999999e-126, 1e-124, 9.999999999999997e-124, 9.999999999999998e-123, 9.999999999999995e-122, 9.999999999999998e-121, 
9.999999999999999e-120, 9.999999999999998e-119, 9.999999999999999e-118, 9.999999999999999e-117, 9.999999999999997e-116, 9.999999999999997e-115, 
9.999999999999998e-114, 9.999999999999998e-113, 9.999999999999997e-112, 9.999999999999998e-111, 9.999999999999998e-110, 9.999999999999997e-109, 
9.999999999999999e-108, 9.999999999999997e-107, 9.999999999999998e-106, 9.999999999999998e-105, 9.999999999999998e-104, 1e-102, 
9.999999999999997e-102, 9.999999999999998e-101, 9.999999999999998e-100, 9.999999999999998e-99, 9.999999999999998e-98, 1e-96, 
9.999999999999998e-96, 9.999999999999998e-95, 1e-93, 9.999999999999998e-93, 9.999999999999997e-92, 9.999999999999998e-91, 
9.999999999999997e-90, 9.999999999999998e-89, 9.999999999999998e-88, 9.999999999999999e-87, 9.999999999999998e-86, 9.999999999999997e-85, 
9.999999999999999e-84, 9.999999999999998e-83, 9.999999999999998e-82, 1e-80, 9.999999999999998e-80, 9.999999999999998e-79, 1e-77, 
9.999999999999998e-77, 9.999999999999998e-76, 9.999999999999998e-75, 9.999999999999998e-74, 9.999999999999998e-73, 1e-71, 9.999999999999998e-71, 
1e-69, 9.999999999999999e-69, 1e-67, 9.999999999999998e-67, 9.999999999999997e-66, 9.999999999999998e-65, 9.999999999999999e-64, 1e-62, 1e-61, 
1.0000000000000001e-60, 1e-59, 9.999999999999998e-59, 9.999999999999998e-58, 9.999999999999999e-57, 1e-55, 
9.999999999999999e-55, 1e-53, 1e-52, 1e-51, 9.999999999999999e-51, 1e-49, 1e-48, 1e-47, 1e-46, 1e-45, 1e-44, 1e-43, 
9.999999999999999e-43, 1e-41, 1e-40, 1e-39, 1e-38, 9.999999999999999e-38, 1e-36, 1e-35, 1e-34, 9.999999999999999e-34, 
9.999999999999999e-33, 1e-31, 9.999999999999999e-31, 1.0000000000000001e-29, 1.0000000000000001e-28, 1e-27, 9.999999999999999e-27, 
9.999999999999999e-26, 1.0000000000000001e-24, 1.0000000000000001e-23, 
1e-22, 1e-21, 1e-20, 1e-19, 1e-18, 1e-17, 1e-16, 1e-15, 1e-14, 1e-13, 1e-12, 1e-11, 1e-10, 1e-09, 1e-08, 1e-07, 1e-06, 1e-05, 
0.0001, 0.001, 0.01, 0.1, 1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0, 
1000000000.0, 10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0, 100000000000000.0, 
1e+15, 1e+16, 1e+17, 1e+18, 1e+19, 1e+20, 1e+21, 1e+22, 9.999999999999999e+22, 1e+24, 1e+25, 1e+26, 1e+27, 1e+28, 
1e+29, 1e+30, 1e+31, 1e+32, 1.0000000000000001e+33, 1.0000000000000001e+34, 
1e+35, 1e+36, 1.0000000000000001e+37, 1e+38, 1.0000000000000001e+39, 1e+40, 1e+41, 1e+42, 1e+43, 1e+44, 
1.0000000000000001e+45, 1e+46, 1e+47, 1e+48, 1.0000000000000001e+49, 1e+50, 1e+51, 1e+52, 1e+53, 1e+54, 1e+55, 1e+56, 
1.0000000000000002e+57, 1.0000000000000001e+58, 1.0000000000000001e+59, 1e+60, 1e+61, 1e+62, 1e+63, 1.0000000000000002e+64, 
1.0000000000000002e+65, 1.0000000000000001e+66, 1.0000000000000001e+67, 1.0000000000000002e+68, 1e+69, 1.0000000000000002e+70, 
1.0000000000000002e+71, 1.0000000000000001e+72, 1.0000000000000001e+73, 1.0000000000000002e+74, 1.0000000000000001e+75, 1.0000000000000002e+76,
1.0000000000000001e+77, 1.0000000000000002e+78, 1.0000000000000001e+79, 1.0000000000000001e+80, 1.0000000000000001e+81, 1.0000000000000001e+82, 
1.0000000000000002e+83, 1.0000000000000003e+84, 1.0000000000000002e+85, 1.0000000000000002e+86, 1.0000000000000002e+87, 1.0000000000000001e+88,
1.0000000000000003e+89, 1.0000000000000002e+90, 1.0000000000000003e+91, 1.0000000000000002e+92, 1e+93, 1.0000000000000002e+94, 
1.0000000000000002e+95, 1.0000000000000002e+96, 1.0000000000000003e+97, 1.0000000000000003e+98, 1.0000000000000001e+99, 
1.0000000000000002e+100, 1.0000000000000003e+101, 1.0000000000000001e+102, 1.0000000000000002e+103, 1.0000000000000002e+104, 
1.0000000000000002e+105, 1.0000000000000003e+106, 1.0000000000000001e+107, 1.0000000000000003e+108, 1.0000000000000002e+109, 
1.0000000000000002e+110, 1.0000000000000002e+111, 1.0000000000000001e+112, 1.0000000000000002e+113, 1.0000000000000003e+114, 
1.0000000000000002e+115, 1.0000000000000002e+116, 1.0000000000000002e+117, 1.0000000000000002e+118, 1.0000000000000001e+119, 
1.0000000000000003e+120, 1.0000000000000004e+121, 1.0000000000000002e+122, 1.0000000000000003e+123, 1.0000000000000001e+124, 
1.0000000000000001e+125, 1.0000000000000002e+126, 1.0000000000000002e+127, 1.0000000000000003e+128, 1.0000000000000003e+129, 
1.0000000000000003e+130, 1.0000000000000003e+131, 1.0000000000000003e+132, 1.0000000000000003e+133, 1.0000000000000003e+134, 
1.0000000000000003e+135, 1.0000000000000003e+136, 1.0000000000000002e+137, 1.0000000000000002e+138, 1.0000000000000003e+139, 
1.0000000000000003e+140, 1.0000000000000002e+141, 1.0000000000000003e+142, 1.0000000000000002e+143, 1.0000000000000002e+144, 
1.0000000000000003e+145, 1.0000000000000004e+146, 1.0000000000000003e+147, 1.0000000000000003e+148, 1.0000000000000003e+149, 
1.0000000000000003e+150, 1.0000000000000002e+151, 1.0000000000000003e+152, 1.0000000000000004e+153, 1.0000000000000003e+154, 
1.0000000000000002e+155, 1.0000000000000002e+156, 1.0000000000000001e+157, 1.0000000000000003e+158, 1.0000000000000003e+159, 
1.0000000000000003e+160, 1.0000000000000004e+161, 1.0000000000000003e+162, 1.0000000000000003e+163, 1.0000000000000003e+164, 
1.0000000000000003e+165, 1.0000000000000003e+166, 1.0000000000000003e+167, 1.0000000000000004e+168, 1.0000000000000003e+169, 
1.0000000000000003e+170, 1.0000000000000004e+171, 1.0000000000000004e+172, 1.0000000000000003e+173, 1.0000000000000003e+174, 
1.0000000000000003e+175, 1.0000000000000003e+176, 1.0000000000000003e+177, 1.0000000000000004e+178, 1.0000000000000003e+179, 
1.0000000000000002e+180, 1.0000000000000003e+181, 1.0000000000000004e+182, 1.0000000000000003e+183, 1.0000000000000004e+184, 
1.0000000000000004e+185, 1.0000000000000003e+186, 1.0000000000000003e+187, 1.0000000000000002e+188, 1.0000000000000003e+189, 
1.0000000000000003e+190, 1.0000000000000004e+191, 1.0000000000000004e+192, 1.0000000000000005e+193, 1.0000000000000004e+194, 
1.0000000000000004e+195, 1.0000000000000004e+196, 1.0000000000000003e+197, 1.0000000000000005e+198, 1.0000000000000005e+199, 
1.0000000000000005e+200, 1.0000000000000004e+201, 1.0000000000000006e+202, 1.0000000000000003e+203, 1.0000000000000004e+204, 
1.0000000000000004e+205, 1.0000000000000004e+206, 1.0000000000000005e+207, 1.0000000000000004e+208, 1.0000000000000004e+209, 
1.0000000000000004e+210, 1.0000000000000004e+211, 1.0000000000000005e+212, 1.0000000000000004e+213, 1.0000000000000004e+214, 
1.0000000000000005e+215, 1.0000000000000003e+216, 1.0000000000000006e+217, 1.0000000000000005e+218, 1.0000000000000006e+219, 
1.0000000000000005e+220, 1.0000000000000002e+221, 1.0000000000000005e+222, 1.0000000000000004e+223, 1.0000000000000004e+224, 
1.0000000000000006e+225, 1.0000000000000006e+226, 1.0000000000000003e+227, 1.0000000000000004e+228, 1.0000000000000005e+229, 
1.0000000000000003e+230, 1.0000000000000004e+231, 1.0000000000000005e+232, 1.0000000000000004e+233, 1.0000000000000005e+234, 
1.0000000000000003e+235, 1.0000000000000006e+236, 1.0000000000000005e+237, 1.0000000000000005e+238, 1.0000000000000005e+239, 
1.0000000000000004e+240, 1.0000000000000005e+241, 1.0000000000000005e+242, 1.0000000000000005e+243, 1.0000000000000005e+244, 
1.0000000000000004e+245, 1.0000000000000005e+246, 1.0000000000000004e+247, 1.0000000000000005e+248, 1.0000000000000007e+249, 
1.0000000000000004e+250, 1.0000000000000006e+251, 1.0000000000000003e+252, 1.0000000000000004e+253, 1.0000000000000005e+254, 
1.0000000000000004e+255, 1.0000000000000005e+256, 1.0000000000000006e+257, 1.0000000000000005e+258, 1.0000000000000006e+259, 
1.0000000000000005e+260, 1.0000000000000006e+261, 1.0000000000000005e+262, 1.0000000000000006e+263, 1.0000000000000005e+264, 
1.0000000000000006e+265, 1.0000000000000005e+266, 1.0000000000000005e+267, 1.0000000000000005e+268, 1.0000000000000005e+269, 
1.0000000000000005e+270, 1.0000000000000005e+271, 1.0000000000000005e+272, 1.0000000000000005e+273, 1.0000000000000005e+274, 
1.0000000000000006e+275, 1.0000000000000005e+276, 1.0000000000000006e+277, 1.0000000000000006e+278, 1.0000000000000004e+279, 
1.0000000000000004e+280, 1.0000000000000007e+281, 1.0000000000000005e+282, 1.0000000000000006e+283, 1.0000000000000004e+284, 
1.0000000000000005e+285, 1.0000000000000005e+286, 1.0000000000000004e+287, 1.0000000000000005e+288, 1.0000000000000007e+289, 
1.0000000000000006e+290, 1.0000000000000005e+291, 1.0000000000000007e+292, 1.0000000000000006e+293, 1.0000000000000005e+294, 
1.0000000000000007e+295, 1.0000000000000005e+296, 1.0000000000000006e+297, 1.0000000000000005e+298, 1.0000000000000006e+299, 
1.0000000000000006e+300, 1.0000000000000006e+301, 1.0000000000000005e+302, 1.0000000000000006e+303, 1.0000000000000005e+304, 
1.0000000000000005e+305, 1.0000000000000006e+306, 1.0000000000000005e+307, 1.0000000000000006e+308]


# static variables
## Maximum amount of exponent symbols that [method g_to_str] is allowed to write.
static var max_es_in_str: int = 5
## Maximum amount of iterations for LambertW functions.
static var max_i_lambertw: int = 100
## Maximum amount of iterations for [method g_tetrate].
static var max_i_tetra: int = 10000
## Maximum amount of iterations for [method g_pentate].
static var max_i_penta: int = 10
## Maximum amount of iterations for miscellaneous functions.
static var max_i_other: int = 100
## Default round to that [method g_to_str_to_decimal_places] will use.
static var default_round_to: int = 2
# static functions
## Helper function to use the [constant POWERS_OF_TEN] lookup table. Equivalent to [code]pow(10, e)[/code]
static func ipow10(e: int) -> float:
	if NUMBER_EXP_MIN + 1 > e or e > NUMBER_EXP_MAX:
		return INF * signf(e)
	return POWERS_OF_TEN[(e - NUMBER_EXP_MIN - 1)]

# from https://math.stackexchange.com/a/465183
# Please don't change the tolerance unless you know what you're doing
## Returns the solution of [code]W(x) = x * (e ** x)[/code]. 
## [url]https://en.wikipedia.org/wiki/Lambert_W_function[/url]
## [br]This is a multi-valued function in the complex plane, but only two branches matter for real numbers: the "principal branch" W0, and the "non-principal branch" W-1.
static func f_lambertw(z: float, principal: bool = true, tolerance: float = 1e-10) -> float:
	var w: float
	var wn: float
	if principal and -1 / exp(1) < z:
		if !is_finite(z) or z == 0:
			return z
		if z == 1:
			return LAMBERTW_ONE_ZERO

		if (z < 10):
			w = 0
		else:
			w = log(z) - log(log(z))
	elif -1 / exp(1) < z and z < 0:
		if z <= -0.1:
			w = -2
		else:
			w = log(-z) - log(-log(-z))
	elif z >= 0: # the godot way of doing maths, i guess
		return -INF
	else: # i don't think you know what you're doing 
		return NAN
	for i in range(max_i_lambertw):
		wn = (z * exp(-w) + w * w) / (w + 1)
		if absf(wn - w) < tolerance * absf(wn):
			return wn
		else:
			w = wn
		
	assert(false, "f_lambertw: Number {num} failed to converge after {i} iterations".format({
		"num": z,
		"i": max_i_lambertw
	}))
	return NAN


## Normalizes [param n].[br] 
## This is done in-place. If you want to make another normalized number PackedFloat64Array, use [method duplicate_num_only]. [br]
## Does the following stuff:[br]
## - If sign is 0 or (mag and layer is 0), makes all of them 0.[br]
## - If layer is 0 and mag < [constant FIRST_NEG_LAYER] (1/9e15), shifts to first negative layer.[br]
## - increases the layer and lowers the mag (log10(mag)) if mag is above threshold (9e15)
## or lowers the layer and raises the mag (10^mag) if mag is below the layer threshold (15.954).[br]
## [b]Note:[/b] Users of this library should not need to use this function.
static func normalize_n(n: PackedFloat64Array) -> void:
	const l = BigNumArrayIndices.LAYER
	const m = BigNumArrayIndices.MAG
	# Make all partial 0s full 0s
	if n[m] == 0:
		n[l] = 0
		return

	n[l] = floorf(absf(n[l])) * signf(n[l])
	# Handle infinities
	if absf(n[l]) == INF or absf(n[m]) == INF:
		n[l] = INF * signf(n[l]) if signf(n[l]) != 0 else n[m]
		n[m] = INF

	# Shift from layer 0 to negative layers
	if n[l] == 0 and absf(n[m]) < FIRST_NEG_LAYER:
		n[l] += 1 * signf(n[m])
		n[m] = log(absf(n[m]))/log(10)
		return

	var absmag := absf(n[m])
	var signmag := signf(n[m])
	if absmag >= LAYER_UP and is_finite(absmag):
		if n[l] == 0:
			n[l] += 1 * signmag
			n[m] = log(absmag)/log(10)
		else:
			n[l] += 1 * signf(n[l])
			n[m] = signmag * log(absmag)/log(10)
	else:
		while absmag < LAYER_DOWN and n[l] != 0:
			var signlayer = signf(n[l])
			n[l] -= 1 * signlayer
			if n[l] == 0:
				n[m] = pow(10, n[m]) * signlayer
			else:
				n[m]= signmag * pow(10, absmag)
				absmag = absf(n[m])
				signmag = signf(n[m])
		if n[l] == 0 and n[m] == 0:
			push_warning("Magnitude may have been excessively rounded. Your number has been normalized to 0. Sorry!")
	# Handle NANs
	if is_nan(n[l]) or is_nan(n[m]):
		n[l] = NAN
		n[m] = NAN



## A randomized number struct for testing purposes. Does not have proper random distribution.
static func testable_random_num_struct(max_layer: float = 2.0 ** 1023.0, rng: RandomNumberGenerator = null) -> PackedFloat64Array:
	var v: PackedFloat64Array = BIGNUM_ZERO.duplicate()
	if not is_instance_valid(rng):
		rng = RandomNumberGenerator.new()
		rng.randomize()

	# WEIGHTS: 5% 0, 2.5% each for 1 or -1;
	# Otherwise, pick a random layer, 
	# then 10% to make it a simple power of 10
	# then 10% to trunc the mag

	var roll1 := rng.randf()

	if roll1 <= 0.05:
		return v # 0

	if roll1 <= 0.1:
		v[0] = 1
		if roll1 <= 0.075:
			v[0] = -1
		return v # -1, 1
	v[0] = rng.rand_range(0, max_layer + 1)

	var roll2 := rng.randf()
	var random_exp :float
	if v[0] == 0:
		random_exp = rng.randf() * 616 - NUMBER_EXP_MAX
	else:
		random_exp = rng.randf() * 16
	if roll2 <= 0.1:
		random_exp = floorf(random_exp)
	v[1] = pow(10, random_exp)
	var roll3 := rng.randf()
	if roll3 <= 0.1:
		v[1] = floorf(v[1])
	return v

## Converts the number to a [float].
## This may return 0 or [constant INF] since floats cannot support numbers as large as numbers of this library.
static func to_float(n: PackedFloat64Array) -> float:
	if not is_finite(n[0]):
		return n[0]
	if not is_finite(n[1]):
		return n[1]
	if n[0] == 0:
		return n[1]
	if absf(n[0]) == 1:
		return (10 ** n[1]) * signf(n[0])
	if absf(n[0]) > 0 and n[1] > 0: # Should be overflowing for normalized numbers
		return INF * signf(n[0])
	return 0

## Creates a new normalized number from the given components.
static func from_components(num_sign: int, layer: float, mag: float) -> PackedFloat64Array:
	var v: PackedFloat64Array = from_components_no_normalize(num_sign, layer, mag)
	
	normalize_n(v)
	
	return v

# no_normalize is a lie, this normalizes the sign
## Creates a new number from the given components.
static func from_components_no_normalize(num_sign: int, layer: float, mag: float) -> PackedFloat64Array:
	if num_sign == 0:
		return [0, 0]
	if layer > 0:
		return [absf(layer) * num_sign, mag]
	return [0, absf(mag) * num_sign]

## Creates a new normalized number from the given [float].[br]
## [b]Note:[/b] Godot should be able to coerce an [int] to a [float].
static func from_float(num: float) -> PackedFloat64Array:
	var v: PackedFloat64Array = from_float_no_normalize(num)
	
	normalize_n(v)
	
	return v

## Creates a new number from the given [float].[br]
## [b]Note:[/b] Godot should be able to coerce an [int] to a [float].
static func from_float_no_normalize(num: float) -> PackedFloat64Array:
	return [0, num]

## Return a normalized copy of [param n].
static func duplicate_num_only(n: PackedFloat64Array) -> PackedFloat64Array:
	var v: PackedFloat64Array = duplicate_num_only_no_normalize(n)
	
	normalize_n(v)
	
	return v

## Returns an exact copy of [param n] as a bignum. 
## Currently implemented as an alias of calling [code]n.slice(0, 2)[/code]
static func duplicate_num_only_no_normalize(n: PackedFloat64Array) -> PackedFloat64Array:
	return n.slice(0, 2)



# number engine @ from_str(): Exponent too high
## Converts a string into the number form. Accepted input formats: [codeblock]
## M === M
## eX === 10^X
## MeX === M*10^X
## eXeY === 10^(XeY)
## MeXeY === M*10^(XeY)
## eeX === 10^10^X
## eeXeY === 10^10^(XeY)
## eeeX === 10^10^10^X
## eeeXeY === 10^10^10^(XeY)
## eeee... (N es) X === 10^10^10^ ... (N 10^s) X
## (e^N)X === 10^10^10^ ... (N 10^s) X
## N PT X === 10^10^10^ ... (N 10^s) X
## N PT (X) === 10^10^10^ ... (N 10^s) X
## NpX === 10^10^10^ ... (N 10^s) X
## FN === 10^10^10^ ... (N 10^s)
## XFN === 10^10^10^ ... (N 10^s) X
## X^Y === X^Y
## X^^N === X^X^X^ ... (N X^s) 1
## X^^N;Y === X^X^X^ ... (N X^s) Y
## X^^^N === X^^X^^X^^ ... (N X^^s) 1
## X^^^N;Y === X^^X^^X^^ ... (N X^^s) Y
## [/codeblock]
static func from_str(text: String, linear_hyper: bool = false) -> PackedFloat64Array:
	text = text.to_lower()

	# Handle string inputs explicitly wanting a certain special value (NAN, INF, -INF)
	if text.begins_with("inf"):
		return BIGNUM_INF.duplicate()
	if text.begins_with("-inf"):
		return BIGNUM_NEG_INF.duplicate()
	if text.begins_with("nan"):
		return BIGNUM_NAN.duplicate()
	
	# Handle X^^^Y;Z format
	if text.get_slice_count("^^^") == 2:
		var base := text.get_slice("^^^", 0).to_float()
		var height := text.get_slice("^^^", 1).to_float()
		var height_parts := text.get_slice("^^^", 1).split(";")
		var payload: float = 1.0
		if len(height_parts) == 2:
			payload = height_parts[1].to_float()
			if not is_finite(payload):
				payload = 1
				if is_finite(base) and is_finite(height):
					return g_pentate(from_float(base), height, from_float(base), true)
	# Handle X^^Y;Z format
	if text.get_slice_count("^^") == 2:
		var tetra_parts := text.split("^^")
		var base := tetra_parts[0].to_float()
		var height_parts := tetra_parts[1].split_floats(";")
		var n_exp := height_parts[0]
		var payload: float = 1
		if len(height_parts) == 2:
			payload = height_parts[1]
			if not is_finite(payload):
				payload = 1
		if is_finite(base) and is_finite(n_exp):
			return g_tetrate(from_float(base), from_float(n_exp), from_float(payload), linear_hyper)

	# Handle X ^ Y format.
	# JS's parseFloat() returns NaN if the whole string isn't a valid float. Godot's String.to_float() doesn't do that, so I have to check if the first slice ends at e instead.
	if text.get_slice_count("^") == 2 and (not text.get_slice("^", 0).ends_with("e")):
		var pow_parts := text.split("^")
		var base := pow_parts[0].to_float()
		var n_exp := pow_parts[1].to_float()
		if is_finite(base) and is_finite(n_exp):
			return g_pow(from_float(base), from_float(n_exp))

	# Non ^ bignum notations
	text = text.strip_edges()
	
	# Handle the 10^^X;Y tetras (X PT Y, X P(Y) and X F(Y))
	const BASE10_TETRA_SYMBOLS = ["pt", "p", "f"]
	for s in BASE10_TETRA_SYMBOLS:
		if text.get_slice_count(s) == 2:
			var text2 := text.replace("(", "").replace(")", "")
			var base := from_float(10)
			var base10_tetra_parts := text2.split(s)
			var j: int = 1 if s == "f" else 0 # SORRY
			var k: int = 0 if s == "f" else 1
			var payload := base10_tetra_parts[j].to_float()
			var n_exp := base10_tetra_parts[k].to_float()
			if not is_finite(payload):
				payload = 1
			if is_finite(n_exp):
				return g_tetrate(base, from_float(n_exp), from_float(payload), linear_hyper)
	var _is_neg: bool = text.begins_with("-")

	# Handle the current (e^x)y format.
	if text.get_slice_count("e^") == 2:
		var current: PackedFloat64Array = []
		var s2: String = text.get_slice("e^", 1)
		for c in s2:
			var c_code := c.unicode_at(0) 
			# character is "0" to "9" or "+" or "-" or "." or "e" (or "," or "/")
			if not((43 <= c_code and c_code <= 57) or c_code == 101):
				# we found the end of the layer count
				current = s2.split_floats(c)
				# Handle invalid cases like (e^-8)1 and (e^10.5)1 by just calling tetrate
				if (current[0] < 0) or (not is_zero_approx(fposmod(current[0], 1))):
					current = g_tetrate(from_float(10), from_float(current[0]), from_float(current[1]), linear_hyper)
				normalize_n(current)
				return current
	var ecount: int = text.get_slice_count("e") - 1
	var n_exp2: float = text.get_slice("e", ecount).to_float()
	
	if (ecount == 0) or ((ecount == 1) and (n_exp2 <= 308)):
		#ignore_warning: Exponent too high # i know what i'm doing godot, shut up with your runtime warnings
		
		var n : float = text.to_float()
		if is_finite(n) and (absf(n) > LOWEST_POSITIVE_NORMAL_FLOAT):
			return from_float(n)
	var v: PackedFloat64Array = BigNumRef.BIGNUM_ZERO.duplicate()

	# Godot can't split a valid but beyond range float to (mantissa, exponent) values
	# with the String.split_floats() method
	var m := text.get_slice("e", 0).to_float()
	if m == 0:
		return BigNumRef.BIGNUM_ZERO.duplicate()
	# handle numbers like XeYeZ, Xe... (N es) YeZ  
	if ecount >= 2:
		var me := text.get_slice("e", ecount - 1).to_float()
		if (absf(me) >= (1.0 + 1e-10)) and is_finite(me):
			v[1] *= signf(me)
			v[1] += signf(me) * log(absf(me))/log(10)
	# handle numbers like eee... (N es) X
	if (absf(m) <= (1.0 + 1e-10)) or (not is_finite(m)) or ecount > 2: 
		v[0] = (ecount) * signf(m)
		v[1] = n_exp2
	# handle numbers like XeY
	if ecount == 1:
		v[0] = 1 * signf(m)
		v[1] = n_exp2 + log(absf(m))/log(10)
	# handle numbers like Xe...Y
	else:
		return g_mul(from_components(1, 2, n_exp2), from_float(m))
	normalize_n(v)
	return v

## Tries to create a new number from a [Variant].
static func from_v_no_normalize(arg) -> PackedFloat64Array:
	match typeof(arg):
		TYPE_FLOAT, TYPE_INT:
			return from_float_no_normalize(arg)
		TYPE_STRING:
			return from_str(arg)
		TYPE_PACKED_FLOAT64_ARRAY:
			return duplicate_num_only_no_normalize(arg)
		TYPE_DICTIONARY:
			if "sign" in arg and arg.sign is int and "layer" in arg and arg.layer is float and "mag" in arg and arg.mag is float:
				return from_components_no_normalize(arg.sign, arg.layer, arg.mag)
			push_error("Cannot construct number from dictionary '{arg}'.".format({"arg": arg}))
			return BIGNUM_NAN.duplicate()
		TYPE_OBJECT:
			if "d" in arg and is_bignum(arg.d):
				return arg.d
			push_error("Cannot construct number from object '{arg}'.".format({"arg": arg}))
			return BIGNUM_NAN.duplicate()
		TYPE_BOOL:
			return BigNumRef.BIGNUM_ONE if arg else BigNumRef.BIGNUM_ZERO
		_:
			push_error("Cannot construct number from parameter type '{type}' '{arg}'.".format({"arg": arg, "type": type_string(typeof(arg))}))
			return BIGNUM_NAN.duplicate()

# this is what i get for... not storing sign separately
static func from_bytes_no_normalize(data: PackedByteArray) -> PackedFloat64Array:
	if data.size() < 16:
		return BIGNUM_NAN.duplicate()
	# var is_neg: bool = data.decode_u8(0) 
	# var layer: float = absf(data.decode_double(0))
	# var mag: float = data.decode_double(8)
	return [data.decode_double(0), data.decode_double(8)]

static func from_bytes(data: PackedByteArray) -> PackedFloat64Array:
	var v: PackedFloat64Array = from_bytes_no_normalize(data)

	normalize_n(v)

	return v

## Tries to create a new normalized number from a [Variant].
static func from_v(arg) -> PackedFloat64Array:
	var v: PackedFloat64Array = from_v_no_normalize(arg)

	normalize_n(v)

	return v

## Returns the sign of the number.
static func g_sign(n: PackedFloat64Array) -> int:
	@warning_ignore_start("narrowing_conversion")
	if signf(n[0]) != 0:
		return signf(n[0])
	return signf(n[1])
	@warning_ignore_restore("narrowing_conversion")

static func g_get_mantissa(n: PackedFloat64Array) -> float:
	if n[1] == 0:
		return 0
	if n[0] == 0:
		# if is_zero_approx(n[1]):  # Doesn't happen, 1e-298 is below the layer -1 threshold
		# 	return 5 * g_sign(n)
		var e: int = floori(log(absf(n[1]))/log(10))
		var _ef: float = ipow10(e)
		return n[1] / _ef
	if absf(n[0]) == 1:
		return g_sign(n) * 10 ** fposmod(n[1], 1)
	return g_sign(n)

static func g_get_exp(n: PackedFloat64Array) -> float:
	if n[1] == 0:
		return 0
	if n[0] == 0:
		return floorf(log(absf(n[1]))/log(10))
	if absf(n[0]) == 1:
		return floorf(n[1])
	if absf(n[0]) == 2:
		return signf(n[1]) * 10 ** floorf(absf(n[1]))
	return INF

## Returns a string representation of [param n].
static func g_to_str(n: PackedFloat64Array) -> String:
	if g_is_nan(n):
		return "nan"
	if !g_is_finite(n):
		return "-inf" if g_sign(n) == -1 else "inf"
	if n[0] == 0:
		if (1e-7 < absf(n[1]) and absf(n[1]) < EXPONENT_WRITTEN) or n[1] == 0:
			return var_to_str(n[1])
		return "{m}e{e}".format({"m": g_get_mantissa(n), "e": g_get_exp(n)})
	if absf(n[0]) == 1:
		if (n[1] < EXPONENT_WRITTEN):
			return "{m}e{e}".format({"m": g_get_mantissa(n), "e": var_to_str(g_get_exp(n)).get_slice(".", 0)})
		return "{m}e{e}".format({"m": g_get_mantissa(n), "e": g_get_exp(n)})
	if absf(n[0]) <= max_es_in_str:
		if g_sign(n) == -1:
			return "-1{l}{e}".format({"e": n[1], "l": "e".repeat(floori(absf(n[0])))})
		return "1{l}{e}".format({"e": n[1], "l": "e".repeat(floori(absf(n[0])))})
	if n[0] < 0:
		return "-1(e^{l}){e}".format({"e": n[1], "l": absf(n[0])})
	return "1(e^{l}){e}".format({"e": n[1], "l": absf(n[0])})

## Returns a string representation of [param n], with up to [member round_to] decimal digits.
static func g_to_str_to_decimal_places(n: PackedFloat64Array, round_to: int = default_round_to) -> String:
	if g_is_nan(n):
		return "NAN"
	if !g_is_finite(n):
		return "-inf" if g_sign(n) == -1 else "inf"
	if n[1] < ipow10(-round_to):
		return "0.0"
	if n[0] == 0:
		if (absf(n[1]) < EXPONENT_WRITTEN) or n[1] == 0:
			return var_to_str(snappedf((n[1] * g_sign(n)), ipow10(-round_to)))
		return "{m}e{e}".format({"m": snappedf(g_get_mantissa(n), ipow10(-round_to)), "e": g_get_exp(n)})
	if n[0] == 1:
		if (absf(n[1]) < EXPONENT_WRITTEN):
			return "{m}e{e}".format({"m": snappedf(g_get_mantissa(n), ipow10(-round_to)), "e": var_to_str(g_get_exp(n)).get_slice(".", 0)})
		# return "{m}e{e}".format({"m": snappedf(g_get_mantissa(n), ipow10(-round_to)), "e": snappedf(g_get_exp(n), ipow10(-round_to))})
		return "{m}e{e}".format({"m": g_get_mantissa(n), "e": g_get_exp(n),})
	if n[0] <= max_es_in_str:
		if g_sign(n) == -1:
			return "-1{l}{e}".format({"e": n[1], "l": "e".repeat(floori(n[0]))})
		return "1{l}{e}".format({"e": n[1], "l": "e".repeat(floori(n[0]))})
	if g_sign(n) == -1:
		return "-1(e^{l}){e}".format({"e": n[1], "l": n[0]})
	return "1(e^{l}){e}".format({"e": n[1], "l": n[0]})

## Returns [code]n1 == n2[/code].
## Prefer using n1 == n2 directly for performance, unless you aren't sure both of them have exactly two elements.
static func g_eq(n1: PackedFloat64Array, n2: PackedFloat64Array)-> bool:
	return (n1[0] == n2[0] and n1[1] == n2[1])

## Returns whether the absolute value of both [param n1] and [param n2] are exactly equal.
static func g_eq_abs(n1: PackedFloat64Array, n2: PackedFloat64Array) -> bool:
	return (absf(n1[0]) == absf(n2[0]) and ((n1[1] == n2[1]) or ((n1[0] == 0) and absf(n1[1]) == absf(n2[1]))))

## Returns 1 if [param n1] is greater, 0 if equal, -1 if [param n2] is greater.
static func g_compare(n1: PackedFloat64Array, n2: PackedFloat64Array) -> int:
	@warning_ignore_start("narrowing_conversion")
	if n1[0] == 0 and n2[0] == 0:
		return signf(n1[1] - n2[1])
	if signf(n1[0]) != signf(n2[0]):
		return signf(n1[0]) - signf(n2[0])
	return g_compare_abs(n1, n2)
	@warning_ignore_restore("narrowing_conversion")

## Returns 1 if the absolute value of [param n1] is greater, 0 if equal, -1 if [param n2] is greater.
static func g_compare_abs(n1: PackedFloat64Array, n2: PackedFloat64Array) -> int:
	@warning_ignore_start("narrowing_conversion")
	if n1[0] == 0 and n2[0] == 0:
		return signf(absf(n1[1]) - absf(n2[1]))
	var l_a: float = signf(n1[1]) * absf(n1[0])
	var l_b: float = signf(n2[1]) * absf(n2[0])
	if l_a != l_b:
		return signf(l_a - l_b)
	return signf(n1[1] - n2[1])
	@warning_ignore_restore("narrowing_conversion")

## Returns the greater number between two numbers.
static func g_num_max(n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if g_compare(n1, n2) == 1:
		return duplicate_num_only(n1)
	return duplicate_num_only(n2)

## Returns the greater number between the absolute value of two numbers.
static func g_num_max_abs(n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if g_compare_abs(n1, n2) == 1:
		return duplicate_num_only(n1)
	return duplicate_num_only(n2)

## Returns the lesser number between two numbers.
static func g_num_min(n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if g_compare(n1, n2) == -1:
		return duplicate_num_only(n1)
	return n2

## Returns the lesser number between the absolute value of two numbers.
static func g_num_min_abs(n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	if g_compare_abs(n1, n2) == -1:
		return duplicate_num_only(n1)
	return duplicate_num_only(n2)

## Returns [code]n1 > n2[code].
static func g_gt(n1: PackedFloat64Array, n2: PackedFloat64Array) -> bool:
	return g_compare(n1, n2) > 0

## Returns [code]n1 >= n2[code].
static func g_gte(n1: PackedFloat64Array, n2: PackedFloat64Array) -> bool:
	return g_compare(n1, n2) >= 0

## Returns [code]n1 < n2[code].
static func g_lt(n1: PackedFloat64Array, n2: PackedFloat64Array) -> bool:
	return g_compare(n1, n2) < 0

## Returns [code]n1 <= n2[code].
static func g_lte(n1: PackedFloat64Array, n2: PackedFloat64Array) -> bool:
	return g_compare(n1, n2) <= 0

## Clamps the value of [param n] between [param n_min] and [n_max].
static func g_clamp(n: PackedFloat64Array, n_min: PackedFloat64Array, n_max: PackedFloat64Array) -> PackedFloat64Array:
	return g_num_max(g_num_min(n, n_min), n_max)

## Returns whether [param n] holds a proper bignum. Currently implemented as an alias of [code]n.size() >= 2[/code]
static func is_bignum(n: PackedFloat64Array)-> bool:
	return n.size() >= 2

## Returns whether [param n] is a bignum that holds NAN, or if [method is_bignum] returns false(as the array is Not (holding) A Number)[br]
## Use [method is_bignum] to only check if the array holds a bignum, without checking if the number held is NAN.[br]
## See also [method g_is_strictly_nan]
static func g_is_nan(n: PackedFloat64Array)-> bool:
	if not is_bignum(n):
		return true
	return is_nan(n[1]) or is_nan(n[0])

## Returns whether [param n] is a bignum that holds NAN. Returns false if [param n] does not hold a bignum.
static func g_is_strictly_nan(n: PackedFloat64Array)-> bool:
	if not is_bignum(n):
		return false
	return is_nan(n[1]) or is_nan(n[0])


## Returns whether the number is finite or not (by this library's standards).
## Returns false if [param n] does not hold a bignum.
static func g_is_finite(n: PackedFloat64Array)-> bool:
	if not is_bignum(n):
		return false
	return is_finite(n[1]) and is_finite(n[0])

## Returns true if [param n1] and [param n2] are approximately equal to each other.[br]
## [param rel_e] is a relative epsilon, multiplied by the greater of the magnitudes of the two arguments.
static func g_eq_approx(n1: PackedFloat64Array, n2: PackedFloat64Array, rel_e: float = 1e-7) -> bool:
	if g_is_nan(n1) or g_is_nan(n2):
		return false
	# Can't multiply two positive numbers to become a negative number
	if g_sign(n1) != g_sign(n2):
		return false
	if absf(n1[0] - n2[0]) > 1:
		return false
	# https://stackoverflow.com/a/33024979
	# return abs(a-b) <= tolerance * max(abs(a), abs(b))
	var mag_a: float = n1[1]
	var mag_b: float = n2[1]
	if n1[0] > n2[0]:
		mag_a = signf(mag_a) * log(absf(mag_a))/log(10)
	elif n2[0] > n1[0]:
		mag_b = signf(mag_b) * log(absf(mag_b))/log(10)
	return absf(mag_a - mag_b) <= rel_e * maxf(absf(mag_a), absf(mag_b))

## Returns true if the absolute values of [param n1] and [param n2] are approximately equal to each other.[br]
## [param rel_e] is a relative epsilon, multiplied by the greater of the magnitudes of the two arguments.
static func g_eq_abs_approx(n1: PackedFloat64Array, n2: PackedFloat64Array, rel_e: float = 1e-7) -> bool:
	if g_is_nan(n1) or g_is_nan(n2):
		return false
	if absf(absf(n1[0]) - absf(n2[0])) > 1:
		return false
	var mag_a: float = absf(n1[1]) if n1[0] == 0 else n1[1]
	var mag_b: float = absf(n2[1]) if n2[0] == 0 else n2[1]
	
	if absf(n1[0]) > absf(n2[0]):
		mag_a = signf(mag_a) * log(absf(mag_a))/log(10)
	elif absf(n2[0]) > absf(n1[0]):
		mag_b = signf(mag_b) * log(absf(mag_b))/log(10)
	return absf(mag_a - mag_b) <= rel_e * maxf(absf(mag_a), absf(mag_b))
## Returns 1 if [param n1] is greater, 0 if approximately equal, -1 if [param n2] is greater.[br]
## [param rel_e] is a relative tolerance, multiplied by the greater of the magnitudes of the two arguments.
## See [method g_eq_approx].
static func g_compare_approx(n1: PackedFloat64Array, n2: PackedFloat64Array, rel_e: float = 1e-7) -> int:
	if g_eq_approx(n1, n2, rel_e):
		return 0
	return g_compare(n1, n2)

## Returns [code]n1 > n2[/code], with approximately equal values also being FALSE.
## See [method g_eq_approx].
static func g_gt_approx(n1: PackedFloat64Array, n2: PackedFloat64Array, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) > 0

## Returns [code]n1 >= n2[/code], with approximately equal values also being TRUE.
## See [method g_eq_approx].
static func g_gte_approx(n1: PackedFloat64Array, n2: PackedFloat64Array, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) >= 0

## Returns [code]n1 < n2[/code], with approximately equal values also being FALSE.
## See [method g_eq_approx].
static func g_lt_approx(n1: PackedFloat64Array, n2: PackedFloat64Array, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) < 0

## Returns [code]n1 <= n2[/code], with approximately equal values also being TRUE.
## See [method g_eq_approx].
static func g_lte_approx(n1: PackedFloat64Array, n2: PackedFloat64Array, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) <= 0


## Rounds the number downwards(towards negative infinity).[br]
## [param round_small_nums]: Whether to round numbers that are extremely close to 0 or not.
static func g_floor(n: PackedFloat64Array, round_small_nums: bool = false) -> PackedFloat64Array:
	if n[0] == 0:
		return [0, floorf(n[1])]
	if n[0] != 0 and (n[1] > 0 or (not round_small_nums)):
		return duplicate_num_only(n)
	if n[0] >= 1 and n[1] < 0:
		return BIGNUM_ZERO.duplicate()
	else:
		return BIGNUM_NEG_ONE.duplicate()
	

## Rounds the number upwards(towards positive infinity).[br]
## [param round_small_nums]: Whether to round numbers that are extremely close to 0 or not.
static func g_ceil(n: PackedFloat64Array, round_small_nums: bool = false) -> PackedFloat64Array:
	return g_neg(g_floor(g_neg(n), round_small_nums))

## Rounds the number towards 0.
## This is equivalent to coercing a [float] to an [int], excluding very large floats.
## [param round_small_nums]: Whether to round numbers that are extremely close to 0 or not.
static func g_trunc(n: PackedFloat64Array, round_small_nums: bool = false) -> PackedFloat64Array:
	if n[0] == 0:
		return [0, floorf(n[1]) if n[1] > 0 else ceilf(n[1])]
	if round_small_nums and n[1] < 0:
		return BIGNUM_ZERO.duplicate()
	return duplicate_num_only(n)

## Returns -n.
static func g_neg(n: PackedFloat64Array) -> PackedFloat64Array:
	return from_components(-g_sign(n), n[0], n[1])

## Returns the absolute value of [param n]. (i.e. non-negative value)
static func g_abs(n: PackedFloat64Array) -> PackedFloat64Array:
	return from_components(absi(g_sign(n)), n[0], n[1])

## Returns [code]1/n[/code].
static func g_recip(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] == 0:
		return BIGNUM_NAN.duplicate()
	if n[0]  == 0:
		return [0, 1 / n[1]]
	return [n[0], -n[1]]

## Returns the remainder of [param n1] divided by [param n2], keeping the sign of [param n1].
static func g_mod(n1: PackedFloat64Array, n2: PackedFloat64Array)-> PackedFloat64Array:
	if g_eq(n2, BIGNUM_ZERO) or g_eq(n1, BIGNUM_ZERO) or g_eq(n2, n1):
		return BIGNUM_ZERO.duplicate()
	
	# Special case: To avoid precision issues, if both numbers are valid floats, just call fmod on those
	if is_finite(to_float(n1)) and is_finite(to_float(n2)):
		return from_float(fmod(to_float(n1), to_float(n2)))
	
	if g_eq(n1, g_sub(n1, n2)):
	# Godot returns 0 on n1 way greater than n2
		return BIGNUM_ZERO.duplicate()

	# Special case: if n2 is greater than n1, just return n1
	if g_compare_abs(n1, n2) < 0:
		return duplicate_num_only(n1)

	return g_sub(n1,g_mul(g_trunc(g_div(n1,n2)),n2))

## Returns the modulo of [param n1] divided by [param n2], keeping the sign of [param n2].
static func g_posmod(n1: PackedFloat64Array, n2: PackedFloat64Array)-> PackedFloat64Array:
	if g_eq(n2, BIGNUM_ZERO) or g_eq(n1, BIGNUM_ZERO) or g_eq(n2, n1):
		return BIGNUM_ZERO.duplicate()

	# Special case: To avoid precision issues, if both numbers are valid floats, just call fposmod on those
	if is_finite(to_float(n1)) and is_finite(to_float(n2)):
		return from_float(fposmod(to_float(n1), to_float(n2)))

	if g_eq(n1, g_sub(n1, n2)):
	# Godot returns 0 on n1 way greater than n2
		return BIGNUM_ZERO.duplicate()

	return g_sub(n1,g_mul(g_floor(g_div(n1,n2)),n2))

## Returns [code]n1 + n2[/code].
static func g_add(n1: PackedFloat64Array, n2: PackedFloat64Array)-> PackedFloat64Array:

	# Inf/NAN check
	if not g_is_finite(n1):
		return n1
	if not g_is_finite(n2):
		return n2
	# n + 0 = n
	if g_eq(n1, BigNumRef.BIGNUM_ZERO):
		return n2
	if g_eq(n2, BigNumRef.BIGNUM_ZERO):
		return n1
	# n - n = 0
	if g_compare_abs(n1, n2) == 0 and (not g_eq(n1, n2)):
		return BigNumRef.BIGNUM_ZERO.duplicate()
	


	# If any of the numbers is layer 2 or bigger, just take the higher number.
	if (absf(n1[0]) >= 2 || absf(n2[0]) >= 2):
		return g_num_max_abs(n1, n2)
	
	if (n1[0] == 0 and n2[0] == 0):
		# Simply add the numbers together.
		return from_float(n1[1] + n2[1])
	
	var dec1: PackedFloat64Array = duplicate_num_only(n1)
	var dec2: PackedFloat64Array = duplicate_num_only(n2)
	if g_compare_abs(dec1, dec2) < 0:
		var temp: PackedFloat64Array = dec2
		dec2 = dec1
		dec1 = temp

	var layer1: float = absf(dec1[0]) * signf(dec1[1])
	var layer2: float = absf(dec2[0]) * signf(dec2[1])
	
	# If one of the numbers is 2+ layers higher than the other, just take the bigger number.
	if absf(layer1 - layer2) >= 2:
		return dec1
	@warning_ignore_start("narrowing_conversion")
	if layer1 == 0 and layer2 == -1:
		if absf(absf(dec2[1]) - (log(absf(dec1[1]))/log(10))) > MAX_FLOAT_PRECISION:
			return dec1
		else:
			var magdiff: float = pow(10, log(absf(dec1[1]))/log(10) - dec2[1])
			var mantissa: float = signf(dec1[1]) * magdiff + signf(dec2[0])
			return from_components(signi(mantissa), 1, dec2[1] + log(absf(mantissa))/log(10))

	if layer1 == 1 and layer2 == 0:
		if absf(absf(dec1[1]) - (log(dec2[1])/log(10))) > MAX_FLOAT_PRECISION:
			return dec1
		else:
			var magdiff: float = pow(10, dec1[1] - log(absf(dec2[1]))/log(10))
			var mantissa: float = signf(dec1[0]) * magdiff + signf(dec2[1])
			return from_components(
				signf(mantissa), 
				1, 
				log(absf(dec2[1]))/log(10) + log(absf(mantissa))/log(10)
			)

	if absf(dec1[1] - dec2[1]) > MAX_FLOAT_PRECISION:
		return dec1
	else:
		var magdiff: float = pow(10, dec1[1] - dec2[1])
		var mantissa: float = signf(dec1[0]) * magdiff + signf(dec2[0])
		
		return from_components(signi(mantissa), 1, dec2[1] + log(absf(mantissa))/log(10))
	@warning_ignore_restore("narrowing_conversion")
	# Unreachable
	#assert(false, "Failed to add {dec1} and {dec2}, throwing out 0".format({
		#"dec1": dec1,
		#"dec2": dec2
	#}))
	#return BIGNUM_ZERO.duplicate()

## Returns [code]n1 - n2[/code].
static func g_sub(n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	return g_add(n1, g_neg(n2))

## Returns [code]n1 * n2[/code].
static func g_mul(n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:

	if g_is_nan(n1) or g_is_nan(n2):
		return BIGNUM_NAN.duplicate()

	# n * 0 yields 0
	if g_eq(n1, BIGNUM_ZERO) or g_eq(n2, BIGNUM_ZERO):
		# 0 * inf = NAN (also prevents 0/0 from returning a valid number)
		if not (g_is_finite(n1) and g_is_finite(n2)):
			return BIGNUM_NAN.duplicate()
		return BIGNUM_ZERO.duplicate()
	
	if n1[0] == 0 and n2[0] == 0:
		# Number is not enough to get into the power tower, just multiply it normally
		return from_float(n1[1] * n2[1])

	var new_sign: int = g_sign(n1) * g_sign(n2)
	# n * (1 / n) yields 1
	if absf(n1[0]) == absf(n2[0]) and n1[1] == -n2[1]:
		return [0, new_sign]

	var m: PackedFloat64Array
	var n: PackedFloat64Array
	if absf(n1[0]) > absf(n2[0]) or (absf(n1[0]) == absf(n2[0]) and absf(n1[1]) > absf(n2[1])):
		m = n1
		n = n2
	else:
		m = n2
		n = n1

	# Multiplication is insigficant, return the bigger number instead.
	if absf(m[0]) >= 3 or (absf(m[0]) - absf(n[0])) >= 2:
		return m.duplicate()

	if absf(m[0]) == 1 and absf(n[0]) == 0:
		return from_components(new_sign , 1, m[1] + log(absf(n[1]))/log(10))

	if absf(m[0]) == 1 and absf(n[0]) == 1:
		return from_components(new_sign , 1, m[1] + n[1])
	else: # if absf(m[0]) == 2 and (absf(n[0]) == 1 or absf(n[0]) == 2):
		@warning_ignore_start("narrowing_conversion")
		var result := from_components(signi(m[1]), 1, absf(m[1]))
		result = g_add(result, from_components(signi(n[1]), absf(n[0] - 1), absf(n[1])))
		@warning_ignore_restore("narrowing_conversion")
		return [result[0] + signf(result[0]), result[1]]
	# unreachable
	# assert(false, "Failed to multiply {n1} and {n2}, throwing out NaN".format({
	# 	"n1": n1,
	# 	"n2": n2
	# }))
	# return BIGNUM_NAN.duplicate()

## Returns [code]n1 / n2[/code].
static func g_div(n1: PackedFloat64Array, n2: PackedFloat64Array) -> PackedFloat64Array:
	return g_mul(n1, g_recip(n2))

## Returns the number so that 
## [code]abs(10 ** result) == n[/code].
static func g_abs_log10(n: PackedFloat64Array) -> PackedFloat64Array:

	if g_sign(n) == 0:
		return BIGNUM_NAN.duplicate()
	if n[0] > 0:
		@warning_ignore("narrowing_conversion")
		return from_components(signi(n[1]), n[0] - 1, absf(n[1]))
	return from_components(1, 0, log(n[1])/log(10))

## Returns the number so that 
## [code]10 ** result == n[/code].
static func g_log10(n: PackedFloat64Array) -> PackedFloat64Array:
	if g_sign(n) <= 0:
		return BIGNUM_NAN.duplicate()
	if n[0] > 0:
		@warning_ignore("narrowing_conversion")
		return from_components(signi(n[1]), n[0] - 1, absf(n[1]))
	return duplicate_num_only([0, log(n[1])])

## The natural exponential function. Returns [i]e[/i] ** n, where [i]e[/i] is a mathematical constant with an approximate value of 2.71828.
static func g_exp(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[0] == 0:
		if absf(n[1]) <= 709.7:
			return from_float(exp(n[1]))
		return from_components(1, 1, g_sign(n) / log(10) * n[1])
	if n[1] < 0:
		return BIGNUM_ONE.duplicate()
	if n[0] == 1:
		return from_components(1, 2, g_sign(n) * ((1/log(10)) + n[1]))
	return from_components(1, n[0] + 1, g_sign(n) * n[1])

## Returns the number you need to raise [param base] with in order to result in [param to].
static func g_log(base: PackedFloat64Array, to: PackedFloat64Array) -> PackedFloat64Array:
	if g_lt(to, BIGNUM_ZERO) or g_lte(base, BIGNUM_ZERO):
		return BIGNUM_NAN.duplicate()
	if g_eq(BIGNUM_ZERO, to):
		return BIGNUM_NEG_INF.duplicate()
	if base[1] == 1 and base[0] == 0:
		return BIGNUM_NAN.duplicate()
	if base[0] == 0 and to[0] == 0:
		@warning_ignore("narrowing_conversion")
		return from_components(1 if to[1] > 1 else -1, 0, log(to[1]) / log(base[1]))
	
	return g_div(g_log10(to), g_log10(base))

## Raises [param base] to the power of [param n_exp].
static func g_pow(base: PackedFloat64Array, n_exp: PackedFloat64Array) -> PackedFloat64Array:
	# Godot returns NAN on 0^0
	if g_eq(base, BIGNUM_ZERO) and g_eq(n_exp, BIGNUM_ZERO):
		push_error("Cannot raise 0 to the power of 0")
		return BIGNUM_NAN.duplicate()
	# n^0 == 1
	if g_eq(n_exp, BIGNUM_ZERO):
		return BIGNUM_ONE.duplicate()
	# 0^x == 0 
	if g_eq(base, BIGNUM_ZERO):
		return BIGNUM_ZERO.duplicate()
	# examine pow on floats for both precision and speed
	if base[0] == 0 and n_exp[0] == 0:
		var float_test: float = pow(base[1], n_exp[1])
		if is_finite(float_test) and absf(float_test) >= LOWEST_POSITIVE_NORMAL_FLOAT:
			return from_float(float_test)
	# n^1 == n # 1^x == 1
	if g_eq(n_exp, BIGNUM_ONE) or g_eq(base, BIGNUM_ONE):
		return duplicate_num_only(base)

	var n2: PackedFloat64Array = duplicate_num_only(base)
	n2 = g_abs_log10(n2)
	n2 = g_mul(n2, n_exp)
	n2 = g_pow10(n2)
	
	
	if g_sign(base) == -1:
		if abs(n_exp[0]) % 1.0 != 0.0: # Fractional: Complex
			return BIGNUM_NAN.duplicate()
		if abs(n_exp[0]) % 2.0 == 0.0: # Even
			return n2
		else: # Odd
			return g_neg(n2)
		
	return n2

## Returns what number raised to [param n_exp] would result in [param to].
static func g_root(n_exp: PackedFloat64Array, to: PackedFloat64Array)-> PackedFloat64Array:
	return g_pow(to, g_recip(n_exp))


# http://mrob.com/pub/comp/hypercalc/hypercalc.txt
# by Robert P. Munafo
## Gamma Function. For a given [param n], this returns [code](n - 1) * (n - 2) * ... * 1[/code].
## This function is able to return an approximation if [param n] is not an integer.
static func f_gamma(n: float) -> float: 

# For very low negative arguments, the gamma function is so
# close to zero that we treat it as zero. However, for negative
# integers it's infinite, so we handle that case explicitly.
	if !is_finite(n):
		return n
	if n < 0:
		if n == floorf(n):
			return -INF
		if n < -50:
			return 0

	# Current precision allows for n^10.
	var scal1: float = n ** 10
# Since we're using Stirling's series for factorials, we have
# to subtract 1 to make it be a gamma function series.
	n -= 1
	var l: float = log(TAU)/2
	l += ((n + 0.5) * log(n))
	l -= n
	var n2: float = n ** 2
	var np: float = n
	l += 1 / (12 * np)
	np *= n2
	l += 1 / (360 * np)
	np *= n2
	l += 1 / (1260 * np)
	np *= n2
	l += 1 / (1680 * np)
	np *= n2
	l += 1 / (1188 * np)
	np *= n2
	l += 691 / (360360 * np)
	np *= n2
	l += 7 / (1092 * np)
	np *= n2
	l += 3617 / (122440 * np)
	
	return exp(l) / scal1

# http://mrob.com/pub/comp/hypercalc/hypercalc.txt
# by Robert P. Munafo
## Gamma Function. For a given [param n], this returns [code](n - 1) * (n - 2) * ... * 1[/code].
## This function is able to return an approximation if [param n] is not an integer.
static func g_gamma(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0:
		return g_recip(n)
	if n[0] == 0:
		# Patashu's source code generates the number struct, but at layer 0 sign * mag IS the whole number
		if g_sign(n) * n[1] < 24:
			return from_float(f_gamma(n[1]))
		
		var t: float = n[1] - 1
		var l: float = log(TAU)/2
		l += (t + 0.5)* log(t)
		l -= t
		var t2 = t ** 2
		var np = t
		var lm = 12 * np
		var adj = 1 / lm
		var l2 = l + adj
		if l2 == l:
			return from_float(exp(l))
		
		l = l2
		np *= t2
		lm = 360 * np
		adj = 1 / lm
		l2 = l - adj
		if l2 == l:
			return from_float(exp(l))
		
		l = l2
		np *= t2
		lm = 1260 * np
		adj = 1 / lm
		l += adj
		np *= t2
		lm = 1680 * np
		adj = 1 / lm
		l -= adj
		return from_float(exp(l))
	if n[0] == 1:
		return g_exp(
			g_mul(
				n, 
				g_sub(
					g_log(
						BIGNUM_E, 
						n
					),
					BIGNUM_ONE
				)
			)
		)
	return from_components(1, n[0] + 1, g_sign(n) * n[1])

## Returns the natural logarithm of gamma [param n].
static func g_lngamma(n: PackedFloat64Array) -> PackedFloat64Array:
	return g_log(BIGNUM_E, g_gamma(n))

## For a given [param n], this returns [code](n) * (n - 1) * ... * 1[/code].
## This function is able to return an approximation if [param n] is not an integer.
static func g_factorial(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0 or n[0] == 0:
		return g_gamma(g_add(BIGNUM_ONE, n))
	if absf(n[0]) == 1:
		return g_exp(
			g_mul(
				n, 
				g_sub(
					g_log(
						BIGNUM_E, 
						n
					),
					BIGNUM_ONE
				)
			)
		)
	return [n[0] + signf(n[0]), signf(n[0]) * n[1]]

## Returns [code]10 ** n[/code].
static func g_pow10(n: PackedFloat64Array) -> PackedFloat64Array:
	# There are four cases we need to consider:
	# 1) positive sign, positive mag (e15, ee15): +1 layer (e.g. 10^15 becomes e15, 10^e15 becomes ee15)
	# 2) negative sign, positive mag (-e15, -ee15): +1 layer but sign and mag sign are flipped (e.g. 10^-15 becomes e-15, 10^-e15 becomes ee-15)
	# 3) positive sign, negative mag (e-15, ee-15): layer 0 case would have been handled in the pow check, so just return 1
	# 4) negative sign, negative mag (-e-15, -ee-15): layer 0 case would have been handled in the pow check, so just return 1

	if (g_is_nan(n)):
		return BIGNUM_NAN.duplicate()
	var n2: PackedFloat64Array = duplicate_num_only(n)
	if n[0] == 0:
		var newmag: float = 10 ** (n[1])
		# Is any precision lost?
		if is_finite(newmag) and absf(newmag) >= 1e-15:
			return [0, newmag]
		if g_sign(n) == 0:
			return BIGNUM_ONE.duplicate()
		
		n2 = from_components_no_normalize(g_sign(n), n[0] + 1, log(n[1])/log(10))

	# Handle all 4 layer +1 layer cases individually.
	if n2[1] > 0:
		return from_components(g_sign(n2), absf(n2[0]) + 1, n2[1])
	if n2[1] < 0:
		return from_components(g_sign(n2), absf(n2[0]), -n2[1])
	
	return BIGNUM_ONE.duplicate()

# from https://github.com/scipy/scipy/blob/8dba340293fe20e62e173bdf2c10ae208286692f/scipy/special/lambertw.pxd
## Returns the solution of [code]W(x) = x * (e ** x)[/code]. [url]https://en.wikipedia.org/wiki/Lambert_W_function[/url]
static func g_lambertw(z: PackedFloat64Array, principal: bool = true, tolerance: float = 1e-10) -> PackedFloat64Array:
	var w: PackedFloat64Array
	if g_compare(from_float(-0.3678794411710499), z) > 0:
		push_error("lambertw returning nan: no real value exists below -1 / e")
		return BIGNUM_NAN.duplicate()
	if principal:
		if z[1] < 0:
			return from_float(f_lambertw(to_float(z)))
		if z[0] == 0:
			return from_float(f_lambertw(z[1]))
		if absf(z[0]) >= 3: # Numbers this large would sometimes fail to converge using Halley's method, and at this size ln(z) is close enough
		# close enough? nah, at this point z squared IS z - H4zardZ1
			return g_log(BIGNUM_E, z)

		if not g_is_finite(z):
			return z
		
		if z[1] == 0:
			return BIGNUM_ZERO.duplicate()

		if z[1] == 1: # Split out this case because the asymptotic series blows up
			return from_float(LAMBERTW_ONE_ZERO)
		w = g_log(BIGNUM_E, z)
	else:
		if g_sign(z) == 1:
			return BIGNUM_NEG_INF.duplicate()
		if z[0] == 0:
			return from_float(f_lambertw(z[1], false))
		if absf(z[0]) == 1:
			w = g_log(BIGNUM_E, g_neg(z))
		else:
			return g_neg(g_lambertw(g_recip(g_neg(z))))
			
	var ew: PackedFloat64Array
	var wewz: PackedFloat64Array
	var wn: PackedFloat64Array
	
	# See 5.9 in [LINK ROTTEN]
	for i in range(max_i_lambertw):
		ew = g_exp(g_neg(w))
		wewz = g_sub(w, g_mul(z, ew))
		# let me build my family sized nest in peece
		wn = g_sub(
			w, 
			g_div(
				g_sub(
					g_add(
						w, 
						BIGNUM_ONE
					), 
					g_div(
						g_add(w, from_float(2)), 
						g_add(g_mul(w, from_float(2)), from_float(2))
					)
				), 
				wewz
			)
		)
		if g_compare(g_mul(from_float(tolerance), wn), g_abs(g_sub(wn, w))) > 1:
			return wn
		else:
			w = wn
	
	push_error("Number {n} failed to converge after {i} iterations".format({
		"n": z,
		"i": max_i_lambertw
	}))
	return BigNumRef.BIGNUM_NAN.duplicate()
	


static func _critical_section(base: float, n_exp: float, grid: Array[PackedFloat64Array]) -> float:
	# this part is simple at least, since it's just 0.1 to 0.9
	n_exp = clampf(n_exp, 0, 1)
	n_exp *= 10
	# have to do this complicated song and dance since one of the critical_headers is exp(1), and in the future I'd like 1.5 as well
	base = clampf(base, 2, 10)
	var lower: float = 0
	var upper: float = 0
	# basically, if we're between bases, we interpolate each bases' relevant values together
	# then we interpolate based on what the fractional height is.
	# accuracy could be improved by doing a non-linear interpolation (maybe), by adding more bases and heights (definitely) but this is AFAIK the best you can get without running some pari.gp or mathematica program to calculate exact values
	# however, do note http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html can do it for arbitrary heights but not for arbitrary bases (2, e, 10 present)
	for i in range(len(CRITICAL_HEADERS)):
		if CRITICAL_HEADERS[i] == base: # exact match
			lower = grid[i][floori(n_exp)]
			upper = grid[i][ceili(n_exp)]
			break
		elif CRITICAL_HEADERS[i] < base and base < CRITICAL_HEADERS[i + 1]: # interpolate between this and the next
			var basefrac = (base - CRITICAL_HEADERS[i]) / (CRITICAL_HEADERS[i + 1] - CRITICAL_HEADERS[i])
			lower = lerp(grid[i][floori(n_exp)], grid[i + 1][floori(n_exp)], basefrac)
			upper = lerp(grid[i][ceili(n_exp)], grid[i][floori(n_exp)], basefrac)
			break
	var frac: float = fposmod(n_exp, 1)

	# improvement - you get more accuracy (especially around 0.9-1.0) by doing log, then frac, then powing the result
	# (we could pre-log the lookup table, but then fractional bases would get Weird)
	# also, use old linear for slog (values 0 or less in critical section). maybe something else is better but haven't thought about what yet
	if lower <= 0 or upper <= 0:
		return lower * (1 - frac) + upper * frac
	return base ** ((log(lower) / log(base) * (1 - frac)) + (log(upper) / log(base) * frac))

## Returns ([param base] ** [param from]) repeated [param diff] times, from the top. See [method g_tetrate].
## [codeblock]base ** (base ** (base ** ... (base ** from) ... )))[/codeblock]
## This function is able to return an approximation if [param diff] is not an integer.[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.
static func g_layer_add(from: PackedFloat64Array, diff: PackedFloat64Array, base: PackedFloat64Array, linear: bool = false) -> PackedFloat64Array:
	var slogthis := g_slog(base, from)
	var slogdest := g_add(slogthis, diff)
	if g_gte(slogdest, BIGNUM_ZERO):
		return g_tetrate(base, slogdest, BIGNUM_ONE, linear)
	elif not g_is_finite(slogdest):
		return from_float_no_normalize(NAN)
	elif g_gte(slogdest, BIGNUM_NEG_ONE):
		return g_log(base, g_tetrate(base, g_add(slogdest, BIGNUM_ONE), BIGNUM_ONE, linear))
	else: 
		return g_log(base, g_log(base, g_tetrate(base, g_add(slogdest, from_float(2)), BIGNUM_ONE, linear)))

static var max_i_layer_sub_10: int = 100000
## Returns (10 ** [param from]) repeated [param diff] times, from the top. See [method g_tetrate].
## [codeblock]10 ** (10 ** (10 ** ... (10 ** from) ... )))[/codeblock]
## This function is able to return an approximation if [param diff] is not an integer.[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.
static func g_layer_add_10(from: PackedFloat64Array, diff: PackedFloat64Array, linear: bool = false) -> PackedFloat64Array:
	var v := duplicate_num_only(from)
	var was_med_neg: bool = false
	var starting_sign: int = g_sign(diff)
	if g_lt(diff, BIGNUM_ONE):
		if v[1] < 0 and absf(v[0]) > 0:
			# bug fix: if result is very smol (mag < 0, layer > 0) turn it into 0 first
			v = [0, 0]
		elif v[1] < 0:
			# bug fix - for stuff like -3.layeradd10(1) we need to move the sign to the mag
			was_med_neg = true
		var layeradd: float = floorf(to_float(diff))
		diff = g_sub(diff, from_float(layeradd))
		v[0] += layeradd
	if g_lt(diff, BIGNUM_NEG_ONE):
		var layeradd2: float = floorf(to_float(diff))
		diff = g_sub(diff, from_float(layeradd2))
		# We can't just subtract the layer as the layer's sign is the number, we need a proxy layer to do negative-layer stuff!
		var new_layer: float = absf(v[0])
		new_layer += layeradd2
		if new_layer < 0:
			for i in range(max_i_layer_sub_10):
				new_layer += 1
				v[1] = log(v[1])/log(10)
				if not is_finite(v[1]):
					# another bugfix: if we hit -Infinity mag, then we should return negative infinity, not 0. 0.layeradd10(-1) h its this
					if signf(v[0]) < 0 or (v[0] == 0 and v[1] < 0):
						v = g_abs(v)
					# also this, for 0.layeradd10(-2)
					if new_layer < 0:
						new_layer = 0
					v = [new_layer * g_sign(v), v[1]]
					normalize_n(v)
					return v
				if new_layer >= 0:
					break
		v[0] = new_layer * signf(v[0])
	if was_med_neg:
		v[0] += 1 * starting_sign
	while v[0] * starting_sign < 0:
		v[0] += 1 * starting_sign
		v[1] = log(v[1])/log(10)
	# bugfix: before we normalize: if we started with 0, we now need to manually fix a layer ourselves!
	if v[1] == 0 and v[0] != 0:
		if v[1] == 0 and v[0] != 0:
			v[0] -= 1
			v[1] = 1
		v = g_abs(v)
	normalize_n(v)

	if not g_eq(diff, BIGNUM_ZERO):
		return g_layer_add(v, diff, from_float(10), linear)
	
	return v

## Returns [param base] raised to the power of [param base], [param n_exp]-1 times, starting from the top. 
## [url]https://en.wikipedia.org/wiki/Tetration[/url][br]
## If [param payload] is not 1, then first raises [param base] to the power of [param payload] once, that is, without repeating [param payload] in the [param n_exp] repetition.
## [codeblock] 
## base ** (base ** (base ** (base ** ...(base ** payload)...)))
## [/codeblock]
## [url]https://andydude.github.io/tetration/archives/tetration2/ident.html[/url][[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.[br]
static func g_tetrate(base: PackedFloat64Array, n_exp: PackedFloat64Array, payload: PackedFloat64Array = BIGNUM_ONE, linear: bool = false) -> PackedFloat64Array:
	
	# x ^^ 1 = x
	if g_eq(n_exp, BIGNUM_ONE):
		return g_pow(base, payload)
	# x ^^ 0 = 1
	if g_eq(n_exp, BIGNUM_ZERO):
		return duplicate_num_only(payload)
	# 1 ^^ x = 1, 
	if g_eq(BIGNUM_ONE, base):
		return BIGNUM_ONE
	# -1 ^^ x = -1
	if  g_eq(BIGNUM_NEG_ONE, base):
		return g_pow(base, payload)
	
	if g_eq(n_exp, BIGNUM_INF):
		if exp(-exp(1)) < base[1] and base[1] < exp(1/exp(1)):
			if base[1] > 1.444667861009099: # hotfix for the very edge of the number range not being handled properly
				return BIGNUM_E.duplicate()
			# formula for infinite height power tower
			var negln: PackedFloat64Array = g_neg(g_log(BIGNUM_E, base))
			return g_div(g_lambertw(negln), negln)
		elif base[1] > exp(1/exp(1)):
			return BIGNUM_INF
		else:
			# 0.06598803584531253708 > this_num >= 0: never converges
			# this_num < 0: All returns a complex number
			return BIGNUM_NAN
	
	# pow(0,0) is undefined in Godot
	if g_eq(BIGNUM_ZERO, base):
		return from_float_no_normalize(NAN)
	
	if g_lt(n_exp, BIGNUM_ZERO):
		return g_i_log(payload, base, g_neg(n_exp), linear)
	
	var frac_exp: PackedFloat64Array = g_posmod(n_exp, BIGNUM_ONE)
	n_exp = g_floor(n_exp)

	var v: PackedFloat64Array = duplicate_num_only(payload)
	if g_compare(BIGNUM_ZERO, base) == -1 and g_compare(base, from_float(exp(1) ** (1/exp(1)))) > 0:
		# flip-flops between two values, converging slowly (or if it's below 0.06598803584531253708, never).
		var old_exp := n_exp.duplicate()
		n_exp = g_num_min(from_float(max_i_tetra), n_exp)
		for i in range(n_exp):
			var old_v: PackedFloat64Array = duplicate_num_only(v)
			v = g_pow(base, v)
			# Stop early if we converge
			if g_eq(v, old_v):
				return v
		if not g_eq(frac_exp, BIGNUM_ZERO) or g_gt(old_exp, from_float(max_i_tetra)):
			# Raise a number to a power fraction times... Just do linear approx
			if g_lte(old_exp, from_float(max_i_tetra)) or g_eq(g_mod(old_exp, from_float(2)), BIGNUM_ZERO):
				return g_add(g_mul(v, frac_exp), g_mul(g_pow(base, v), g_sub(BIGNUM_ONE, frac_exp)))
			return g_add(g_mul(v, g_sub(BIGNUM_ONE, frac_exp)), g_mul(g_pow(base, v), frac_exp))
		return v
	
	#if g_compare(BIGNUM_ZERO, base) == -1:
		#pass
	
	if g_eq(frac_exp, BIGNUM_ZERO):
		if g_eq(BIGNUM_ONE, payload):
			if g_compare(from_float(10), base) == -1 or linear:
				# Linear approx.
				v = g_pow(base, frac_exp)
			else:
				v = from_float(_critical_section(to_float(base), to_float(frac_exp), CRITICAL_TETR_VALUES))
				# TODO: until the critical section grid can handle numbers below 2, scale them to the base
				# TODO: maybe once the critical section grid has very large bases, this math can be appropriate for them too? I'll think about it
				if g_compare(base, from_float(2)) == -1:
					v = g_add(
						BIGNUM_ONE, 
						g_mul(
							g_sub(base, BIGNUM_ONE), g_sub(v, BIGNUM_ONE)
						)
					)
		else:
			if g_eq(base, from_float(10)):
				v = g_layer_add_10(v, frac_exp, linear)
			else:
				v = g_layer_add(v, frac_exp, base, linear)
	for i in range(minf(absf(to_float(n_exp)), max_i_tetra)):
			v = g_pow(base, v)
			# Bail if we're NAN (or INF, somehow)
			if (not is_finite(v[0])) or (not is_finite(v[1])):
				return duplicate_num_only(v)
			# Shortcut
			if absf(v[0]) - absf(base[0]) > 3:
				@warning_ignore("narrowing_conversion")
				return from_components_no_normalize(signf(v[0]), absf(v[0]) + to_float(n_exp) - i - 1, v[1])
	return v


## Returns the result of repeating[code]log{base}(to)[/code] [param i] times.
## [codeblock]
## log{base}(log{base}(log{base}(...(log{base}(to))...)))
## [/codeblock]
static func g_i_log(to: PackedFloat64Array, base: PackedFloat64Array, i: PackedFloat64Array, linear: bool = false) -> PackedFloat64Array:
	if g_lt(i, BIGNUM_ZERO):
		return g_tetrate(base, g_neg(i), to, linear)
	var frac: PackedFloat64Array = g_posmod(i, BIGNUM_ONE)
	i = g_floor(i)
	var v = duplicate_num_only(to)
	@warning_ignore("narrowing_conversion")
	for j in range(minf(to_float(i), max_i_tetra)):
		v = g_log(base, v)
		if (not is_finite(v.mag)) or (not is_finite(v.layer)):
			return duplicate_num_only(v)
	if g_gt(frac, BIGNUM_ZERO):
		if g_eq(from_float(10), base):
			v = g_layer_add_10(v, g_neg(frac), linear)
		else:
			v = g_layer_add(v, g_neg(frac), base, linear)
	return v

static func g_slog_start(base: PackedFloat64Array, to: PackedFloat64Array, linear: bool = false) -> PackedFloat64Array:
	# Handle special cases first.
	if g_compare(base, BIGNUM_ZERO) <= 0 or g_eq(base, BIGNUM_ONE): 
		return BIGNUM_NAN
	# need to handle these small, wobbling bases specially
	if g_compare(base, BIGNUM_ONE) == 1:
		if g_eq(to, BIGNUM_ONE):
			return BIGNUM_ZERO
		if g_eq(to, BIGNUM_ZERO):
			return BIGNUM_NEG_ONE
		# 0 < this < 1: ambiguous (happens multiple times)
	# this < 0: impossible (as far as I can tell)
	# this > 1: partially complex (http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html base 0.25 for proof)
		return BIGNUM_NAN
	# slog(0) is -1
	if to[1] <= 0:
		return BIGNUM_NEG_ONE
	# what is this magic number lol - H4zardZ1
	if g_lt(base, from_float(1.44466786100976613)):
		var tower_test: PackedFloat64Array = g_neg(g_log(BIGNUM_E, base))
		tower_test = g_div(g_lambertw(tower_test), tower_test)
		if g_eq(tower_test, to):
			return BIGNUM_INF
		elif g_lt(tower_test, to):
			return BIGNUM_NAN
	var v: PackedFloat64Array = BIGNUM_ZERO
	var t: PackedFloat64Array = duplicate_num_only(to)
	if absf(t[0]) - absf(base[0]) > 3:
		var layerloss: float = absf(t[0]) - absf(base[0]) - 3
		v = g_add(v, from_float(layerloss))
		t = g_sub(t, from_float(layerloss))
	for i in range(max_i_other):
		if g_compare(t, BIGNUM_ZERO) < 0:
			t = g_pow(base, t)
			v = g_sub(t, BIGNUM_ONE)
		elif g_compare(t, BIGNUM_ONE) <= 0:
			# If base > 10, revert to linear
			if linear or g_compare(base, from_float(10)) > 0: 
				return g_add(v, t)
			else:
				return g_add(v, from_float(_critical_section(to_float(base), to_float(t), CRITICAL_SLOG_VALUES)))
		else:
			v = g_add(v, BIGNUM_ONE)
			t = g_log(base, t)
	return v

## Default tolerance for g_slog.[br]
## [code]1e-308[/code]
const SLOG_DEFAULT_TOL: PackedFloat64Array = [1, -308]
## Returns how many times you have to raise [param base] to itself in order to get [param to].
## [url]https://en.wikipedia.org/wiki/Super-logarithm[/url][br]
## Use [param max_i_other] to change the amount of iterations.[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.
static func g_slog(base: PackedFloat64Array, to: PackedFloat64Array, linear: bool = false, epsilon: PackedFloat64Array = SLOG_DEFAULT_TOL) -> PackedFloat64Array:
	var step_size: PackedFloat64Array = [0, 0.001]
	var has_changed_directions_once: bool = false
	var risen: bool = false
	var v: PackedFloat64Array = g_slog_start(base, to, linear)
	for i in range(max_i_other):
		var t: PackedFloat64Array = g_tetrate(base, v, BIGNUM_ONE, linear)
		var rising: bool = g_compare(to, t) < 0
		if i > 1:
			if rising != risen:
				has_changed_directions_once = true
		risen = rising
		if has_changed_directions_once:
			step_size = g_mul(step_size, from_float(1/2.0))
		else:
			step_size = g_mul(step_size, from_float(2))
		var flip: int = -1 if rising else 1
		step_size = g_mul(g_abs(step_size), from_float(flip))
		var new_v: PackedFloat64Array = g_add(v, step_size)
		if new_v == v or g_lt(g_abs(step_size), epsilon):
			break
		v = new_v
	return v

## Returns what number raised to itself [code]degree - 1[/code] times will be equal to [param to].[br]
## This function returns the number PackedFloat64Array.[br]
## [b]Note:[/b]
## Only works with the linear approximation of tetration, as starting with analytic and then switching to linear would result in inconsistent behavior for super-roots.
## This only matters for non-integer degrees.[br]
## [b]Note:[/b]
## This function may be slow for 0 < [param to] < 1
static func g_sroot(to: PackedFloat64Array, degree: PackedFloat64Array) -> PackedFloat64Array:
	# TODO: Optimize this like how slog is optimized (if it isn't already)
	# 1st-degree super root just returns its input
	if g_eq(degree, BIGNUM_ONE):
		return duplicate_num_only_no_normalize(to)
	if g_eq(BIGNUM_INF, to):
		return BIGNUM_INF
	if not g_is_finite(to):
		return BIGNUM_NAN.duplicate()
	# Using linear approximation, x^^n = x^n if 0 < n < 1
	if g_lt(BIGNUM_ZERO, degree) and g_lt(degree, BIGNUM_ONE):
		return g_root(to, degree)
	# Using linear approximation, there actually is a single solution for super roots with -2 < degree <= -1
	if g_lt(from_float(-2), degree) and g_lt(degree, BIGNUM_NEG_ONE):
		return g_root(g_add(degree, from_float(2)), to)
	# Super roots with -1 <= degree < 0 have either no solution or infinitely many solutions, and tetration with height <= -2 returns NaN, so super roots of degree <= -2 don't work
	if g_lte(degree, BIGNUM_ZERO):
		return BIGNUM_NAN.duplicate()
	if g_eq(BIGNUM_ONE, to):
		return BIGNUM_ONE.duplicate()
	# Infinite degree super-root is x^(1/x) between 1/e <= x <= e, undefined otherwise
	if g_eq(degree, BIGNUM_INF):
		var t := to_float(to)
		if exp(-1) < t and t < exp(1):
			return g_root(to, to)
		else:
			return BIGNUM_NAN.duplicate()
	# base < 0 (It'll probably be NaN anyway)
	if g_compare(to, BIGNUM_ZERO) <= 0:
		return BIGNUM_NAN.duplicate()
	# Treat all numbers of layer <= -2 as zero, because they effectively are
	if g_compare(to, [2.0, -16.0]) <= 0:
		if fmod(to_float(degree), 2) == 1:
			return duplicate_num_only(to)
		else:
			return BIGNUM_NAN.duplicate()
	# I'll see if the guesswork of ssqrt() on the lambertw function or the guesswork of sroot(2, n) is faster later; for now i'll comment this out- H4zardZ1
	# if degree == 2:
	# 	return g_ssqrt(to)
	if g_compare(to, BIGNUM_ONE) == 1:
		# Uses guess-and-check to find the super-root.
		# If this > 10^^(degree), then the answer is under iteratedlog(10, degree - 1): for example, ssqrt(x) < log(x, 10) as long as x > 10^10, and linear_sroot(x, 3) < log(log(x, 10), 10) as long as x > 10^10^10
		# On the other hand, if this < 10^^(degree), then clearly the answer is less than 10
		# Since the answer could be a higher-layered number itself, the guess-and-check is scaled to the layer of the upper bound, so the guess is set to the average of some higher-layer exponents of the bounds rather than the bounds itself (as taking plain averages on tetrational-scale numbers would go nowhere)
		var upper_bound_local := from_float(10)
		if g_compare(to, g_tetrate(from_float(10), degree, BIGNUM_ONE, true)):
			upper_bound_local = g_i_log(to, from_float(10), degree, true)
		if g_lte(degree, BIGNUM_ONE):
			upper_bound_local = g_root(to, degree)
		var lower_local := BIGNUM_ZERO.duplicate()
		var layer: float = upper_bound_local[0]
		var upper_local := g_i_log(upper_bound_local, from_float(10), from_float(layer), true)
		var previous_local = upper_local
		var guess_local := g_div(upper_local, from_float(2))
		while true:
			guess_local = g_div(g_add(upper_local, lower_local), from_float(2))
			var direction := g_compare(g_tetrate(g_tetrate(from_float(10), from_float(layer), guess_local, true), degree, BIGNUM_ONE, true), to)
			if direction == 1:
				upper_local = guess_local
			else:
				lower_local = guess_local
			if g_eq(previous_local, guess_local):
				break
			else:
				previous_local = guess_local
		return g_tetrate(from_float(10), from_float(layer), guess_local, true)
	# 0 < to < 1
	# A tetration of decimal degree can potentially have three different portions, as shown at https://www.desmos.com/calculator/ayvqks6mxa, which is a graph of x^^2.05:
	# The portion where the function is increasing, extending from a minimum (which may be at x = 0 or at some x between 0 and 1) up to infinity (I'll call this the "increasing" range)
	# The portion where the function is decreasing (I'll call this the "decreasing" range)
	# A small, steep increasing portion very close to x = 0 (I'll call this the "zero" range)
	# If ceiling(degree) is even, then the tetration will either be strictly increasing, or it will have the increasing and decreasing ranges, but not the zero range (because if ceiling(degree) is even, 0^^degree == 1).
	# If ceiling(degree) is odd, then the tetration will either be strictly increasing, or it will have all three ranges (because if ceiling(degree) is odd, 0^^degree == 0).
	# The existence of these ranges means that a super-root could potentially have two or three valid answers.
	# Out of these, we'd prefer the increasing range value if it exists, otherwise we'll take the zero range value (it can't have a decreasing range value if it doesn't have an increasing range value) if the zero range exists.
	# It's possible to identify which range that "this" is in:
	# If the tetration is decreasing at that point, the point is in the decreasing range.
	# If the tetration is increasing at that point and ceiling(degree) is even, the point is in the increasing range since there is no zero range.
	# If the tetration is increasing at that point and ceiling(degree) is odd, look at the second derivative at that point. If the second derivative is positive, the point is in the increasing range. If the second derivative is negative, the point is the zero range.
	# We need to find the local minimum (separates decreasing and increasing ranges) and the local maximum (separates zero and decreasing ranges).
	# (stage) is which stage of the loop we're in: stage 1 is finding the minimum, stage 2 means we're between the stages, and stage 3 is finding the maximum.
	# The boundary between the decreasing range and the zero range can be very small, so we want to use layer -1 numbers. Therefore, all numbers involved are log10(recip()) of their actual values.
	var stage: int = 1
	var minimum : PackedFloat64Array = from_components(1, 10, 1)
	var maximum : PackedFloat64Array = from_components(1, 10, 1)
	var lower : PackedFloat64Array = from_components(1, 10, 1) # 1eeeeeeeeee-10
	var upper : PackedFloat64Array = from_components(1, 1, -16) # 1e-16
	var prev_span : PackedFloat64Array = BIGNUM_ZERO.duplicate()
	var difference : PackedFloat64Array = from_components(1, 10, 1)
	var upper_bound : PackedFloat64Array = g_recip(g_pow10(upper))
	var distance : PackedFloat64Array = BIGNUM_ZERO.duplicate()
	var guess : PackedFloat64Array = BIGNUM_ZERO.duplicate()
	var prev_point : PackedFloat64Array= upper_bound.duplicate()
	var next_point : PackedFloat64Array = upper_bound.duplicate()
	var even_degree : bool = g_eq(g_mod(degree, [0, 2]), BIGNUM_ZERO)
	var dir: int = 0
	var last_valid : PackedFloat64Array = from_components(1, 10, 1)
	var inf_loop_detector : bool = false
	var previous_upper : PackedFloat64Array = BIGNUM_ZERO.duplicate()
	var decreasing_found : bool = false
	# JS allows you to dupe stuff with just the assignment operator. Godot... doesn't do that -H4zardZ1
	while stage < 4:
		if stage == 2:
			# The minimum has been found. If ceiling(degree) is even, there's no zero range and thus no local maximum, so end the loop here. Otherwise, begin finding the maximum.
			if even_degree:
				break
			else:
				lower = from_components(1, 10, 1)
				upper = duplicate_num_only(minimum)
				stage = 3
				difference = from_components(1, 10, 1)
				last_valid = from_components(1, 10, 1)
		inf_loop_detector = false
		while not g_eq(upper, lower):
			previous_upper = upper
			if g_eq(BIGNUM_ONE, g_tetrate(g_recip(g_pow10(upper)), degree, BIGNUM_ONE, true)) and g_gte(from_float(0.4), g_recip(g_pow10(upper))):
				upper_bound = g_recip(g_pow10(upper))
				prev_point = g_recip(g_pow10(upper))
				next_point = g_recip(g_pow10(upper))
				distance = BIGNUM_ZERO.duplicate()
				dir = -1 # This would cause problems with degree < 1 in the linear approximation... but those are already covered as a special case
				if stage == 3:
					last_valid = duplicate_num_only(upper)
			elif g_eq(g_recip(g_pow10(upper)), g_tetrate(g_recip(g_pow10(upper)), degree, BIGNUM_ONE, true)) and (not even_degree) and g_gte(from_float(0.4), g_recip(g_pow10(upper))):
				upper_bound = g_recip(g_pow10(upper))
				prev_point = g_recip(g_pow10(upper))
				next_point = g_recip(g_pow10(upper))
				distance = BIGNUM_ZERO.duplicate()
				dir = 0
			elif g_eq(g_tetrate(g_recip(g_pow10(upper)), degree, BIGNUM_ONE, true), g_tetrate(g_mul(from_float(2), g_recip(g_pow10(upper))), degree, BIGNUM_ONE, true)):
				# If the upper bound is closer to zero than the next point with a discernable tetration, so surely it's in whichever range is closest to zero?
				# //This won't happen in a strictly increasing tetration, as there x^^degree ~= x as x approaches zero
				upper_bound = g_recip(g_pow10(upper))
				prev_point = BIGNUM_ZERO.duplicate()
				next_point = g_mul(upper_bound, from_float(2))
				distance = duplicate_num_only(upper_bound)
				if even_degree:
					dir = 1
				else:
					dir = 0
			else:
				prev_span = g_mul(upper, from_float(1.2e-16))
				upper_bound = g_recip(g_pow10(upper))
				prev_point = g_recip(g_pow10(g_add(upper, prev_span)))
				distance = g_sub(upper_bound, prev_point)
				next_point = g_add(upper_bound, distance)
				while g_eq(g_tetrate(next_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true)) or \
				g_eq(g_tetrate(prev_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true)) or \
				g_gte(prev_point, upper_bound) or g_lte(next_point, upper_bound):
					prev_span = g_mul(prev_span, from_float(2))
					prev_point = g_recip(g_pow10(g_add(prev_span, upper)))
					distance = g_sub(upper_bound, prev_point)
					next_point = g_add(upper_bound, distance)
					if (stage == 1 and g_gt(g_tetrate(next_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true)) and \
					g_gt(g_tetrate(prev_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true))) or \
					g_gte(prev_point, upper_bound) or g_lte(next_point, upper_bound):
						last_valid = duplicate_num_only(upper)
					if g_lt(g_tetrate(next_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true)):
						# Derivative is negative, so we're in decreasing range
						dir = -1
					elif even_degree:
						# No zero range, so we're in increasing range
						dir = 1
					elif stage == 3 and g_gt_approx(upper, minimum, 1e-8):
						# We're already below the minimum, so we can't be in range 1
						dir = 0
					else: # Number imprecision has left the second derivative somewhat untrustworthy, so we need to expand the bounds to ensure it's correct
						while g_eq_approx(g_tetrate(prev_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true), 1e-8) or \
						g_eq_approx(g_tetrate(next_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true), 1e-8) or \
						g_gte(prev_point, upper_bound) or g_lte(next_point, upper_bound):
							prev_span = g_mul(prev_span, from_float(2))
							prev_point = g_recip(g_pow10(g_add(upper, prev_span)))
							distance = g_sub(upper_bound, prev_point)
							next_point = g_add(upper_bound, distance)
						if g_lt(g_sub(g_tetrate(next_point, degree, BIGNUM_ONE, true), g_tetrate(upper_bound, degree, BIGNUM_ONE, true)), g_sub(g_tetrate(upper_bound, degree, BIGNUM_ONE, true), g_tetrate(prev_point, degree, BIGNUM_ONE, true))):
							# Second derivative is negative, so we're in zero range
							dir = 0
						else: # By process of elimination, we're in increasing range
							dir = 1
			decreasing_found = (dir == -1)
			if (stage == 1 and dir == 3) or (stage == 3 and dir != 0):
				# The upper bound is too high
				if g_eq(lower, from_components(1, 10, 1)):
					upper = g_mul(upper, from_float(2))
				else:
					upper = g_div(g_add(upper, lower),from_float(2))
					if inf_loop_detector and ((dir == 1 and stage == 1) or (dir == -1 and stage == 3)):
						# Avoid infinite loops from floating point imprecision
						break 
			else:
				if g_eq(lower, from_components(1, 10, 1)):
					# We've now found an actual lower bound
					lower = duplicate_num_only(upper)
					upper = g_div(upper, from_float(2))
				else:
					# The upper bound is too low, meaning last time we decreased the upper bound, we should have gone to the other half of the new range instead
					lower = g_sub(lower, difference)
					upper = g_sub(upper, difference)
					if inf_loop_detector and ((dir == 1 and stage == 1) or (dir == -1 and stage == 3)):
						# Avoid infinite loops from floating point imprecision
						break 
		# can't use the set bool value hack, have to do it this way because it might be false next pass
		if g_gt(g_abs(g_div(g_sub(lower, upper),from_float(2))), g_mul(difference, from_float(1.5))):
			inf_loop_detector = true
		difference = g_abs(g_div(g_sub(lower, upper),from_float(2)))
		if g_gt(upper, from_float(1e18)):
			break
		if g_eq(upper, previous_upper): # Since this isnt an invariant somehow this sanity check has to be done
			break
		if g_gt(upper, from_float(1e18)):
			break
		if not decreasing_found: # If there's no decreasing range, then even if an error caused lastValid to gain a value, the minimum can't exist
			break
		if last_valid == from_components(1, 10, 1):
			# Whatever we're searching for, it doesn't exist. If there's no minimum, then there's no maximum either, so either way we can end the loop here.
			break
		if stage == 1:
			minimum = duplicate_num_only(last_valid)
		elif stage == 3:
			maximum = duplicate_num_only(last_valid)
		stage += 1
	#	Now we have the minimum and maximum, so it's time to calculate the actual super-root.
	# First, check if the root is in the increasing range.
	lower = duplicate_num_only(minimum)
	upper = from_components(1, 1, -18)
	var previous : PackedFloat64Array = duplicate_num_only(upper)
	guess = BIGNUM_ZERO.duplicate()
	var loop_going = true
	while loop_going:
		if g_eq(lower, from_components(1, 10, 1)):
			guess = g_mul(upper, from_float(2))
		else:
			guess = g_div(g_add(upper, lower), from_float(2))
		if g_gt(g_tetrate(g_recip(g_pow(from_float(10), guess)), degree, BIGNUM_ONE, true), to):
			upper = duplicate_num_only(guess)
		else:
			lower = duplicate_num_only(guess)
		if g_eq(guess, previous):
			loop_going = false
		else:
			previous = duplicate_num_only(guess)
		if g_gt(upper, from_float(1e18)):
			return BIGNUM_NAN.duplicate()
	# using guess.neq(minimum) led to imprecision errors, so here's a fixed version of that
	if not g_eq_approx(minimum, from_float(1e-15)):
		return g_recip(g_pow10(guess))
	# If guess == minimum, we haven't actually found the super-root, the algorithm just kept going down trying to find a super-root that's not in the increasing range.
	# Check if the root is in the zero range.
	elif g_eq(maximum, from_components(1, 10, 1)):
		# There is no zero range, so the super root doesn't exist
		return BIGNUM_NAN.duplicate()
	lower = from_components(1, 10, 1)
	upper = duplicate_num_only(maximum)
	previous = duplicate_num_only(upper)
	guess = BIGNUM_ZERO.duplicate()
	loop_going = true
	while loop_going:
		if g_eq(lower, from_components(1, 10, 1)):
			guess = g_mul(upper, from_float(2))
		else:
			guess = g_div(g_add(lower, upper), from_float(2))
		if g_gt(g_tetrate(g_recip(g_pow(from_float(10), guess)), degree, BIGNUM_ONE, true), to):
			upper = duplicate_num_only(guess)
		else:
			lower = duplicate_num_only(guess)
		if g_eq(guess, previous):
			loop_going = false
		else:
			previous = duplicate_num_only(guess)
		if g_gt(upper, from_float(1e18)):
			return BIGNUM_NAN.duplicate()

	return g_recip(g_pow10(guess))

# https://math.stackexchange.com/questions/4152393/square-rooting-in-tetration
## Returns what number raised to itself will be equal to [param to].[br]
## See [method g_sroot]. This method is separate due to easier implementation.
static func g_ssqrt(to: PackedFloat64Array)-> PackedFloat64Array:
	if g_sign(to) == 1 and absf(to[0]) >= 3:
		return from_components_no_normalize(g_sign(to), absf(to[0]) - 1, to[1])
	var lnx := g_log(BIGNUM_E, to)
	return g_div(lnx, g_lambertw(lnx))

## Returns [param base] tetrated to [param base], [param n_exp] times, starting from the top. [url]https://en.wikipedia.org/wiki/Pentation [/url][br]
## [codeblock]
## tetrate(base, tetrate(base, tetrate(base, tetrate...(base, base)...)))
## [/codeblock]
## This is an absurdly strong operator. [code]pentate(2, 4.28)[/code] and [/code]pentate(10, 2.37)[/code] are already too huge for this library!
## [br]
## [b]Note:[/b]
## For non-whole pentation heights, the linear approximation of pentation is always used, as there is no defined analytic approximation of pentation.
static func g_pentate(base: PackedFloat64Array, n_exp: float, payload: PackedFloat64Array = BIGNUM_ONE, linear: bool = false) -> PackedFloat64Array:
	var v : PackedFloat64Array = duplicate_num_only(payload)
	var frac_exp : float = fmod(n_exp, 1)
	# I have no idea if this is a meaningful approximation for pentation to continuous heights, but it is monotonic and continuous.
	if frac_exp != 0:
		if g_eq(BIGNUM_ONE, payload):
			n_exp += 1
			v = from_float(n_exp)
		else:
			if g_eq(from_float(10), base):
				v = g_layer_add_10(v, from_float(frac_exp), linear)
			else:
				v = g_layer_add(v, from_float(frac_exp), base, linear)
	for i in range(min(max_i_tetra, floori(n_exp))):
		v = g_tetrate(base, v, BIGNUM_ONE, linear)
		if (not is_finite(v[0])) or (not is_finite(v[0])):
			return duplicate_num_only(v)
	return v
# Trigonometry functions

# @GlobalScope.sin
## Returns the sine of angle [param n] in radians.
static func g_sin(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0:
		return duplicate_num_only_no_normalize(n)
	if n[0] == 0:
		return from_float(sin(n[1]))
	return BIGNUM_ZERO.duplicate()

# @GlobalScope.cos
## Returns the cosine of angle [param n] in radians.
static func g_cos(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0:
		return BIGNUM_ONE.duplicate()
	if n[0] == 0:
		return from_float(cos(n[1]))
	return BIGNUM_ZERO.duplicate()

# @GlobalScope.tan
## Returns the tangent of angle [param n] in radians.
static func g_tan(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0:
		return duplicate_num_only_no_normalize(n)
	if n[0] == 0:
		return from_float(tan(n[1]))
	return BIGNUM_ZERO.duplicate()

# @GlobalScope.asin
## Returns the arc sine of [param n] in radians. See [method @GlobalScope.asin][br]
## [b]Note[/b]: This function returns 0 on large numbers (instead of NAN).
static func g_asin(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0:
		return duplicate_num_only_no_normalize(n)
	if n[0] == 0:
		return from_float(asin(n[1]))
	return BIGNUM_ZERO.duplicate()

# @GlobalScope.acos
## Returns the arc cosine of [param n] in radians. See [method @GlobalScope.acos][br]
## [b]Note[/b]: This function returns [constant @GDScript.TAU]/4 on large numbers (instead of NAN).
static func g_acos(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0:
		return from_float(acos(to_float(n)))
	if n[0] == 0:
		return from_float(acos(n[1]))
	return from_float(TAU/4)

# @GlobalScope.atan
## Returns the arc tangent of [param n] in radians. See [method @GlobalScope.atan]
static func g_atan(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[1] < 0:
		return duplicate_num_only_no_normalize(n)
	if n[0] == 0:
		return from_float(atan(n[1]))
	# 9e15 < 1.8e308
	return from_float(atan(minf(absf(to_float(n)), 1.7e308) * signf(n[0])))

# @GlobalScope.atan2
## Returns the arc tangent of [code]y/x[/code] in radians, based on the quadrant of the given (x, y). See [method @GlobalScope.atan2]
static func g_atan2(y: PackedFloat64Array, x: PackedFloat64Array) -> PackedFloat64Array: # Vector2.angle
	var xfloat := to_float(x)
	var yfloat := to_float(y)
	if is_finite(xfloat) and is_finite(yfloat) and\
	(absf(xfloat) >= LOWEST_POSITIVE_NORMAL_FLOAT) and\
	(absf(yfloat) >= LOWEST_POSITIVE_NORMAL_FLOAT):
		return from_float(atan2(yfloat, xfloat))
	if g_gt(x, BIGNUM_ZERO):
		return g_atan(g_div(y, x))
	elif g_lt(x, BIGNUM_ZERO):
		var ys: int = g_sign(y) if g_sign(y) != 0 else 1
		return g_add(g_atan(g_div(y, x)), from_float(PI * ys))
	elif not g_eq(y, BIGNUM_ZERO):
		return from_float(PI * g_sign(y) / 2)
	else: # why the hell are you inserting double zeros in this
		return BIGNUM_NAN.duplicate()

# @GlobalScope.sinh # (e^x - e^-x)/2
## Returns the hyperbolic sine of [param n]. See [method @GlobalScope.sinh]
static func g_sinh(n: PackedFloat64Array) -> PackedFloat64Array:
	# Special Case: since Godot has sinh, use it on layer 0 numbers
	if n[0] == 0:
		return from_float(sinh(n[1]))
	return g_div(g_sub(g_exp(n), g_exp(g_neg(n))), from_float(2))

# @GlobalScope.cosh # (e^x + e^-x)/2
## Returns the hyperbolic cosine of [param n]. See [method @GlobalScope.sinh]
static func g_cosh(n: PackedFloat64Array) -> PackedFloat64Array:
	# Special Case: since Godot has cosh, use it on layer 0 numbers
	if n[0] == 0:
		return from_float(cosh(n[1]))
	return g_div(g_add(g_exp(n), g_exp(g_neg(n))), from_float(2))

# @GlobalScope.tanh # Sinh(x)/Cosh(x)
## Returns the hyperbolic tangent of [param n]. See [method @GlobalScope.tanh]
static func g_tanh(n: PackedFloat64Array) -> PackedFloat64Array:
	# Special Case: since Godot has tanh, use it on layer 0 numbers
	if n[0] == 0:
		return from_float(tanh(n[1]))
	return g_div(g_sinh(n), g_cosh(n))
	
# @GlobalScope.asinh
## Returns the hyperbolic arc sine of [param n] in radians. Use this to get the angle from an angle's sine in hyperbolic space.
## [br]See [method @GlobalScope.asinh]
static func g_asinh(n: PackedFloat64Array) -> PackedFloat64Array:
	# Special Case: Since Godot has asinh, use it on layer 0 numbers
	if n[0] == 0:
		return from_float(asinh(n[1]))
	return g_log(BIGNUM_E, g_add(n, g_root(from_float(2), g_add(BIGNUM_ONE, g_pow(n, from_float(2))))))

# @GlobalScope.acosh
## Returns the hyperbolic arc cosine of [param n] in radians. Use this to get the angle from an angle's cosine in hyperbolic space if [param n] is larger than 1.
## [br]This returns 0 if [param n] is less than 1. See [method @GlobalScope.acosh]
static func g_acosh(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[0] == 0:
		return from_float(acosh(n[1]))
	# Godot wants to return 0 instead of NAN on x < 1. Let's do that
	if n[1] < 1:
		return BIGNUM_ZERO.duplicate()
	return g_log(BIGNUM_E, g_add(n, g_root(from_float(2), g_add(BIGNUM_NEG_ONE, g_pow(n, from_float(2))))))

# @ GlobalScope.atanh
## Returns the hyperbolic arc tangent of [param n] in radians. Use this to get the angle from an angle's cosine in hyperbolic space.
## [br]This returns a signed infinity if [param n] is more than or equal to 1 or less than or equal to -1.
static func g_atanh(n: PackedFloat64Array) -> PackedFloat64Array:
	if n[0] == 0:
		return from_float(atanh(n[1]))
	if g_compare_abs(n, BIGNUM_ONE) > 1: 
		# Godot wants to return signed INF instead of NAN on x > 1 or x < -1. Let's do that
		return from_components_no_normalize(g_sign(n), INF, INF)
	return g_div(g_log(BIGNUM_E, g_div(g_add(BIGNUM_ONE, n), g_sub(BIGNUM_ONE, n))), from_float(2))


	

# Godot helper math functions BEGIN
## Returns the linear interpolation (or extrapolation) between [param from] and [param to]. See [method @GlobalScope.lerp]
static func g_lerp(from: PackedFloat64Array, to: PackedFloat64Array, weight: PackedFloat64Array) -> PackedFloat64Array:
	return g_add(from, g_mul(weight, g_sub(to, from)))

## Returns the interpolation (or extrapolation) factor of [param current]
## between the range specified by [param from] and [param to].[br]
## See [method @GlobalScope.inverse_lerp]
static func g_inverse_lerp(from: PackedFloat64Array, to: PackedFloat64Array, current: PackedFloat64Array) -> PackedFloat64Array:
	return g_div(g_sub(current, from), g_sub(to, from))

## Wraps [param value] between [param min] and [param max]. 
## See [method @GlobalScope.wrap].
static func g_wrap(value: PackedFloat64Array, from: PackedFloat64Array, to: PackedFloat64Array) -> PackedFloat64Array:
	return g_add(from, g_posmod(value, g_sub(from, to)))

# Godot helper math functions END


## Returns the linear interpolation between [param from] and [param to], with [param weight] values above 1 or below 0 wrapped around.
static func g_wraplerp(from: PackedFloat64Array, to: PackedFloat64Array, weight: PackedFloat64Array) -> PackedFloat64Array:
	return g_add(from, g_mul(g_posmod(weight, BIGNUM_ONE), g_sub(to, from)))


## Returns the length of the sum of a geometric series starting at [param price_start] additionally offset by [param current_owned]
## where its value is the highest possible that is lower than or equal to [param res].[br]
## This is an inverse of [method sum_geometric_series], where the returned result is always an integer.
static func afford_geometric_series(
	res: PackedFloat64Array, 
	price_start: PackedFloat64Array, 
	ratio: PackedFloat64Array, 
	current_owned: PackedFloat64Array = BIGNUM_ZERO
) -> PackedFloat64Array:
	var actual_start := g_mul(g_pow(ratio, current_owned), price_start)
	return g_floor(
		g_div(
			g_log10(
				g_add(
					g_mul(
						g_div(res, actual_start),
						g_sub(ratio, BIGNUM_ONE)
					), 
					BIGNUM_ONE
				)
			), 
			g_log10(ratio)
		)
	)

## Returns the sum of a geometric series starting at [param price_start], additionally offset by [param current_owned], up to the [param items]-th item.
static func sum_geometric_series(
	items: PackedFloat64Array,
	price_start: PackedFloat64Array,
	ratio: PackedFloat64Array,
	current_owned: PackedFloat64Array = BIGNUM_ZERO
) -> PackedFloat64Array :
	return g_div(
		g_mul(
			g_mul(price_start, g_pow(ratio, current_owned)),
			g_sub(BIGNUM_ONE, g_pow(ratio, items))
		), 
		g_sub(BIGNUM_ONE, ratio)
	)

## Returns the length of the sum of an arithmetic series starting at [param price_start], additionally offset by [param current_owned]
## where its value is the highest possible that is lower than or equal to [param res].[br]
## This is an inverse of [method sum_arithmetic_series], where the returned result is always an integer.
static func afford_arithmetic_series(
	res: PackedFloat64Array,
	price_start: PackedFloat64Array,
	increase: PackedFloat64Array,
	current_owned: PackedFloat64Array = BIGNUM_ZERO
) -> PackedFloat64Array :
	var actual_start := g_add(price_start, g_mul(increase, current_owned))
	var b := g_sub(actual_start, g_div(increase, from_float(2)))
	var b2 := g_pow(b, from_float(2))
	return g_floor(
		g_div(
			g_add(
				g_neg(b), 
				g_root(
					from_float(2), 
					g_add(
						b2, 
						g_mul(g_mul(increase, res), from_float(2))
					)
				)
			), 
			increase
		)
	)

## Returns the sum of an arithmetic series starting at [param price_start], additionally offset by [param current_owned], up to the [param items]-th item.
static func sum_arithmetic_series(
	items: PackedFloat64Array,
	price_start: PackedFloat64Array,
	increase: PackedFloat64Array,
	current_owned: PackedFloat64Array = BIGNUM_ZERO
) -> PackedFloat64Array :
	var actual_start := g_add(price_start, g_mul(increase, current_owned))
	return g_mul(
		g_div(items, from_float(2)),
		g_add(
			g_mul(actual_start, from_float(2)), 
			g_mul(g_sub(items, BIGNUM_ONE), increase)
		)
	)

## Logarithmic integral function.[br]
## While this is useful for an approximation of amount of primes until [param n], the antiderivative of [code]1/log(n)[/code] itself may be useful for another purpose.
static func f_li(n: float, tol: float = 1e-7) -> float:
	if n < 0 or is_nan(n):
		return NAN
	if n == 0:
		return 0
	if n == 1:
		return -INF
	# ramanujan's faster convergence li approximation
	# multiple summations x_x
	var starting_value: float = 0.57721566490153286 + log(absf(log(n)))
	var starting_multiplier: float = sqrt(n)
	var sum: float = 0.0
	var this_block: float
	for i in range(max_i_other):
		this_block = (((-1.0) ** (i)) * (log(n) ** (i + 1)))/\
					 			 (f_gamma(i + 1) * 2 ** (i))
		var sum_mul: float = 1
		@warning_ignore("integer_division") # flooring is intended here
		for j in range((i - 2) / 2):
			sum_mul += 1.0 / (j * 2 + 1)
		this_block *= sum_mul
		sum += this_block
		if absf(this_block) < absf(sum * tol):
			return starting_value + starting_multiplier * sum
	return starting_value + starting_multiplier * sum

static func g_ln(n: PackedFloat64Array) -> PackedFloat64Array:
	if g_sign(n) < 0:
		return BIGNUM_NAN.duplicate()
	elif g_sign(n) == 0:
		return BIGNUM_NEG_INF.duplicate()
	elif n[0] == 0:
		return duplicate_num_only([0, log(n[1])])
	elif n[0] == 1:
		@warning_ignore("narrowing_conversion")
		return from_components(signf(n[1]), 0, absf(log(n[1])) * log(10))
	elif n[0] == 2:
		@warning_ignore("narrowing_conversion")
		return from_components(signf(n[1]), 1, absf(log(n[1])) + 0.36221568869946325) # log10(log10(e))
	elif n[0] == 3:
		@warning_ignore("narrowing_conversion")
		return from_components(signf(n[1]), 2, absf(log(n[1] + 0.36221568869946325)))
	else:
		@warning_ignore("narrowing_conversion")
		return from_components(signf(n[1]), n[0] - 1, absf(log(n[1])))

## Logarithmic integral function.[br]
## While this is useful for an approximation of amount of primes [param n], the antiderivative of [code]1/log(n)[/code] itself may be useful for another purpose.
static func g_li(n: PackedFloat64Array, tol: float = 1e-7) -> PackedFloat64Array:
	if g_sign(n) < 0 or g_is_nan(n):
		return BIGNUM_NAN.duplicate()
	if absf(n[0]) > 2:
		# as li(x) approaches infinity, it's going to be similar to x / ln(x) (after all, it's 1/ln(x) antiderivated)
		# division is 'too weak' of a function here, and especially at extremely low values (instead of very high) the only relevant part is the sign!
		return [n[0] * signf(n[1]), n[1]]
	if n[0] == 0:
		return from_float(f_li(n[1], tol))

	var starting_value: PackedFloat64Array = from_float(0.57721566490153286 + to_float(g_ln(g_abs((g_ln(n)))))) # mag can be negative
	var starting_multiplier: PackedFloat64Array = g_root(from_float(2), n)
	var sum: PackedFloat64Array = BIGNUM_ZERO.duplicate()
	var this_block: PackedFloat64Array
	for i in range(max_i_other):
		this_block = g_div(
			g_mul(from_float(-1.0 ** (i)), g_pow(g_ln(n), from_float(i + 1))), 
			from_float(f_gamma(i + 1) * 2 ** (i))
		)
		var sum_mul: float = 1
		@warning_ignore("integer_division")
		for j in range((i) / 2):
			sum_mul += 1.0 / (j * 2 + 1)
		this_block = g_mul(this_block, from_float(sum_mul))
		sum = g_add(sum, this_block)
		if g_eq_approx(sum, this_block, tol):
			return g_add(starting_value, g_mul(sum, starting_multiplier))
	return g_add(starting_value, g_mul(sum, starting_multiplier))

	
	




# variables
## The PackedFloat64Array representation of the number this BigNumRef holds.
var d: PackedFloat64Array:
	set(value):
		n_layer = value[0]
		_single_pass_n_changed = false
		n_mag = value[1]
		_single_pass_n_changed = true
	get:
		return [n_layer, n_mag]
## Layer of the number held.
## Stores the negative value if its absolute value is 1 or higher.
var n_layer: float:
	set(value):
		n_layer = value
		if _single_pass_n_changed:
			n_changed.emit()
## Magnitude of the number. Stores the negative value if the layer of the number is zero.
## Otherwise, a negative magnitude represents a number that is close to zero. (1e-x)
var n_mag: float:
	set(value):
		n_mag = value
		if _single_pass_n_changed:
			n_changed.emit()
var _dirty_l_normalize: bool
var _single_pass_n_changed: bool = true
var n_is_nan: bool:
	get:
		return BigNumRef.g_is_nan(d)

func _init(arg = 0):
	d = BigNumRef.from_v(arg)

## Changes the number inside the reference to [param text], and then returns the reference.
func l_from_str(text: String) -> BigNumRef:
	d = BigNumRef.from_str(text)
	return self

## Changes the number inside the reference to [param n], and then returns the reference.
func n_replace(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.duplicate_num_only(n)
	return self

## Changes the number inside the reference to the number that [param obj] holds, and then returns the reference.
func replace(obj: BigNumRef) -> BigNumRef:
	d = obj.d.duplicate()
	return self

## Changes the number inside the reference to [param arg], and then returns the reference.
func v_replace(arg) -> BigNumRef:
	d = from_v(arg)
	return self

## Changes the number inside the reference to [param arg] if it is not null, and then returns the reference.
func v_replace_safe(arg) -> BigNumRef:
	var new: PackedFloat64Array = from_v(arg)
	if BigNumRef.g_is_nan(new):
		return self
	d = from_v(arg)
	return self

## Adds the number the reference holds with [param n], and then returns the reference.
func n_add(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.g_add(n, d)
	return self

## Adds the number the reference holds with the number that [param obj] holds,
## then returns the reference this function was called on.
func add(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_add(obj.d, d)
	return self

## Subtracts the number the reference holds with [param n], and then returns the reference.
func n_sub(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.g_sub(d, n)
	return self

## Multiplies the number the reference holds with [param n], and then returns the reference.
func n_mul(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.g_mul(n, d)
	return self

## Multiplies the number the reference holds with the number that [param obj] holds,
## then returns the reference this function was called on.
func mul(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_mul(obj.d, d)
	return self

## Negates the number the reference holds, then returns the reference this function was called on.
func neg() -> BigNumRef:
	d = BigNumRef.g_neg(d)
	return self

## Recipocates the number the reference holds, then returns the reference this function was called on.
func recip() -> BigNumRef:
	d = BigNumRef.g_recip(d)
	return self

## Raises the number the reference holds by [param n], and then returns the reference.
func n_pow(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.g_pow(d, n)
	return self

## Raises the number this reference holds by the number that [param obj] holds,
## then returns the reference this function was called on.
func o_pow(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_pow(d, obj.d)
	return self

## Raises [param n] by the number the reference holds, and then returns the reference.
func n_pow_base(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.g_pow(n, d)
	return self

## Raises the number that [param obj] holds by the number the reference holds,
## mutating the reference [i]the function was called on [b]instead of[/b][/i] [param obj],
## then returns the reference the function was called on.
func pow_base(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_pow(obj.d, d)
	return self

# @GlobalScope.log
## Sets the number the reference holds to the logarithm of the number the reference previously holds by the base of [param obj].
## Returns the reference the function was called on.
func o_log(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_log(obj.d, d)
	return self

## Sets the number the reference holds to the logarithm of [param obj] by the base of the number the reference previously holds.
## Returns the reference the function was called on.
func log_base(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_log(d, obj.d)
	return self

## Sets the number the reference holds to the logarithm of the number the reference previously holds by the base of [param n].
## Returns the reference the function was called on.
func n_log(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.g_log(n, d)
	return self

## Sets the number the reference holds to the logarithm of [param n] by the base of the number the reference previously holds.
## Returns the reference the function was called on.
func n_log_base(n: PackedFloat64Array) -> BigNumRef:
	d = BigNumRef.g_log(d, n)
	return self

## Returns the string representation of the number this reference holds.
func n_str() -> String:
	return BigNumRef.g_to_str(d)

func n_str_to_decimal_places(round_to: int = default_round_to) -> String:
	return BigNumRef.g_to_str_to_decimal_places(d, round_to)

## Returns whether the number held by this reference is equal to [param n].
func n_eq(n: PackedFloat64Array) -> bool:
	return BigNumRef.g_eq(n, d)

## Returns whether the number held by this reference is equal to the number [param obj] holds.
func eq(obj: BigNumRef) -> bool:
	return BigNumRef.g_eq(obj.d, d)

## Returns 1 if the number held by this reference is greater than n, 0 if equal, -1 if n is greater.
func n_compare(n: PackedFloat64Array) -> int:
	return BigNumRef.g_compare(d, n)

## Returns whether the number held by this reference is greater than the number [param obj] holds.
func n_gt(n: PackedFloat64Array) -> bool:
	return BigNumRef.g_gt(d, n)

## Returns whether the number held by this reference is greater than or equal to the number [param obj] holds.
func n_gte(n: PackedFloat64Array) -> bool:
	return BigNumRef.g_gte(d, n)

func defer_l_normalize() -> void:
	if _dirty_l_normalize == false:
		call_deferred("l_normalize")
		_dirty_l_normalize = true

## Normalizes the number currently held by this reference.[br]
## [b]Note:[/b] Users of this library should not need to use this function.
func l_normalize() -> void:
	d = BigNumRef.duplicate_num_only(d) # SORRY
	_dirty_l_normalize = false
