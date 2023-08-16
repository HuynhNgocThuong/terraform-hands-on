```markdown
# Terraform Programming Concepts

Terraform supports programming in the style of Functional Programming.

## Creating an EC2 Instance

Let's walk through an example of creating an EC2 instance to understand programming concepts in Terraform. Create a file named `main.tf`.

```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "hello" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}
```

Run `terraform init` and `terraform apply`, then on AWS, you will see your EC2 instance. In the above code, our EC2 instance will always have an `instance_type` of `t2.micro`. But what if we want to create an EC2 instance with a different `instance_type`? Should we modify the code in the Terraform file? That's not very flexible. Instead, we'll use variables (referred to as "variables" in programming) to achieve this.

## Declaring Input Variables

We can define variables for Terraform using the following syntax:

```hcl
variable "instance_type" {
  type        = string
  description = "Instance type of the EC2"
}
```

The `type` attribute specifies the data type of the variable, and the `description` attribute is used to provide a description of the variable's meaning. Only the `type` attribute is required. In Terraform, a variable can have the following data types:

- Basic Types: `string`, `number`, `bool`
- Complex Types: `list()`, `set()`, `map()`, `object()`, `tuple()`

In Terraform, the `number` and `bool` data types will be converted to strings when necessary. For example, `"1"` and `"true"` would be used instead of `1` and `true`. We use the syntax `var.<VARIABLE_NAME>` to access the value of a variable and update the `main.tf` file.

```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "hello" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type # change here
}
```

Instead of a hard-coded value for the `instance_type` attribute, we now use the variable `var.instance_type`.

## Assigning Values to Variables

To assign values to variables, we create a file named `terraform.tfvars`.

```hcl
instance_type = "t2.micro"
```

When we run `terraform apply`, Terraform will use the `terraform.tfvars` file to load default values for variables. If we don't want to use the default values, we can provide the `-var-file` attribute when running the `apply` command. For example, create a file named `production.tfvars`.

```hcl
instance_type = "t3.small"
```

When running the CI/CD process for production, we specify the file like this:

```bash
terraform apply -var-file="production.tfvars"
```

Now the `instance_type` value is much more flexible.

## Checking Variable Validity

We can also define that a variable can only be assigned specific values by using the `validation` attribute:

```hcl
variable "instance_type" {
  type        = string
  description = "Instance type of the EC2"

  validation {
    condition     = contains(["t2.micro", "t3.small"], var.instance_type)
    error_message = "Value not allowed."
  }
}
```

In the above file, we use the `contains` function to check if the value of the `instance_type` variable is within the allowed list. If not, when we run the `apply` command, we'll see the error message in the `error_message` field. Update the `terraform.tfvars` file accordingly.

```hcl
instance_type = "t3.micro"
```

Run `terraform apply`.

```bash
terraform apply
```

```
Error: Invalid value for variable

  on variable.tf line 1:
   1: variable "instance_type" {

Value not allowed.

This was checked by the validation rule at variable.tf:5,3-13.
```

Use `validation` to control the values allowed for variables. Update the `terraform.tfvars` file as before. Typically, after creating an EC2 instance, we want to see its IP address. To achieve that, we use the output block.

## Output Values

The values of the output block will be displayed in the terminal. The syntax is as follows:

```hcl
output "ec2" {
  value = {
    public_ip = aws_instance.hello.public_ip
  }
}
```

Run `terraform apply -auto-approve`. You will see the IP value of the EC2 instance printed to the terminal.

```bash
terraform apply -auto-approve
```

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

ec2 = {
  "public_ip" = "52.36.124.230"
}
```

Now we know how to use variables and outputs. Next, what if we want to add another EC2 instance? In the `main.tf` file, we'll simply copy another EC2 resource block.

```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "hello1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}

resource "aws_instance" "hello2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}

output "ec2" {
  value = {
    public_ip1 = aws_instance.hello1.public_ip
    public_ip2 = aws_instance.hello2.public_ip
  }
}
```

We will add another resource block for a second EC2 instance, and in the output section, we will update it to display the IP addresses of both EC2 instances. Everything is straightforward so far, but what if we want to create 100 EC2 instances? We can certainly copy and paste the resource blocks, but nobody wants to do that 😂. Instead, we'll use the `count` attribute.

## The `count` Attribute

The `count`

 attribute is a Meta Argument. It's not a property of a resource type belonging to a provider. In the previous article, we mentioned that a resource type contains the properties provided by the provider. However, Meta Arguments are attributes of Terraform itself. Therefore, we can use them with any resource block. Let's update the `main.tf` file to create 5 EC2 instances.

```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "hello" {
  count         = 5
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}

output "ec2" {
  value = {
    public_ip = [ for v in aws_instance.hello : v.public_ip ]
  }
}
```

Now, when you run `terraform apply`, Terraform will create 5 EC2 instances. Please note that to access the resources in the output section, we use the syntax `<RESOURCE TYPE>.<NAME>[index]`.

Now we have resolved the issue of duplicating resource blocks when we need to create a large number of instances. However, in the output section, we still have to write each resource individually. We will address this using the `for` expression.

## The `for` Expression

The `for` expression allows us to iterate over a list. The syntax for the `for` expression is:

```plaintext
for <value> in <list> : <return value>
```

For example, you can use it to create a new list with uppercase values of an existing list: `[for s in var.words : upper(s)]` or create a new object with uppercase keys and values: `{ for k, v in var.words : k => upper(s) }`. We'll use the `for` expression to simplify the output of the EC2 instances. Let's update the `main.tf` file again.

```hcl
...

resource "aws_instance" "hello" {
  count         = 5
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}

output "ec2" {
  value = { for i, v in aws_instance.hello : format("public_ip%d", i + 1) => v.public_ip }
}
```

Run `terraform plan` to check, and you will see that the output is now in the format `{ public_ip1: <value>, public_ip2: <value> }`.

## Conclusion

Now you have learned about some simple ways to program in Terraform. Use variables to store values, use outputs to display output values, use the `for` expression to iterate over an array. In the next article, we will explore more functions through an example of using Terraform to deploy a website to S3.
```

Feel free to use this `README.md` for your purpose.