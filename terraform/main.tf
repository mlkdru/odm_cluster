rovider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_spot_instance_request" "web" {
  availability_zone = "${var.availability_zone}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  user_data = "${file("user-data.txt")}"

  spot_price = "${var.spot_price}"
  wait_for_fulfillment = true
  spot_type = "one-time"

  root_block_device {
    volume_size = "${var.root_ebs_size}"
  }

  connection {
    user = "ubuntu"
    private_key = "${file("/Users/alen/.ssh/id_rsa")}"
    host = "${aws_spot_instance_request.web.public_ip}"
  }

  // Tag will not be added. Below script will copy tags from spot request to the instance using AWS CLI.
  // https://github.com/terraform-providers/terraform-provider-aws/issues/32
  tags {
    Name = "web"
    Env = "dev"
    InstanceType = "spot"
  }

  provisioner "file" {
    source = "set_tags.sh"
    destination = "/home/ubuntu/set_tags.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/set_tags.sh ${var.access_key} ${var.secret_key} ${var.region} ${aws_spot_instance_request.web.id} ${aws_spot_instance_request.web.spot_instance_id}"
    ]
  }
}