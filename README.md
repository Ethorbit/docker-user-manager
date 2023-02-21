# docker-user-manager
A docker container that creates users and groups from a YAML config and outputs user files that can be mounted in other containers.

Inside example/ 

We have two docker-compose projects.

## * setup\_users/
This has the sole purpose of creating the users and groups. It will output 4 files to data/users 
* passwd
* group 
* shadow
* env

The env contains the user mappings `username\_u` for uid and `username\_g` for gid, and we pass it other compose projects using --env-file.

## * your\_project
This would just be whatever your project is meant to be, but inside there is a container which runs as the example user and then outputs its user info

## Makefile
Inside the Makefile, we run two docker-compose up's. One is for setting up users and groups and generating the env file, and the other is passing the env file to the *real* project.

You can run `make test` to run the example.

# data/users/settings.yml

settings.yml contains the user and groups desired.

Here is an example of every property possible, they are all optional:
```yaml
groups:
    example:
        id: 2000
        system: false

users:
    example:
        id: 2000
        home: "/home/example"
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

# Pros
Users and groups can be shared with other containers with the names remaining isolated from the host

# Cons
Any changes to users and groups outside the settings will be overrided as soon as the users container starts. To persist changes, you have to edit the settings.yml file and then restart the user container.
