# AUR-build

Build AUR packages inside a docker container (and upload it to [DataManager](https://github.com/DataManager-Go)).

# Get started
Pull the Image:
```bash
docker pull jojii/buildaur:latest
```

Build an AUR pagkage:
```bash
docker run -it -e REPO='glogg' jojii/buildaur:latest
```

This will compile tha AUR package 'glogg'. You can replace it with any other AUR package

# DataManager
This docker images supports uploading the compiled package to a [DataManagerServer](https://github.com/DataManager-Go/DataManagerServer) (an alternative cloud storage system with support for filesharing). To use it, you have to add some envars to the docker command:
```bash
docker run -it \ 
-e REPO='glogg' \
-e DM_URL ='<DataManagerURL>' \
-e DM_USER='<DataManagerUser>' \
-e DM_TOKEN='<DataManagerToken>' \
jojii/buildaur:latest
```
The `DM_URL` must be set to the URL of the DataManagerServer.<br>
The `DM_USER` var must be set to the username of an existing DataManager User.<br>
The `DM_TOKEN` must be a vaild sessiontoken of the given DM_USER!
