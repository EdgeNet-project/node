# Users can copy and set their terraform config file as below. 
# Do NOT add SSH key pair in your config file, it will be produced and dealed by bash script automatically.
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
    "no_of_instances" : "1"
  }

]
