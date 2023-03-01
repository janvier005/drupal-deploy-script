# drupal-deploy-script

*This a beta, please use it only for testing purposes*

This is script is able to setup debian or ubuntu server to host new or exsting Drupal 9 website.


## New websites
Drupal will be installed with a minimal profile and without any extensions


## Existing websites
Datas can come from a Github repository. After code deployment, drush cim will be run ton init and import config. Drush dcdes is run after in order to import casual existing contents.


## Using config.var file
Yout set all variables required to start script into the file called config.var. It must be located into the same folder as deploy.sh. To use the settings collected into config.var with deploy.sh, you have to choose to use this file just after having launched script.
