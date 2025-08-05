# RT10W Power Sleep

This script contains settings to do the following on Honeywell RT10W Tablet: 

- Sets auto-logon (note this is done with registry settings so the password is stored in plain text)
- Sets it so screeen timeout and power button do not require login when waking 

It accomplishes this by: 

- Writing `.reg` settings to a temporary file and merges them silently.
- Runs all the `powercfg` commands for power button action and no lock on wake.

# To Run 

- Change variables for the auto-logon feature 
- Copy and run on tablet or execute remotely 