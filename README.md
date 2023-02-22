# ![DockerHub](https://i.imgur.com/tItmtNW.png) [docker-user-manager](https://hub.docker.com/r/ethorbit/user-manager)
A docker container that creates users and groups from a YAML config and outputs user files that can be mounted in other containers.

## Inside example/ 

### setup\_users/
This docker-compose project has the sole purpose of creating the users and groups. It will output 5 files to data/users:
* passwd
* group 
* shadow
* gshadow
* env

The env contains the user mappings `username_u` for uid and `username_g` for gid, and we pass them when running compose commands to use them inside compose files.

### your\_project
This docker-compose project would just be whatever your project is meant to be, but by default there is a container which runs as the example user and then outputs its user info to the terminal.

### data/users/settings.yml

settings.yml contains the user and groups desired.

Here is an example of every property possible, they are all optional:
```yaml
groups:
    example:
        id: 2000
        system: false
        password: "securepassword"
users:
    example:
        id: 2000
        home: "/home/example"
        base:
        shell: "/bin/sh"
        groups:
           - games
           - audio
           - video 
        password: "securepassword"
        system: false
```

Entries are parsed in the same order they are written.
You can also use environment variables, but for them to work, they must also be passed to the users container.

### Makefile
Inside the Makefile, we run two docker-compose up's. One is for setting up users and groups and generating the env file, and the other is passing the env file's variables to the *real* project.

You can run `make test` to run the example.

# Pros
Users and groups can be shared with other containers with the names remaining isolated from the host

# Cons
Any changes to users and groups outside the settings will be overriden as soon as the users container starts. To persist changes, you have to edit the settings.yml file and then restart the user container.
