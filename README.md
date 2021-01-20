# CentralBackup2
CentralBackup2 is a simple Bash backup solution for local or remote hosts. It allows you to backup files, databases cron tasks, list of installed packages. The output is a compressed .tar.gz file for each backup.

A bunch of linux distro are supported (DEB/RPM) : Debian, Raspbian, Fedora, ~~CentOS~~, RedHat Entreprise Linux, Ubuntu...

## How it works ?

This is very simple, CentralBackup2 is meant to be installed on one central host which will backup itself and several other hosts.

![ ](https://github.com/ycambourieu/CentralBackup2/blob/main/screenshots/schema.png)

//TODO : Schema

Backups and logs are stored locally on the central host. Options to add other type of destination like SMB or cloud based storage solution are in study.

## Folder Structure

The program consist of one MODEL folder which is the template for host creation and few script and configuration files :
- `MODEL` : Template folder for host creation
  - `backup.sh` : backup script launched to perform the backup
  - `sauvegarde.conf` : host configuration file for backup
- `add_client.sh` : script to add host to backup
- `maj_centralbackup.sh` : script to update all hosts configuration to match the code of the MODEL. Very usefull if you need to manually add some tweaks into `backup.sh` script for all hosts.
- `centralbackup.conf` : main configuration file of CentralBackup2

## What it does ?

1. Create all needed directory structure for host and backu storage
2. Add all backup information into log files
3. Create a host info file to have basic data on the backuped host like hostname, ip, username...
4. Check remote (SSH) access if the host to backup is remote
5. Detect OS from host to backup
6. Check if all needed package are installed on both CentralBackup2 host and client to backup
7. Check what user is used to launch the backup
8. Backup folder dans directories
9. Backup databases
10. Backup cron tasks
11. Backup list of installed packages
12. Compress the backup into a single archive (.tar.gz) file
13. Display a report of the backup
14. Check if a scheduled task exist for this backup task

Everything is nicely displayed to the user with a cool output (in French) :

## Installation

To install CentralBackup2 on your machine you need to : 

```
git clone https://github.com/ycambourieu/CentralBackup2.git
cd CentralBackup2/
chmod -R +x *.sh
pwd
```

Then edit `centralbackup.conf` to change `LAUNCH_DIR` to fit your environment, use the output of the previous `pwd` command :
```
vim centralbackup.conf
# Configuration du répertoire parent contenant les lanceurs de sauvegardes
	LAUNCH_DIR="/path/to/your/CentralBackup2"
# Save and exit the file
```

## Add a host

To add a host you need to execute the script `add_client.sh`
It will ask to 

```
./add_client.sh
```

Output :
![ ](https://github.com/ycambourieu/CentralBackup2/blob/main/screenshots/add_client.png)

Then you need to go to the host folder to edit `sauvegarde.conf` file and set all the settings.

## Configure a host backup

All backup settings of a host is stored on its `sauvegarde.conf` file. Example for SRV1 :

```
cd /path/to/your/CentralBackup2/SRV1/
vim sauvegarde.conf
```

Here is the list of settings you need to configure :

```
# Information sur l'hote
	NAMEHOST="SRV1"   #=> Name of host in CentralBackup2
# Type de sauvegarde
	REMOTE_MODE="1"    #=> Enable/Disable remote mode backup by using SSH to connect to SRV1, if set to "0", the local machine will be backuped
# Remote options
	REMOTE_LOGIN="root"    #=> SSH login to SRV1
	REMOTE_SSH_PORT="22"   #=> SSH port to SRV1
	REMOTE_HOST="192.168.0.10"    #=> IP adress or network hostname of SRV1
# BDD Backup options
	BDD_LOGIN="mysqluser"    #=> User to connect to the database
	BDD_MDP="******************" #=> Password to connect to the database
# Options de sauvegarde
	ACTIV_FICH="1"    #=> Enable/Disable files and directory backup
	SOURCE_DIR=( etc opt root var/log )   #=> List of directory to backup
	ACTIV_BDD="0"    #=> Enable/Disable databases backup (mariadb and mysql supported for now)
	ACTIV_PKG="1"    #=> Enable/Disable list of installed packages backup (DEB or RPM supported)
	ACTIV_CRONTAB="1"    #=> Enable/Disable cron task backup
# Destination de la sauvegarde
	DEST_DIR="/mnt/backup/$NAMEHOST"     #=> Destination of the backups
# Paramètres de rétention (Activation nettoyage auto et Nombre d'archives à conserver)
	ACTIV_CLEANUP="0"    #=> Enable/Disable auto deletion of old .tar.gz backup archives
	NB_ARCHIV="5"    #=> Number of .tar.gz backup archives to keep
# Répertoire d'enregistrement des logs
	DEST_LOG="/mnt/backup/$NAMEHOST/#Log"    #=> Destination of the logs
```

Save and exit the file, your host is now ready to be backuped !

## Remove a host

To remove a host you just have to remove its folder containing `backup.sh` and `sauvegarde.conf` files from CentralBackup2's folder.

## Launch a backup

To perform a backup of a host you need to go to into the folder of the host and execute its `backup.sh` script :
```
cd /path/to/your/CentralBackup2/SRV1/
./backup.sh
```

![ ](https://github.com/ycambourieu/CentralBackup2/blob/main/screenshots/backup.png)

Note : To backup a remote host, SSH connection based on key and certificate exchange must be in place before you launch the backup. You need to be able to connect to the remote host throush SSH with password (see `ssh-keygen` and `ssh-copy-id` commands to achieve this)

## Schedule a backup

To schedule a backup of a host, you need to add a crontask like this 

```
crontab -e
# Add a task to backup SRV1 host every day at 3 A.M
0 3 * * * /path/to/your/CentralBackup2/SRV1/backup.sh
# Save and exit the file
```

To verify the configuration : 
```
crontab -l
# Output the task :
0 3 * * * /path/to/your/CentralBackup2/SRV1/backup.sh
```

Note : When you launch a backup, the script tell you if the backup task is already scheduled or not.
Tips : You can use a crontab generator to create complex schedules (see https://crontab-generator.org)

## Tweak the backup script and update hosts configuration

If you need to make some changes to the `backup.sh` script to fit your needs, you need to do it into the `CentralBackup2/MODEL/backup.sh` file.

Then run : 
```
./maj_centralbackup.sh
```

It will automatically update all host configuration and set the right permissions on all `backup.sh` file without modifying `sauvegarde.conf` file. Host configuration remains the same.
