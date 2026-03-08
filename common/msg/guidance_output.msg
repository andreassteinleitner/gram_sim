uint64 timestamp		# time since system start (microseconds)
float32[60] cruise_wps	# all wps used for cruise loitering
float32 curr_wp_id
float32[3] curr_wp		# north,east,down
float32[3] offset		# deviation from runway (lon, lat, vert)
float32 v_cmd
float32 chi_cmd
float32 psi_cmd
float32 roll_lim
float32 gamma_cmd
float32 alpha_cmd