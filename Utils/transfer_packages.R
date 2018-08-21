
filename = file.path(Sys.getenv("HOME"), 'source/installed_packages.rda')

# run in previous R version
tmp = installed.packages()
installedpackages = as.vector(tmp[is.na(tmp[,"Priority"]), 1])
saveRDS(installedpackages, file=filename)



# run in current R version
installedpackages = readRDS(filename)
tmp = installed.packages()
current_packages = as.vector(tmp[is.na(tmp[,"Priority"]), 1])
missing_packages = setdiff(installedpackages, current_packages)
for (pkg in missing_packages) install.packages(pkg)