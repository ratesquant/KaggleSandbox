library(R.utils)

folder = 'W:/hmda/LAR'
files = list.files(folder, glob2rx('*.csv'), full.names = TRUE)

for(file_name in files){
  bzip2(file_name)
}