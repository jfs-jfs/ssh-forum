# SSH Forum
A ssh forum, nothing more nothing less

![analog](https://github.com/user-attachments/assets/5bae266e-77a3-44e4-bdad-c75d753cd7cc)

## Features
- Anonymous text Forum
- Chat
- Theme personalitzation

## Adding/Removing boards
Easy as adding/removing entries from a bash array.
Open the `entrypoint.sh` (all configuration variables are there) and edit the array `BOARDS`:
```bash
# ...

export BOARDS=(\
  # "Board Name" "Description"\
  "Board 1"     "Dedicated to the cult of the number one"\
  "Board 2"     "Dedicated to the cult of the number two"\
)

# ...
```
For each board you will want to add the board name and a description.

## Modifying the interface
Basic layout configuration can be found on `entrypoint.sh`. There a bunch of constants defined there that control the size of different elements in the user interface.

Another way of drastically changing the interface without rewritting the functionality would be providing a substitute for the `./src/visuals.sh` file. Keep the functions and their arguments and returns but change the display commands for the ones of your liking.

## Theme personalitzation
Users can pick their prefered theme by putting the theme name as the username when connecting.
For example if a user connects using `ssh classic@45.79.250.220` the user interface will be rendered with the theme at `./assets/themes/classic.dialogrc`.

To change the default theme (in case the user doesn't provide a valid theme as username) you can just update the value of the `DIALOGRC` variable in `entrypoint.sh` to the one of your choosing.

## Installation
### Docker
You will need to have installed `git` and `docker`
```bash
git clone git@github.com:jfs-jfs/ssh-forum.git
cd ssh-forum
docker build -t ssh-forum . && docker run -d -p 2222:2222 ssh-forum
```

### Doker with persistance
This way you can keep the contents of the threads even if you kill the container

First you will need to add a `.dockerignore` with this contents:
```text
boards
archive
```

And then run from inside the project folder:
```bash
docker build -t ssh-forum . && docker run -d -p 2222:2222\
    -v "$(pwd)/boards:/usr/src/app/boards:rw"\
    -v "$(pwd)/archive:/usr/src/app/archive:rw"\
    ssh-forum
```

### Manual
You will need to have installed `dialog`, `go` and `git`
```bash
git clone git@github.com:jfs-jfs/ssh-forum.git
cd ssh-forum
go mod tidy && go build -v -o ssh-server server.go
./ssh-server # This will start the server at port 2222
```
