uint64 timestamp	# vergangene Zeit seit Systemstart [Mikrosekunden]

float32[3] rates_raw	# unfiltered rates [rad/s]
float32[3] rates_filt	# filtered rates [rad/s]
float32[3] rates_filt_ma # moving average on filtered rates [rad/s]
float32[3] acc_filt	# accelerations [m/s^2]
float32[3] ang_acc	# angular accelerations (filtered) [rad/s^2]
float32[3] ang_acc_ma	# moving average on angular accelerations (filtered) [rad/s^2]
float32 omega	# frequency parameter used for second order low-pass filter [Hz]
float32 zeta	# damping parameter used for second order low-pass filter
