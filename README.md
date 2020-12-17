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
ansible-pull -i node1.example,node2.example -K -U git@github.com:maxmouchet/node.git node.yml
```

## TODO

TODO: Packer
TODO: Handle ZFS-backed VMs?
TODO: Asciinema
TODO: Inside Docker?
TODO: Schema with ansible->packer->vm/cloud/docker/...
