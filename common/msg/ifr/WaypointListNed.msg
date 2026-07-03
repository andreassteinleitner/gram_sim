# Topic added by iFR for the waypoint publisher module. Extracts waypoints from the dataman in x/y/z local coordinates to be used by other iFR GNC modules

uint64 timestamp		# time since system start (microseconds)

float32[20] x    
float32[20] y   
float32[20] z
uint16 count