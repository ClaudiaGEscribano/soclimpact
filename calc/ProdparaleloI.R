library(raster)
#library(maps)
#library(maptools)
library(parallel)
library(solaR)
 
## Calculate  productivity using parallel function

source('fooIProd.R')

##########################################################################
## 1. DATA
#########################################################################


SISS <- brick("../data/CRE_rsds_2000_2001.nc")

Tas <- brick("../data/CRE_tas_2000_2001.nc")
Tas <- Tas-273.15

tt <- seq(
    from=as.POSIXct("2000-1-1 0:00", tz="UTZ"),
    to=as.POSIXct("2001-12-31 21:00", tz="UTZ"),
    by="3 hour")

SISS <- setZ(SISS, tt)
Tas <- setZ(Tas, tt)

names(SISS) <- tt
names(Tas) <- tt

y <- init(SISS, v='y')

########################################################################
## 2. ProdCGPV Yearly productivity
########################################################################

cell <- 200
x <- as.vector(SISS[200])
xx <- as.vector(Tas[200])
lat <- y[200]
data <- c(lat, x, xx)
  

#modeTrk <-'fixed'
 
yProdFixed <- fooParallel(SISS, Tas)
 
#################################################

yProdFixed <- stack(yProdFixed)

writeRaster(yProdFixed, filename='pruebadaily_3h_CRE_2000-2001.grd', overwrite=TRUE)



