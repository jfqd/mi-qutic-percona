# mi-qutic-percona

This repository is based on [Joyent mibe](https://github.com/joyent/mibe). Please note this repository should be build with the [mi-core-base](https://github.com/skylime/mi-core-base) mibe image.

Most of the scripts are from the [Joyent mi-percona](https://github.com/joyent/mi-percona) image.

## mdata variables

- `mysql_pw`: mysql root password

## services

- `3306/tcp`: mysql server

## installation

The following sample can be used to create a zone running a copy of the the qutic-percona image.

```
IMAGE_UUID=$(imgadm list | grep 'qutic-percona' | tail -1 | awk '{ print $1 }')
vmadm create << EOF
{
  "brand":      "joyent",
  "image_uuid": "$IMAGE_UUID",
  "alias":      "percona56",
  "hostname":   "percona56.example.com",
  "dns_domain": "example.com",
  "resolvers": [
    "80.80.80.80",
    "80.80.81.81"
  ],
  "nics": [
    {
      "interface": "net0",
      "nic_tag":   "admin",
      "ip":        "10.10.10.10",
      "gateway":   "10.10.10.1",
      "netmask":   "255.255.255.0"
    }
  ],
  "max_physical_memory": 1024,
  "max_swap":            1024,
  "quota":                 10,
  "cpu_cap":              100,
  "customer_metadata": {
    "admin_authorized_keys": "your-long-key",
    "root_authorized_keys":  "your-long-key",
    "mail_smarthost":        "mail.example.com",
    "mail_auth_user":        "you@example.com",
    "mail_auth_pass":        "smtp-account-password",
    "mail_adminaddr":        "report@example.com",
    "munin_master_allow":    "munin-master.example.com",
    "vfstab":                "storage.example.com:/export/data    -       /where-ever-you-want    nfs     -       yes     rw,bg,intr",
    "mysql_pw":              "fe07774d219916e6ca29dfdbca331ebb",
    "mysql_server_id":       "1",
    "mysql_qb_pw":           "c418530bee3ccf52f2637e1baac4b72b"
  },
  "delegate_dataset":      true
}
EOF
```

After creating the zone login and run `/opt/local/bin/mysql_secure_installation`!

## Todo

* add configuration for redis slave setup: slaveof <ip> 6379
