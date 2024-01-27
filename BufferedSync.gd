extends Node
class_name BufferedSync

const sync_interval = 1.0/30.0
var sync_seq = 0
var sync_clock: float = 0.0

var state_buffer = []
var state_interp: float = 0.0
var got_initial_state = false
var target_state_buffer_len = 4
var target_state_buffer_len_min = 4

# for dynamic client state buffer limiting
var segment_time: float = 0.0
var segment_length: float = 5.0
var drops_in_segment: int = 0
var drops_threshold: int = 3
var dropless_segments: int = 0
var dropless_threshold: int = 5
var buffer_increases: int = 0

var server_state = {}

class StateInterp:
	extends RefCounted
	var start_state: Variant
	var end_state: Variant
	var progress: float
	var valid: bool
	
	static func invalid():
		var s = StateInterp.new()
		s.valid = false
		return s
	
	static func create(sbuf: Array, key: String, interp: float):
		if len(sbuf) < 1:
			return StateInterp.invalid()
		
		var s = StateInterp.new()
		s.valid = true
		if key not in sbuf[0]:
			return StateInterp.invalid()
		s.start_state = sbuf[0][key]
		
		if len(sbuf) == 1:
			s.end_state = s.start_state
			s.progress = 0.0
		else:
			if key not in sbuf[1]:
				return StateInterp.invalid()
			s.end_state = sbuf[1][key]
			s.progress = interp
			
		return s

func _process(delta):
	if multiplayer.is_server():
		sync_clock += delta
		if sync_clock > sync_interval:
			sync_seq += 1
			sync_clock -= sync_interval
			if sync_clock > sync_interval:
				push_warning("sync interval lagging - resetting sync clock")
				sync_clock = 0.0
			server_state["S"] = sync_seq
			sync_state.rpc(server_state)
			server_state = {}
	else:
		state_interp += delta
		
		# adjust state buffer max based on quality of network
		segment_time += delta
		if segment_time >= segment_length:
			if drops_in_segment == 0:
				dropless_segments += 1
				if dropless_segments > dropless_threshold:
					if target_state_buffer_len > target_state_buffer_len_min:
						target_state_buffer_len -= 1
						print("decreasing state buffer to %d" % target_state_buffer_len)
					dropless_segments = 0
			elif drops_in_segment > drops_threshold:
				dropless_segments = 0
				dropless_threshold += 1
				target_state_buffer_len += 1
				buffer_increases += 1
				print("increasing state buffer to %d" % target_state_buffer_len)
				if buffer_increases > 3:
					buffer_increases = 0
					target_state_buffer_len_min += 1
			
			drops_in_segment = 0
			segment_time = 0.0

func amend_server_state(key: String, value: Variant):
	server_state[key] = value

@rpc("authority", "call_remote", "unreliable", 2)
func sync_state(state: Dictionary):
	if len(state_buffer) < 1:
		got_initial_state = true
		state_interp = 0.0
		state_buffer.append(state)
	elif state["S"] > state_buffer[-1]["S"]:
		state.merge(state_buffer[-1])
		state_buffer.append(state)
		if state["S"] > state_buffer[-1]["S"] + 1:
			push_warning("state seq skipped %d" % state["S"] - state_buffer[len(state_buffer) - 1]["S"])
	elif state["S"] < state_buffer[0]["S"]:
		push_warning("state drop %d" % state["S"])
	else:
		var idx = 1
		while idx < len(state_buffer):
			if state["S"] == state_buffer[idx]["S"]:
				push_warning("state dupe %d" % state["S"])
				break
			elif state["S"] < state_buffer[idx]["S"]:
				push_warning("state OOO %d" % state["S"])
				break
			idx += 1

func get_state(key: String) -> StateInterp:
	# remove expired states
	while state_interp > sync_interval:
		state_interp -= sync_interval
		if len(state_buffer) > 1:
			state_buffer.pop_front()
		else:
			push_warning("state buffer depleted")
			state_interp = 0.0
			return StateInterp.invalid()
	
	# remove over-buffered states
	var overbuffered: int = len(state_buffer) - target_state_buffer_len
	if overbuffered > 0:
		push_warning("dropping %d over-buffered states" % overbuffered)
		drops_in_segment += 1
		state_interp = sync_interval
		state_buffer = state_buffer.slice(overbuffered)
	
	return StateInterp.create(state_buffer, key, state_interp / sync_interval)
