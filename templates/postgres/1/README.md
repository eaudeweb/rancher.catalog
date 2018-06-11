# POSGRES DB rancher template

## Variables:

1. Schedule Postgres service on hosts with the following host labels - Comma separated list of host labels (e.g. key1=value1, key2=value2) to be used for scheduling
2. Postgres User - the user with admin rights on the database
3. Postgres Password - postgres password
4. Time zone - Local Time zone


## Load balancer configuration:

1. Add Load balancer Service Rule - with the following selected: Public, TCP on port 5432 on master container

