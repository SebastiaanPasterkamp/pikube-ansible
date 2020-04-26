# Raspberry Pi Kubernetes cluster

## Setting up the RPi disks

1. Get the latest Raspbian (Buster) Lite image from the
    Raspberry Pi
    [Download page](https://www.raspberrypi.org/downloads/raspbian/).
2. Unzip the zipped image file in your downloads folder:
    ```bash
    unzip 2020-02-13-raspbian-buster-lite.zip
    ```
3. Check the block device file name assigned to the MicroSD card:
    ```bash
    dmesg | tail -n 5
    ```
4. Write the Raspbian image to the SD card:
    ```bash
    sudo dd \
        bs=1M status=progress \
        if=2020-02-13-raspbian-buster-lite.img \
        of=/dev/mmcblk0
    ```
5. Mount the newly written file systems on the SD using your preferred file
    system browser. Once the file systems are mounted, export the common path
    part to a variable. We'll continue to use this variable in the examples
    below. Of course these commands can be tailored to your particular setup.
    ```bash
    # e.g. for /path/to/boot
    export MOUNT=/path/to
    ```
6. Enable the ssh service on boot, by creating the `ssh` file in the boot
    partition:
    ```bash
    touch $MOUNT/boot/ssh
    ```
7. Enable password-less login to the `pi` user:
    ```bash
    mkdir \
        --mode=700 \
        $MOUNT/rootfs/home/pi/.ssh
    cp \
        ~/.ssh/id_rsa.pub \
        $MOUNT/rootfs/home/pi/.ssh/authorized_keys
    chmod 600 $MOUNT/rootfs/home/pi/.ssh/authorized_keys
    ```
8. Disable the default `pi` password:
    ```bash
    sudo sed -ri \
        's/^pi:[^:]+:/pi::/' \
        $MOUNT/rootfs/etc/shadow
    ```
    Although this step is optional, it is highly recommended. Alternatively you
    can change the default password once you're logged in.
9. Change the default hostname:
    ```bash
    sudo sed -ri \
      's/raspberrypi/pikube-node-01/g' \
      $MOUNT/rootfs/etc/hostname \
      $MOUNT/rootfs/etc/hosts
    ```
