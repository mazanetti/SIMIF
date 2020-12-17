# SIMIF (Shiny Interface for Municipality Interactive Forecasts)
## Previsioni meteo a scala comunale sulla Lombardia by ShinyApp
### Introduzione
SIMIF è un applicativo in grado di restituire previsioni meteorologiche a 72h per qualsiasi comune della Lombardia. Al 20-11-2020 le variabili visualizzabili, a scadenza oraria, sono temperatura a 2m, precipitazione cumulata, nuvolosità (in ottavi), velocità e direzione del vento a 10m. I dati sono elaborazioni dal modello numerico COSMO 5M.

### La tecnologia
L'applicativo è costruito attraverso il pacchetto R denominato Shiny (https://shiny.rstudio.com/), il quale sfrutta l'interattività dei grafici del pacchetto PLOTLY (https://plotly.com/r/), già sviluppato anche per il linguaggio PYTHON.

### La struttura
L'architettura dell'app prevede l'utilizzo di un file NetCDF contenente tutte le variabili sopracitate e proveniente da elaborazioni utilizzate anche dall'applicativo CIUMBIA (https://github.com/ARPASMR/ciumbia), in seguito sono presenti istruzioni di interpolazione e creazione di un database, lo stesso che l'app di Shiny utilizza per funzionare.
Ulteriori dettagli sui "mattoni" che costutuiscono l'applicazione sono disponibili nel file caricato su questa repository: https://github.com/mazanetti/SIMIF/blob/main/Architettura_SIMIF.pdf

### Funzionamento da container
_In aggiornamento_

### Utilizzo dell'app
L'applicazione è raggiungibile da rete interna di Arpa al seguente indirizzo: http://10.10.0.29:8803/, oppure attraverso un link dedicato sulla pagina principale di GHOST (10.10.0.14).
L'interfaccia si compone di un form di "ricerca comune" diviso per provincia e di 4 output in risposta alla selezione dell'utente.
Nel dettaglio:
- Una mappa per geolocalizzare il comune
- Tre grafici di previsione che mostrano: temperatura (° C), nuvolosità (ottavi), precipitazioni (mm), velocità e direzione del vento (m/s e gradi sessagesimali)
- Una tabella dati con temperatura e precipitazioni

La particolare caratteristica dei grafici è quella di essere "dinamici", ossia con possibilità di interagire con gli stessi attraverso selezioni, zoom etc...
Di seguito un esempio di come si presenta l'interfaccia grafica:

 ![Esempio di interfaccia grafica](Es_interfaccia.PNG)
 
### Avvertenze
L'output modellistico non presenta modifiche e/o variazioni in relazione alla quota reale della casa comunale (diversa da quella stimata del modello), quindi ad esempio la temperatura sui comuni di montagna può non risultare sempre accurata.
Le previsioni vengono aggiornate ogni mattina entro le 9:00, al momento non sono previste modifiche al fine di lasciare traccia di run del modello vecchi, quindi quello presente è sempre l'ultimo disponibile (o funzionante).

### Nuovi sviluppi
Ulteriori campi di sviluppo possono riguardare:
- l'implementazione di nuovi modelli al fine di allungare l'orizzonte temporale di previsione (es. ECMWF)
- L'aggiunta del run delle 12 del modello COSMO 5M
- Discriminazione della neve dalle precipitazioni
- Aggiunta di nuove variabili da visualizzare
- Maggiori informazioni (es. quota, coordinate etc. etc.) sul comune selezionato
- Tutto quello che la mente può partorire

### Riferimenti
Matteo Zanetti
mzanetti1986@gmail.com

