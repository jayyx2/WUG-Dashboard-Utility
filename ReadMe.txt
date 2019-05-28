**USE AT YOUR OWN RISK AND WITH CAUTION, THIS PROGRAM INTERACTS DIRECTLY WITH THE WHATSUP GOLD DATABASE**

This utility is for interacting in bulk with WhatsUp Gold dashboards

To use, you must provide a configuraiton file in the following format:

sqlservername\instance
sqluser
sqlpassword
databasename


A sample login file is included, named "login.txt" if you're having trouble.
The only thing require in this file is the first line which asks for SQL Server
Name and instance. The other fields are optional and if not found, the program
will prompt for them.

The file "default_dashboard.txt" contains the SQL statements required to recreate
the default dashboards. It is set to read-only, should not be modified, and 
needs to be in the same directory as the .exe.

If encounter any problems or have questions, e-mail jason@wug.ninja Enjoy!

--Jason
