# Terraform config to create alpine package repository

This terraform configuration will create a mirror of the Alpline Linux package repository on a CentOS 7 system.

This is based on a [page from the Alpine Linux wiki](https://wiki.alpinelinux.org/wiki/How_to_setup_a_Alpine_Linux_mirror.)

To use this project, you need [Terraform](https://www.terraform.io/). To install, either [download](https://www.terraform.io/downloads.html) or on macs with [homebrew](https://brew.sh/) run `brew install terraform`.

## Prerequisites
The first thing to determine is how much of the Alpine repository you wish to mirror, and how much disk space that will require. By default, the mirroring script at `provisioning-scripts/rsync-alpine-repo.sh` will mirror EVERYTHING. This requires around 530GB of disk.

Most folks will want a little less; Editing lines around 17 in the script allow excluding unwanted releases. As an example, the following would exclude releases before 3.6:
```
EXCLUDES="v2.* edge v3.0 v3.1 v3.2 v3.3 v3.4 v3.5"
```

To determine how much disk space is needed for a specific set of releases, a `calculate-mirror-size.sh` script is included. As with the `rsync-alpine-repo.sh` script, there is a `desired_releases` variable that can be customized to have the script calulate the required storage space. One thing to note - in this script you specify the releases you *want*, not the ones to *exclude* - so to get everything since v3.6 (as of May 2019), the variable would be set like:
```
desired_releases="v3.6 v3.7 v3.8"
```

One note: `calculate-mirror-size.sh` calculates storage requirements without actually downloading everything. It should run in about a minute.

Also note that you may want to make the volume larger than is needed today, to be able to handle newly added packages, as well as new Alpine releases.

### Using with AWS
This uses Terraform's AWS "provider." Instructions to set up authentication are [here](https://www.terraform.io/docs/providers/aws/index.html), but the two popular places it will look for your AWS credentials in either

* `~/.aws/credentials` - Instructions to set this up are [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
* `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables


## Getting Started
Before running for the first time, the terraform environment will need to be initialized:
```
terraform init
```
Next, to apply the configuration, several variables need to be set (see Variables, below). Once those are figured out, terraform can be run with a command similar to the following:

```
terraform apply -var ssh_keypair_name=my-keypair -var vpc_id=vpc-971323fa -var subnet_id=subnet-166323
```

This will create an EC2 instance with a new security group allowing in ssh and http access from the world, an EBS volume of 150GB for storing mirrored packages.

Upon successful deployment, the system's IP address will be displayed:
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

instance_ip_addr = 54.202.233.242
```

As it is a CentOS system, the default ssh user is **centos**.

Once the mirror is synchronized to the host, it can be accessed via `http://<server-ip>/alpine`

### Actual Mirroring
If left alone, this terraform configuration will set up a cron job that runs daily (via of cron.daily). To get a start on things, you may ssh into the new system and run the sync manually with:
```
sudo /etc/cron.daily/rsync-alpine-repo.sh
```
Note this command will take probably hours to run, depending on configuration. If you network connection is not reliable, you may wish to execute this command inside screen, mux, or similar utility.

## Cleaning up
To remove resources created by this configuration, run terraform similar as to create, but replace `apply` with `destroy`:
```
terraform destroy -var ssh_keypair_name=my-keypair -var vpc_id=vpc-971323fa -var subnet_id=subnet-166323
```

# Variables
By default, the script runs with "reasonable" defaults. The following variables can be used to override defaults:

| Variable name          | Required | Description  | Default Value |
| ---------------------- | -------- | ------------ | ------------- |
| ssh_keypair_name       |    *     | Name of ssh keypair defined in EC2 to allow ssh into system | |
| subnet_id              |    *     | Subnet ID of where to install mirror| |
| vpc_id                 |    *     | VPC ID of where to install mirror | |
| availability_zone      |          | AWS AZ of where to install mirror | us-west-2 |
| http_acl               |          | List of CIDR blocks to allow http traffic from | ["0.0.0.0/0"] |
| region                 |          | AWS Region of where to install mirror | us-west-2a |
| ssh_acl               |          | List of CIDR blocks to allow ssh traffic from | ["0.0.0.0/0"] |
| storage_size           |          | Size of volume to create to store mirrored packages (GB) | 150 |

# TODO
There's several ways this configuration could be improved.  Some that come to mind, are...
* Reboot host after the build to ensure updates are fully applied.
* Adding either an ELB or EIP to provide a consistent address to connect to
* Currently this config is AWS-specific; I'd like to add support for other tf provisioners, but the lack of logic/flow control in Terraform is not thrilling me.
* Allow specifying architecture(s) to mirror (right now mirroring aarch64, armhf, armv7, ppc64le, s390x, x86, x86_64)
