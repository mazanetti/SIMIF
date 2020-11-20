#library(dbplyr)
#library(dplyr)
#library(rlang)
#library(plotly)
library(lubridate)#m
library(tidyverse)
library(ncdf4)#m
library(DBI)#m
library(fields)#m

comuni_db <- dbConnect(RSQLite::SQLite(), dbname = "db_archive\\comuni_db") #creo db di nome comuni_db
comuni_lomb <- dbReadTable(comuni_db,"comuni_db")

#Acquisizione variabili accessorie
lat_comuni<-comuni_lomb$Latitudine
lon_comuni<-comuni_lomb$Longitudine
coord_comuni<-cbind(lon_comuni,lat_comuni)

#Acquisizione campi COSMO 5M
ncfile_surf <- nc_open("C:\\Users\\mazanetti\\Documents\\Siri\\SIMIF\\nc\\sorted_surf_C5M.nc")
z <- ncvar_get(ncfile_surf, "p3008")
#mx2t1 <- ncvar_get(ncfile_surf, "mx2t6")
#mn2t1 <- ncvar_get(ncfile_surf, "mn2t6")
tp  <- ncvar_get(ncfile_surf, "tp")
sf  <- ncvar_get(ncfile_surf, "lssf")
t2m <- ncvar_get(ncfile_surf, "t2m")
d2m <- ncvar_get(ncfile_surf, "d2m")
u10 <- ncvar_get(ncfile_surf, "u10")
v10 <- ncvar_get(ncfile_surf, "v10")
tcc <- ncvar_get(ncfile_surf, "tcc")
hcc <- ncvar_get(ncfile_surf, "hcc")
mcc <- ncvar_get(ncfile_surf, "mcc")
lcc <- ncvar_get(ncfile_surf, "lcc")

#Variabili accessorie che possono essere acquisite una volta sola visto che il modello è lo stesso
lat  <- ncvar_get(ncfile_surf, "latitude")
nlat <- dim(lat)
lon  <- ncvar_get(ncfile_surf, "longitude")
nlon <- dim(lon)
time <- ncvar_get(ncfile_surf,"time")
ntime<- dim(time)


############################# FUNZIONI #####################
# E necessario interpolare i punti di griglia del modello affinchè io possa avere il dato per ogni comune lombardo
# Creo quindi una funzione "interpola" con la libreria "fields"
interpola<-function(var,lon,lat,punti) {
  nlat  <-dim(lat)
  nscad <-dim(var)[3]
  npunti<-dim(punti)[1]
  
  var_int<-array(0,c(npunti,nscad))
  
  for (t in 1:nscad){
    var_obj<-list( x=lon, y=rev(lat), z=var[,nlat:1,t])
    var_int[,t]<-interp.surface(var_obj,punti)
  }
  
  return(var_int)
}

#Funzione che scumula la precipitazione convettiva
scumula <- function(tp) {
  
  ntime <-dim(tp)[3]
  nlon  <-dim(tp)[1]
  nlat  <-dim(tp)[2]
  
  var_scumulata <- array(0,c(nlon,nlat,ntime))
  for (t in 1:ntime){
    if (t==1){
      var_scumulata[,,t] <- tp[,,t] #il primo step temporale non va toccato cumulata(0 - 3h)
    } else {
      var_scumulata[,,t]<-tp[,,t]-tp[,,t-1]
    }
  }
  
  return(var_scumulata)
  
}

#Funzione che tramuta la tcc in ottavi
copertura <- function(tcc) {
  
  ntime <-dim(tcc)[3]
  nlon  <-dim(tcc)[1]
  nlat  <-dim(tcc)[2]
  
  tcc_8 <- array(0,c(nlon,nlat,ntime))
  for (t in 1:ntime){
    tcc_8[,,t] <- round(tcc[,,t] * 0.08,digits = 0)
  }
  return(tcc_8)
}

#Funzione che calcola velocità e direzione del vento
vento <- function(u10,v10) {
  
  ntime <- dim(u10)[3]
  nlon <- dim(u10)[1]
  nlat <- dim(u10)[2]
  
  vv <- array(0,c(nlon,nlat,ntime))
  dv <- array(0,c(nlon,nlat,ntime))
  
  for(t in 1:ntime){
    vv[,,t] <- sqrt(u10[,,t]^2 + v10[,,t]^2)
    dv[,,t] <- 270-(atan2(v10[,,t], u10[,,t])*(180/pi))%%360
  }
  return(list(vv,dv))
}
  
########################################################## APPLICO FUNZIONI PREC E NUVOLOSITA'
#maneggio il vettore delle precipitazioni 
tp_scumulate <- scumula(tp) #Scumulo la variabile per avere la quantità ogni 3 ore
tcc <- copertura(tcc)
#la lista "vento" viene separata nelle due variabili velocità e drezione
vento <- vento(u10,v10)
vv <- vento[[1]]
dv <- vento[[2]]

################### Creazione del Database Meteo COSMO 5M #######################################à
meteo_db_5m <- dbConnect(RSQLite::SQLite(),dbname = "db_archive\\meteo_db_5m")

t<-as.POSIXlt(time*3600, origin = "1900-01-01", tz = "GMT")
t <- format(t,"%Y/%m/%d %H:%M")

z_int	<- interpola(z,lon,lat,coord_comuni)
t2m_int <- interpola(t2m,lon,lat,coord_comuni)
d2m_int <- interpola(d2m,lon,lat,coord_comuni)
u10_int <- interpola(u10,lon,lat,coord_comuni)
v10_int <- interpola(v10,lon,lat,coord_comuni)
vv_int <- interpola(vv,lon,lat,coord_comuni)
dv_int <- interpola(dv,lon,lat,coord_comuni)
tcc_int <- interpola(tcc,lon,lat,coord_comuni)
hcc_int <- interpola(hcc,lon,lat,coord_comuni)
mcc_int <- interpola(mcc,lon,lat,coord_comuni)
lcc_int <- interpola(lcc,lon,lat,coord_comuni)
prec_int <- interpola(tp_scumulate,lon,lat,coord_comuni)
#snow_int <- interpola(snow,lon,lat,coord_comuni)

#Arrotondo
t2m_int <- round(t2m_int-273.16,digits=1)
prec_int <- round(prec_int,digits = 0)
tcc_int <- round(tcc_int,digits = 0)
vv_int <- round(vv_int,digits = 1)
dv_int <- round(dv_int,digits = 0)
u10_int <- round(u10_int,digits = 1)
v10_int <- round(v10_int,digits = 1)


j=2
#Ciclo sulle varie scadenze (73) e scrittura progressiva del nuovo db
for (i in 1:(ntime-1)){
  t2m_slice_int <- as.vector(t2m_int[,j])
  tp_slice_int <- as.vector(prec_int[,i])
  tcc_slice_int <- as.vector(tcc_int[,j])
  vento_vv_slice_int <- as.vector(vv_int[,j])
  vento_dv_slice_int <- as.vector(dv_int[,j])
  u_slice_int <- as.vector(u10_int[,j])
  v_slice_int <- as.vector(v10_int[,j])
  campi_interpolati <- data.frame(cbind(comuni_lomb$Comune, comuni_lomb$SiglaProv, 
                          t2m_slice_int, tcc_slice_int, tp_slice_int,vento_vv_slice_int,vento_dv_slice_int,u_slice_int,v_slice_int, t[i]))
  names(campi_interpolati) <- c("Comune","Provincia","Temperatura","Copertura del cielo","Precipitazioni",
                                "VV","DV","u10","v10","Orario")
  dbWriteTable(meteo_db_5m,"meteo_comune_5m",campi_interpolati,append=TRUE)
  j = j+1
}

#Disconnetto il db
dbDisconnect(meteo_db_5m)
dbDisconnect(comuni_db)


