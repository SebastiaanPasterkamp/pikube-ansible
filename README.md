# Raspberry Pi Kubernetes cluster

Using references from:
* https://illegalexception.schlichtherle.de/kubernetes/2019/09/12/provisioning-a-kubernetes-cluster-on-raspberry-pi-with-ansible/
* https://itnext.io/building-a-kubernetes-cluster-on-raspberry-pi-and-low-end-equipment-part-1-a768359fbba3
* https://github.com/chrismeyersfsu/role-iptables

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
    Use either `pikube-master` for the first Kubernetes node, which will become
    the controller, or `pikube-node-01` and up for each new worker node added to
    the cluster.

## Provisioning with Ansible

We'll be using ansible to provision the Raspberry Pi machines once they're
running.

### Set up the Ansible environment

```bash
python3 -m venv .pikube
. .pikube/bin/activate
pip install -r requirements.txt
```

### Test ansible with docker

Run the tests on docker containers.

```bash
make test
```

This will:
1. Run `make lint` to `yamllint` the `ansible` directory.
2. Run `make launch`, which will:
    1. Run `make build` the mock Raspberry Pi docker images.
    2. Then launch the containers defined in the `inventory/docker-test.yaml`
        inventory file.
3. Run `make deploy` with the `docker-test.yaml` playbook and the previously
    mentioned inventory file.
4. Run `make shutdown` to bring down the docker containers once we're finished.

### Prepare the ansible playbook

#### Define the target Pi's

Update the `ansible/inventory/raspberry-pi.yaml` and configure the target
hosts by name, and IP address. Ony use IP addresses, so they can be re-used
in the `/etc/hosts` files on the target machines. Do not use DNS names.

#### Configure external storage

Optionally define a known external storage device by `uuid` in the `mounts`
part. The mount path for the external storage may be used as docker data-root if
configured so below. You can find the UUID's while preparing the raspberry pi
image using the following command:

```bash
lsblk -pf
```

### Apply the ansible playbook to live Raspberry Pi nodes

Once all Pi's are running you can deploy the Kubernetes cluster using the
following command:

```bash
make deploy \
    VERBOSITY="-vv" \
    PLAYBOOK="raspberry-pi.yaml" \
    INVENTORY="inventory/raspberry-pi.yaml"
```
