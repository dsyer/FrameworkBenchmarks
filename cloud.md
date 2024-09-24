# Test Rig on GCP

## Pre-requisites

You need to:

- get `terraform` and `gcloud` (or `nix-shell` so you can install it)
- authenticate with `gcloud` (`gcloud auth application-default login`) and set up a project if you don't have one
- create an SSH identity file (RSA private key) `~/.ssh/google_compute_engine` if you don't have one

## Create a VM and Log in

Create local environment (if you don't have `terraform` already):

```
$ nix-shell

Terraform v1.9.4
...
```

Create a `terraform.tfvars` and put in your project id and user id. E.g.

```
project = "cf-sandbox-dsyer"
user = "dsyer"
```

Initialize and make sure the configuration is clean (maybe first `rm -rf .terraform* terraform.tfstate*` if you have some old state lying around):

```
$ terraform init
$ terraform validate
```

Create a VM and log in (you will need to replace the GCP project ID):

```
$ terraform apply -auto-approve
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

database_ip = "35.197.235.56"
database_name = "database-4d675238400dcf52"
server_ip = "34.142.59.124"
server_name = "server-4d675238400dcf52"
worker_ip = "34.105.144.151"
worker_name = "worker-4d675238400dcf52"
```

Run the postinstall script to update the IP addresses on the remotes:

```
$ for f in server database worker; do ./scripts/postinstall.sh `terraform output $f'_ip' | sed -e 's/"//g'`; done
```

You can verify with `gcloud` that the instance is running, and then SSH in:

```
$ gcloud compute instances list
NAME                       ZONE            MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
database-4d675238400dcf52  europe-west2-c  c3-standard-8               10.154.0.59  35.197.235.56   RUNNING
server-4d675238400dcf52    europe-west2-c  c3-standard-8               10.154.0.60  34.142.59.124   RUNNING
worker-4d675238400dcf52    europe-west2-c  c3-standard-8               10.154.0.58  34.105.144.151  RUNNING
$ ssh -i ~/.ssh/google_compute_engine $(terraform output server_ip | sed -e 's/"//g')
dsyer@test:~$
```

## Manual Set Up

To be automated...

### Server

```
$ cd FrameworkBenchmarks/frameworks/Java/spring
$ curl -s "https://get.sdkman.io" | bash
$ . ~/.sdkman/bin/sdkman-init.sh
$ sdk install java 23-tem
$ ./mvnw package
$ java -XX:+DisableExplicitGC -XX:+UseStringDeduplication -jar target/hello-spring-1.0-SNAPSHOT.jar
```

### Database

You need to (at a minimum) build the Postgres container and run it. If there is an SSD and you want to use
that you need to format it and mount it too.

```
$ ssh -i ~/.ssh/google_compute_engine $(terraform output database_ip | sed -e 's/"//g')
$ lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
nvme1n1 259:0    0  375G  0 disk
$ sudo mkfs.ext4 -F /dev/nvme1n1
$ sudo mkdir /ssd
$ sudo mount /dev/nvme1n1 /ssd
$ cd FrameworkBenchmarks
$ ./tfb --mode verify --test spring
$ docker run -p 5432:5432 -v /ssd:/ssd techempower/postgres
```

### Worker

Nothing special to set up here.

```
$ for c in 16 32 64 128 256 512; do wrk -d 15s -c $c --timeout 8 -t $(($c>90?90:$c)) -H "Connection: keep-alive" http://tfb-server:8080/fortunes | grep Requests; done
```

## Tear Down

Unfortunately you can't use Terraform to [stop an instance](https://github.com/terraform-providers/terraform-provider-aws/issues/22) so you have to go to `gcloud` to do that:

```
$ gcloud compute instances stop --zone europe-west2-c `terraform output server_name`
Stopping instance(s) server...
```

You can, however, destroy the resource completely:

```
$ terraform destroy -auto-approve
...
Destroy complete! Resources: 3 destroyed.
```

## Nix Config

The instances were initialized with `Nix`. So you can add tools and packages declaratively:

```
dsyer@test$ nix-env -q
nix-2.3.3
user-packages
```

E.g. add the [cowsay CLI](https://en.wikipedia.org/wiki/Cowsay):

```
$ nix-env -i cowsay
$ nix-env -q
cowsay-1.12.3
nix-2.3.3
user-packages
$ cowsay hello
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

The `user-packages` are configured in `.config/nixpkgs/config.nix` and installed when the VM is initialized. You can add your favourite stuff there and update with `nix-env -i user-packages`.
