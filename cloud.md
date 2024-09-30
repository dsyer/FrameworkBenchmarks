# Test Rig on GCP

## Pre-requisites

You need to:

- get `terraform` and `gcloud` (or `nix-shell` so you can install it)
- authenticate with `gcloud` (`gcloud auth application-default login`) and set up a project if you don't have one
- create an SSH identity file (RSA private key) `~/.ssh/google_compute_engine` if you don't have one

## Create the VMs and Log in

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
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

database_ip = "35.197.235.56"
database_name = "database-4d675238400dcf52"
server_ip = "34.142.59.124"
server_name = "server-4d675238400dcf52"
worker_ip = "34.105.144.151"
worker_name = "worker-4d675238400dcf52"
```

Run the postinstall script to update the IP addresses on the remotes and run some host-specific automations:

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

## Running Benchmarks

Most of the set up is done automatically.

### Server

Postinstall scripts set up the shell and install Java. You can launch the server on the command line. This one for the vanilla Spring server:

```
$ cd ~/FrameworkBenchmarks/frameworks/Java/spring
$ ./mvnw package
$ java -XX:+DisableExplicitGC -XX:+UseStringDeduplication -jar target/hello-spring-1.0-SNAPSHOT.jar
```

or you can open a remote session in VSCode and debug it.

For the webflux sample:

```
$ cd ~/FrameworkBenchmarks/frameworks/Java/spring-webflux
$ ./mvnw package
$ java -XX:+DisableExplicitGC -XX:+UseStringDeduplication -Dio.netty.leakDetection.level=disabled -Dreactor.netty.http.server.lastFlushWhenNoRead=true -jar target/spring-webflux-benchmark.jar  --spring.profiles.active=r2dbc
```

To collect profiling data (while the server is under load) with `async-profiler`:

```
$ ~/profiler/bin/asprof -d 20 -f test.html hello-spring-1.0-SNAPSHOT.jar
```

It will fail the first time and tell you to set 2 flags in the kernel to allow profiling of userspace processes:

```
$ sudo sysctl kernel.perf_event_paranoid=1
$ sudo sysctl kernel.kptr_restrict=0
```

With JFR (Java <=21 only), first find the PID:

```
$ jps
71233 hello-spring-1.0-SNAPSHOT.jar
```

then put the server under load and start and stop the profiler (with a pause in between):

```
$ jcmd 71233 JFR.start exceptions=all
...
$ jcmd 71233 JFR.dump filename=recording.jfr
```

### Database

The postinstall scripts build the Postgres container and run it. If there is an SSD then it is formatted and mounted too. Check everything is set up by looking for the database running in docker:

```
$ ssh -i ~/.ssh/google_compute_engine $(terraform output database_ip | sed -e 's/"//g')
$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS        ...
a583643693c9   techempower/postgres   "docker-entrypoint.s…"   22 seconds ago   Up 21 seconds ...
```

### Worker

Nothing special to set up here. Check the server is running:

```
$ ssh -i ~/.ssh/google_compute_engine $(terraform output worker_ip | sed -e 's/"//g')
$ curl tfb-server:8080/db
```

To collect some benchmark data:

```
$ for c in 16 32 64 128 256 512; do wrk -d 15s -c $c --timeout 8 -t $(($c>$(nproc)?$(nproc):$c)) -H "Connection: keep-alive" http://tfb-server:8080/fortunes | grep Requests; done
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
