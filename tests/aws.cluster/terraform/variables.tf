variable "configuration" {
  description = "The total configuration, List of Objects/Dictionary"
  default     = [{}]
}

variable "public_key" {
  description = "Public key to ssh remote servers"
  default     = ""
}