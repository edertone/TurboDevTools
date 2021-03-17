#!/bin/bash

# Stop apache server in case it was previously running
/etc/init.d/apache2 stop;

# Search for all the virtual hosts configurations and copy them to the sites-available folder
find /var/www/virtualhosts -name "*.conf" -exec cp {} /etc/apache2/sites-available \;

# Enable all the virtual hosts on the sites-available folder
a2ensite *;

# Verify that the apache config is correct
apachectl configtest;

echo 'Start apache server';

#This is the entry point for the base docker image and must be called after doing our things
apache2-foreground;