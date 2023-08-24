data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = data.aws_ami.ami.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [var.sg.web]

  user_data = filebase64("${path.module}/run.sh")

  iam_instance_profile {
    name = module.iam_instance_profile.name
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project}-asg"
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }
}
