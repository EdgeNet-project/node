<p align="center">
  <img src="/assets/edgenet_logo_2020_05_03_w_text_075dpi.png" height="130"><br/><br/>
  <i>The globally distributed edge cloud for Internet researchers.</i>
</p>

## Contribute an EdgeNet node

### From a dedicated machine

If you want to dedicate a physical (e.g. a Raspberry Pi) or a virtual machine to the EdgeNet project,
ensure that the machine has a public IP address and run the following command on the target machine:
```bash
curl https://edge-net.org/bootstrap.sh | bash
```

Supported operating systems: CentOS 8+, Fedora 32+, Ubuntu 18.04+.

### In the cloud

We have pre-built images for the major cloud providers.
Simply run one of the following to deploy a node:
```bash
az vm create ...
aws create-instance ...
gcloud compute instances create ...
```

### Other options

You can run the `node.yml` playbook manually, for example to deploy multiple nodes at once:
```bash
ansible-pull -i node1.example,node2.example -K -U git@github.com:EdgeNet-project/node.git node.yml
```

## Roles

TODO: Describe roles.

TODO: Describe variables

## TODO

Call in bootstrap to EdgeNet ctrl to create the NC object, which creates the DNS entry, and calls back the playbook with the join token.
Add the node name to the shell script.
Pass token for existing users.

- [ ] Packer
- [ ] Asciinema
- [ ] Squash commits
