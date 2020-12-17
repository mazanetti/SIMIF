# base image
FROM debian:stable-slim 

# chiavi ssh, certificato Arpa, locale
COPY ./conf/id_rs* /root/.ssh/
COPY ./conf/known_hosts /root/.ssh/
RUN chmod 600 /root/.ssh/id_rsa
COPY ./conf/cert.pem /etc/pki/tls/
COPY ./conf/cert.pem /etc/pki/ca-trust/source/anchors/
COPY ./conf/locale.gen /etc/

# passo usr e pwd per il proxy;
ARG SECRET
ENV http_proxy=http://${SECRET}@proxy2:8080
ENV https_proxy=http://${SECRET}@proxy2:8080
ENV NO_PROXY=localhost,.arpa.local,127.0.0.1

# modalita' non interattiva
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# installo i pacchetti di sistema + R 
RUN apt-get update && apt-get install -y apt-utils sudo curl openssh-client libssl-dev
RUN apt-get install -y openssl sqlite3 libsqlite3-dev git python3 libhdf5-dev libnetcdf-dev libgdal-dev r-base r-base-dev

RUN mkdir -p /opt/simif/db
RUN mkdir -p /opt/simif/nc
COPY ./function /opt/simif/function
COPY app.R /opt/simif/
COPY entryscript /opt/simif/
COPY procedure_simif.sh /opt/simif/ 
RUN chmod -R 777 /opt/simif/

# R packages
RUN R -e "install.packages('Rcpp', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('RSQLite', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('lubridate', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('jsonlite', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('curl', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('openssl', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('httr', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('fields', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('maps', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('raster', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('R2HTML', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('DT', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('plotly', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('leaflet', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('dplyr', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('tidyverse', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('ncdf4', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('shiny', repos = 'http://cran.us.r-project.org')"

# ll alias 
RUN echo "# .bash_aliases" >> /root/.bash_aliases \
        && echo "" >> /root/.bash_aliases && echo "alias ll='ls -alh'" >> /root/.bash_aliases \
        && echo "" >> /root/.bashrc \
        && echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" >> /root/.bashrc

# volumi
VOLUME /opt/simif/db
VOLUME /opt/simif/nc

# porte
EXPOSE 8803

# entrypoint
WORKDIR /opt/simif
ENTRYPOINT ["/bin/bash", "/opt/simif/entryscript"]

