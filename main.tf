// Generate Private and Public Key and upload to aws
 resource "tls_private_key" "terrafrom_generated_private_key" {
   algorithm = "RSA"
   rsa_bits  = 4096
 }
 
 resource "aws_key_pair" "generated_key" {
 
   # Name of key: Write the custom name of your key
   key_name   = "aws_keys_pairs"
 
   # Public Key: The public will be generated using the reference of tls_private_key.terrafrom_generated_private_key
   public_key = tls_private_key.terrafrom_generated_private_key.public_key_openssh
 
   # Store private key :  Generate and save private key(aws_keys_pairs.pem) in current directory
   provisioner "local-exec" {
     command = <<-EOT
       echo '${tls_private_key.terrafrom_generated_private_key.private_key_pem}' > aws_keys_pairs.pem
       chmod 400 aws_keys_pairs.pem
     EOT
   }
 }

// Launch aws instance using ami-007cf291af489ad4d then connect to it using ssh and install podman
resource "aws_instance" "rcook" {
  ami           = "ami-0ac94c9bfed423e5e"
  instance_type = "t4g.medium"
  key_name      = aws_key_pair.generated_key.key_name
  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "echo 'Connection Established'",
      "systemctl start podman.socket --user",
      "sudo loginctl enable-linger ec2-user",
    ]
  }
 connection {
   type = "ssh"
   user = "ec2-user"
   private_key = tls_private_key.terrafrom_generated_private_key.private_key_pem
   host = self.public_ip
 }
}


// Output public ip address
output "public_ip" {
  value = aws_instance.rcook.public_ip
}
