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
    from=as.POSIXct("2000-1-1 0:00", tz="UTC"),
    to=as.POSIXct("2001-12-31 21:00", tz="UTC"),
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
g0 <- as.vector(SISS[cell])
ta <- as.vector(Tas[cell])
lat <- y[cell]
  
BDi <- zoo(data.frame(G0 = g0, Ta = ta),
           order.by = tt)

Prod <- prodGCPV(lat = lat,
                 modeRad = 'bdI',
                 dataRad= list(lat = lat, file = BDi),
                 keep.night=TRUE, modeTrk = 'fixed')
 

p <- as.zooI(Prod, complete = TRUE)

xyplot(p[1:10, c("Bo0", "G0")], superpose = TRUE)

#################################################
## Parallel
##################################################################
yProdFixed <- fooParallel(SISS, Tas)

yProdFixed <- stack(yProdFixed)

writeRaster(yProdFixed, filename='pruebadaily_3h_CRE_2000-2001.grd', overwrite=TRUE)



