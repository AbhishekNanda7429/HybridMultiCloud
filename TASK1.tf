
provider "aws" {
	region = "ap-south-1"
	profile= "abhi"
}


resource "aws_key_pair" "newkey" {
  key_name   = "awskey"
  public_key = 
"sshrsaAAAAB3NzaC1yc2EAAAABJQAAAQEAnzs/mLopS6FfbcSAhJs5xzMnrMuQYIelRG/hk+XSlZWEkA4eXxNEKh/GlLsnB0sjZ4JjxpdV50AK2HsAoxLoF+zYDLS4QTj+Q4TwxkqX76XjI8jLFHztuXvQbMH9mjNMZrzVp8585AthU0//GyZB9fAgSqjRoCfdQB1sUHPhOEEJjcOgHmrZ2WjEvK2HHBRsAPzLFCB4RXlC23u4Rmk7uUe4NSn3Rg0R5o30p2j36kB5T4o4j6c4Cac8ZKamDBmVY8JBnwlZ+KZhOdxduPW5oTGRWo0wxmDPfcFqD76Yh4hfnNCc9ygpxmzPDh9smgnqKQrCn3i6GRLFJPDsFTpbeQ==  rsa-key-20200613"



resource "aws_security_group" "security" {
  name        = "secure"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-01fce169"


  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "serviceSG"
  }
}


resource "aws_instance" "instance1" {
depends_on = [ 
		aws_key_pair.newkey, 
		aws_security_group.security, 
		]
ami ="ami-005956c5f0f757d37"
instance_type = "t2.micro"
key_name = "awskey"
security_groups = ["${aws_security_group.security.name}"]
availability_zone = "ap-south-1a"



resource "aws_ebs_volume" "drive1" {
availability_zone = aws_instance.instance1.availability_zone
size = 1


tags = {
	Name = "drive1"
	}
}


resource "aws_volume_attachment" "dr_att" {
device_name = "/dev/sdd"
volume_id = aws_ebs_volume.drive1.id
instance_id = aws_instance.instance1.id
}



resource "aws_s3_bucket" "invic" {
  bucket = "invic1"
  acl    = "private"


  tags = {
    Name        = "My bucket1"
    Environment = "Dev"
  }
}


locals {
  s3_origin_id = aws_s3_bucket.invic.bucket
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.invic.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.invic.bucket


    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E328EH1BU859J5"
    }
  }


  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = ""




  default_cache_behavior {
    allowed_methods  = [ "GET", "HEAD" ]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.invic.bucket


    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 31536000
  }
price_class = "PriceClass_200"


  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }


  tags = {
    Environment = "production"
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_s3_bucket_policy" "inv" {
  bucket = aws_s3_bucket.invic.bucket
depends_on = [
		aws_s3_bucket.invic,
]


  policy = <<EOF
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E328EH1BU859J5"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::invic1/*"
        }
    ]
}
EOF



resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.invic.bucket
  key    = "family.jpg"
  source = "E:/ABHI/images/family.jpg"
  content_type = "image/jpeg"
  content_disposition = "inline"
}


resource "aws_s3_bucket_public_access_block" "invict" {
depends_on = [
		aws_s3_bucket.invic,
		]
  bucket = aws_s3_bucket.invic.bucket


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "null_resource" "nullresource"  {


    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/KIIT/Downloads/awskey.pem")
    host     = "13.127.100.84"
  }


provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo  service httpd start",
      "sudo mkfs.ext4 /dev/xvdd ",
      
      "sudo mount  /dev/xvdd  /var/www/html",
      "sudo rm -rf /var/www/html",
      "sudo git clone https://github.com/AbhishekNanda7429/mycode.git /var/www/html/"
    ]
  }
}


resource "null_resource" "ncl"  {

depends_on = [
    null_resource.nullresource,
  ]


	provisioner "local-exec" {
	    command = "start chrome  http://13.127.100.84/code.html"
  	}
}
