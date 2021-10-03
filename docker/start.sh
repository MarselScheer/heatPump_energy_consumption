#!/bin/zsh

sudo docker run --user shiny --rm -d -p 80:3838 \
     -v /srv/shinyapps/:/srv/shiny-server/ -v /tmp/:/var/log/shiny-server/ \
     -v /mnt/samba/data/m/shinyApps/heatpump/:/srv/data/ heat_pump:0.2.0
