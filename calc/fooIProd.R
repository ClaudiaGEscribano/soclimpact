library(raster)
library(rasterVis)
library(solaR)
library(zoo)
library(ncdf4)

fooParallel <- function(data, data2){
    y <-init(data, v='y')

    modeTrk <-'fixed'
    blocks <- 6
    nodes <- detectCores()
    bs <- blockSize(data, minblocks=blocks*nodes)
    ## List with the indices of blocks for each node
    iCluster <- splitIndices(bs$n, nodes)
 
fooProdI <- function(x, modeTrk = 'fixed', timePeriod = 'day'){
    ## Number of days
    n <- (length(x) - 1)/2
    lat <- x[1]
    g0 <- x[2:(n + 1)]
    Ta <- x[(n + 2):(2*n + 1)]
    BDi <- zoo(data.frame(G0 = g0, Ta = Ta),
              order.by = tt)
    Prod <- prodGCPV(lat = lat,
                     modeRad = 'bdI',
                     dataRad= list(lat = lat, file = BDi),
                     keep.night=TRUE, modeTrk = 'fixed')
    switch(timePeriod,
           year = as.data.frameY(Prod)['Yf'],
           month = as.data.frameM(Prod)['Yf'],
           day = as.data.frameD(Prod)['Yf'],
           intra = as.data.frameI(Prod)['Pac']
           )
}     
    resCl <- mclapply(iCluster,
                  ## Each node receives an element of iCluster, a set of indices
                  function(icl){
                      resList <- lapply(icl, function(i){
                          ## An element of icl is the number of block to
                          ## be read by each node
                          vG0 <- getValues(data, bs$row[i], bs$nrows[i])
                          vTa <- getValues(data2, bs$row[i], bs$nrow[i])                             
                          lat <- getValues(y, bs$row[i], bs$nrows[i])
                          vals <- cbind(lat, vG0, vTa)
                          cat('Lat: ', i, ':', range(lat), '\n')
                          res0 <- try(apply(vals, MARGIN=1L,
                                            FUN=fooProdI,
                                            modeTrk = modeTrk))
                          if (!inherits(res0, 'try-error')) 
                          {
                              res0 <- do.call(cbind, res0)
                              cat('Res: ', i, ':', range(res0), '\n')
                          } else
                          {
                              res0 <- NA
                              cat("Res:", i, ": NA\n")
                          }
                          res0
                      })
                      do.call(cbind, resList)
                  },
                  mc.cores = nodes)
    
    ## The result of mclapply is a list with as many elements as nodes
    resCl <- do.call(cbind, resCl)  
    resCl <- t(resCl) 
    ##nYears <- ncol(resCl)
 
    out <- brick(SISS) # nl = nYears) 
    out <- setValues(out, resCl)
    out
}
 
## head(as.data.frameI(prodGCPV(lat = lat,
##                      modeRad = 'bdI',
##                      dataRad= list(lat = lat, file = BDi),
##                      keep.night=TRUE, modeTrk = 'fixed')))
 
