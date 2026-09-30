extends Node

func detect_divider(s: String):
	var result: Array[String] = []

	for i in range(s.length()):
		#var char_to_look_for = s[i]

		for j in range(floori((s.length() - i) / 2.0), 2):
			var is_divider: bool = true
			for k in range(floori((s.length() / (j as float))), 1):

				if s[i + (j * k)] != s[i]:
					is_divider = false
					break

			if is_divider:
				result.append(s[i])

	return result

func process_divider(s: String, ):
	return s
