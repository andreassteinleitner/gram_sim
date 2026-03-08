funcubXL_flaps_mod: with XFLR5: FunCub_Flaps0_Eta2, FunCub_Flaps50_Eta6, FunCub_Flaps100_Eta10
	Contains six trim speeds for each flap setting
	Enables interpolation of aerodynamics for continuous flap commands (see heterogeneous_distribution==0 in fm_funcub)
	
funcubXL_flaps: with XFLR5: FunCub, FunCub_Flaps50, FunCub_Flaps100
	Copies old values for flaps 0 with only four converging trim settings
	Six trim settings for Flaps50 and Flaps100
	
funcubXL_flaps_old: Old aerodynamic files, not used anymore