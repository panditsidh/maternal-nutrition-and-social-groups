//This do file sets paths for Sidh and Diane to run the code to generate tables and figures for the paper "Fertility and Maternal Undernutrition by Indian Social Group"

* we can delete everything except for YOUR USERNAME one before submission.

if "`c(username)'" == "YOUR USERNAME" {
	
	global nfhs5ir "YOUR FILEPATH TO IAIR7EFL.DTA"
	
	global dataset "WHEREVER YOU'D LIKE THE DATASET STORED"

	cd "FILEPATH TO THIS FOLDER"
	
	global paths "FILEPATH TO THIS FILE"
	
	global ihds1_individual "FILEPATH TO IHDS-1/DS0001/22626-0001-Data.dta"
	
	global ihds1_household "FILEPATH TO IHDS-1/DS0002/22626-0002-Data.dta"
	
	
	global ihds2_individual "FILEPATH TO IHDS-2/DS0001/36151-0001-Data.dta"
	
	
	global ihds2_household "FILEPATH TO IHDS-2/DS0002/36151-0002-Data.dta"
	
	global ihds2_ewomen "FILEPATH TO IHDS-2/DS0003/36151-0003-Data.dta"
	
}


if "`c(username)'" == "sidhpandit" {
// 	global nfhs3ir "/Users/sidhpandit/Desktop/data/nfhs/nfhs3ir/IAIR52FL.dta"
// 	global nfhs4ir "/Users/sidhpandit/Desktop/data/nfhs/nfhs4ir/IAIR74FL.DTA"	
	global nfhs5ir "/Users/sidhpandit/Desktop/data/nfhs/nfhs5ir/IAIR7EFL.DTA"

// 	global nfhs3br "/Users/sidhpandit/Desktop/data/nfhs/nfhs3br/IABR52FL.dta"
// 	global nfhs4br "/Users/sidhpandit/Desktop/data/nfhs/nfhs4br/IABR74FL.DTA"
// 	global nfhs5br "/Users/sidhpandit/Desktop/data/nfhs/nfhs5br/IABR7EFL.DTA"
	global dataset "/Users/sidhpandit/Dropbox/maternal nutrition by social group/data/prepared_dataset.dta"

	cd "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups"
	
	global paths "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/000_paths.do"
	
// 	global nfhs5mr "/Users/sidhpandit/Desktop/nfhs/nfhs5mr/IAMR7EFL.DTA"
//	
// 	global nfhs5hmr "/Users/sidhpandit/Desktop/nfhs/nfhs5hmr/IAPR7EFL.DTA"
//	
// 	global nfhs5hr "/Users/sidhpandit/Desktop/nfhs/nfhs5hr/IAHR7EFL.DTA"
//	
	global ihds1_individual "/Users/sidhpandit/Desktop/data/IHDS/IHDS-1/DS0001/22626-0001-Data.dta"
	
	global ihds1_household "/Users/sidhpandit/Desktop/data/IHDS/IHDS-1/DS0002/22626-0002-Data.dta"
	
	
	global ihds2_individual "/Users/sidhpandit/Desktop/data/IHDS/IHDS-2/DS0001/36151-0001-Data.dta"
	
	
	global ihds2_household "/Users/sidhpandit/Desktop/data/IHDS/IHDS-2/DS0002/36151-0002-Data.dta"
	
	global ihds2_ewomen "/Users/sidhpandit/Desktop/data/IHDS/IHDS-2/DS0003/36151-0003-Data.dta"
	
}



if "`c(username)'" == "dc42724" {
// 	global nfhs3ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS06\ir\IAIR52FL.dta"
// 	global nfhs4ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS15\ir\IAIR71FL.DTA"
	global nfhs5ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS19\IAIR7DDT\IAIR7DFL.DTA"
	
// 	global nfhs3br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS06\br\IABR52FL.dta"
// 	global nfhs4br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS15\br\IABR71FL.DTA"
// 	global nfhs5br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS19\IABR7EDT\IABR7EFL.DTA"

	global dataset "C:\Users\dc42724\Dropbox\K01\maternal-nutrition-social-group\data\prepared_dataset.dta"
	
	cd "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups"
	
	global paths "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\cleaned do files - reviewed\000_paths.do"
}


if "`c(hostname)'" == "PPRC-STATS-P01" {
	
	
	global nfhs3ir "Q:\Coffey\Users\SidhPandit\nfhs3ir\IAIR52FL.dta"
	
	global nfhs3br "Q:\Coffey\Users\SidhPandit\nfhs3br\IABR52FL.dta"
	
	global nfhs5ir "Q:\Coffey\Users\SidhPandit\nfhs5ir\IAIR7EFL.dta"
	
	global nfhs5br "Q:\Coffey\Users\SidhPandit\nfhs5br\IABR7EFL.dta"
	
*	global dataset "C:\Users\dc42724\Dropbox\K01\maternal-nutrition-social-group\data\prepared_dataset.dta"

	
	cd "C:\Users\ssp2843\Documents\GitHub\maternal-nutrition-and-social-groups"
	
	
}




