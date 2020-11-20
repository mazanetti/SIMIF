# SIMIF (Shiny Interface for Municipality Interactive Forecasts)
## Previsioni meteo a scala comunale sulla Lombardia by ShinyApp
### Introduzione
SIMIF è un applicativo in grado di restituire previsioni meteorologiche a 72h per qualsiasi comune della Lombardia. Al 20-11-2020 le variabili visualizzabili, a scadenza oraria, sono temperatura a 2m, precipitazione cumulata, nuvolosità (in ottavi), velocità e direzione del vento a 10m. I dati sono elaborazioni dal modello numerico COSMO 5M.

### La tecnologia
L'applicativo è costruito attraverso il pacchetto R denominato Shiny (https://shiny.rstudio.com/), il quale sfrutta l'interattività dei grafici del pacchetto PLOTLY (https://plotly.com/r/), già sviluppato anche per il linguaggio PYTHON.

L'architettura dello script prevede l'utilizzo di un file NetCDF contenente tutte le variabili sopracitate e proveniente da elaborazioni utilizzate anche dall'applicativo CIUMBIA (https://github.com/ARPASMR/ciumbia), in seguito sono presenti istruzioni di interpolazione e creazione di un database, lo stesso che l'app di Shiny utilizza per funzionare.
Nel dettaglio:


