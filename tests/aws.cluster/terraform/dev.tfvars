configuration = [
  {
    "application_name" : "kube-master",
    "ami" : "ami-0c4f7023847b90238",
    "instance_type" : "t2.micro",
    "no_of_instances" : "1"
  },
  {
    "application_name" : "kube-worker",
    "ami" : "ami-0c4f7023847b90238",
    "instance_type" : "t2.micro",
    "no_of_instances" : "2"
  }

]

public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNahbqOefbHs2ryllhaYFbBOdYWrIdF/6MvIFJQImrE15G74sPIFum5mcMGFJCSFlQ74qJ/tmRYSy7uqYXFfNxK/Mz59RVqbhsWlKfSDymhvH+9XPjLh3Ci1toEZWx+BmTLLpERXCvdi/h64JaThAsTv1UM/HJBaB6zHkJxzFJlhqWnBjnG0+yBuynILhDYTQnVMDlzIKZ6Lznjd2VLBLZCz+jcxyzuIyVfTElLAzUWzsFI8Nkkud5/W9pvdAmx4DjDKXmGXZI6YgI0w"