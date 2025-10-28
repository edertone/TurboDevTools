# Html to PDF command line converter utility with docker

This docker image contains a minimal installation of the chromium browser that is used as a cmd html to pdf converter tool. It can be used to generate pdf files from existing html files without needing to install anything and on any operating system.

## Features

  - Chromium installed on an alpine linux
  
## Pre requisites

- An existing machine with docker installed

## Run the html to pdf conversion

Simply execute this at the folder were the docker-compose.yml file is located:
```
docker-compose run --rm html-pdf-converter example.html example.pdf
```

What does this do:
* `docker-compose run`: This is the key command. It starts a one-off instance of a service for a specific task.
* `--rm`: This flag is important. It automatically removes the container after it finishes its job, keeping your system clean.
* `html-pdf-converter`: This specifies which service from your `docker-compose.yml` file you want to run.
* `example.html example.pdf`: These are the arguments passed to your container. They override the default `CMD` and are picked up by your `entrypoint.sh` script as the input and output filenames.

After running the command, you will find a new file named `example.pdf` in your directory.
  
## Apendix: How to rebuild the full image from scratch

Simply execute this at the folder were the docker-compose.yml file is located:
```
docker-compose build --no-cache
```

### Donate
	
[![Donate](https://raw.githubusercontent.com/edertone/DEV-Tools/master/Virtualization/Docker/Images/php7-apache-vhosts/donate-button.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=53MJ6SY66WZZ2&lc=ES&item_name=php7-apache-vhosts&no_note=0&cn=A%c3%b1adir%20instrucciones%20especiales%20para%20el%20vendedor%3a&no_shipping=2&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)