# Lag rocket debian

This repo contains configuration files and preseeds to build custom, minimal debian iso.
To get going, all necessarry instructions are in `setup.sh` script.

# Building the image
To download and unpack debian iso use
```
./setup.sh setup_debian
```

To add preseed and configs use
```
./setup.sh add_files
```

To build the iso use
```
./setup.sh build_image 
```

# Running the image

To run the iso in qemu use
```
./setup.sh run_iso <memory to allocate> <number of processor cores> <disk image>
```
To install the system chose Advanced options then Automated install

If you are using this repo for the first time, you should create disk image that would serve as a virtual hard drive. Recomended image size is 32G

```
qemu-img create <image name> <demanded image size>
```

# Booting installed system

After installation in qemu the system can be booted using the following command:
```
qemu-system-x86_64 -m <memory to allocate> -smp <number of cores> \
    -hda <disk image> -enable-kvm
```

All files that are to be copied to an installed filesystem should be placed in `conf` directory. The syntax of copying files is following:

```
d-i preseed/late_command string cp -r conf/etc/sources.list /target/etc/apt/sources.list
```

This is the sample line that copies apt sources file from the iso to the installed system. If you wish to add any other files to the installed system, the syntax is the same.

After the installation, the default username is `debian` with `12345` as a password (there is `root` with the same password too). This of course can be changed both after the installation or before, in preseed file.
