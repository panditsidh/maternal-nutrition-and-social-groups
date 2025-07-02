if "`c(username)'" == "sidhpandit" {
	global nfhs3ir "/Users/sidhpandit/Desktop/nfhs/nfhs3ir/IAIR52FL.dta"
	global nfhs4ir "/Users/sidhpandit/Desktop/nfhs/nfhs4ir/IAIR74FL.DTA"	
	global nfhs5ir "/Users/sidhpandit/Desktop/nfhs/nfhs5ir/IAIR7EFL.DTA"
	
	global nfhs3br "/Users/sidhpandit/Desktop/nfhs/nfhs3br/IABR52FL.dta"
	global nfhs4br "/Users/sidhpandit/Desktop/nfhs/nfhs4br/IABR74FL.DTA"
	global nfhs5br "/Users/sidhpandit/Desktop/nfhs/nfhs5br/IABR7EFL.DTA"
	
	cd "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups"
	
}

if "`c(username)'" == "dc42724" {
	global nfhs3ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS06\ir\IAIR52FL.dta"
	global nfhs4ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS15\ir\IAIR71FL.DTA"
	global nfhs5ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS19\IAIR7DDT\IAIR7DFL.DTA"
	
	global nfhs3br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS06\br\IABR52FL.dta"
	global nfhs4br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS15\br\IABR71FL.DTA"
	global nfhs5br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS19\IABR7EDT\IABR7EFL.DTA"
	
	cd "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups"
}




if "`c(hostname)'" == "PPRC-STATS-P01" {
	
	
	global nfhs3ir "Q:\Coffey\Users\SidhPandit\nfhs3ir\IAIR52FL.dta"
	
	global nfhs3br "Q:\Coffey\Users\SidhPandit\nfhs3br\IABR52FL.dta"
	
	global nfhs5ir "Q:\Coffey\Users\SidhPandit\nfhs5ir\IAIR7EFL.dta"
	
	global nfhs5br "Q:\Coffey\Users\SidhPandit\nfhs5br\IABR7EFL.dta"
	
	cd "C:\Users\ssp2843\Documents\GitHub\maternal-nutrition-and-social-groups"
	
	
}
