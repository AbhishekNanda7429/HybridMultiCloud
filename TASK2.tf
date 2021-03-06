


provider "aws" {
  region                  = "ap-south-1"
  profile                 = "abhi"
}



resource "aws_key_pair" "newkey" {
  key_name   = "awskey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAnzs/mLopS6FfbcSAhJs5xzMnrMuQYIelRG/hk+XSlZWEkA4eXxNEKh/GlLsnB0sjZ4JjxpdV50AK2HsAoxLoF+zYDLS4QTj+Q4TwxkqX76XjI8jLFHztuXvQbMH9mjNMZrzVp8585AthU0//GyZB9fAgSqjRoCfdQB1sUHPhOEEJjcOgHmrZ2WjEvK2HHBRsAPzLFCB4RXlC23u4Rmk7uUe4NSn3Rg0R5o30p2j36kB5T4o4j6c4Cac8ZKamDBmVY8JBnwlZ+KZhOdxduPW5oTGRWo0wxmDPfcFqD76Yh4hfnNCc9ygpxmzPDh9smgnqKQrCn3i6GRLFJPDsFTpbeQ== rsa-key-20200613"
}


resource "aws_security_group" "sc6" {
  name        = "sc6"
  description = "created using terraform"
  vpc_id      = "vpc-01fce169"


  ingress {
    description = "ssh inbound rule using terraform"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }


  ingress {
    description = "http inbound rule using terraform"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }


  ingress {
    description = "custom tcp inbound rule using terraform"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }
  
  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "sc6"
  }
}



resource "aws_instance"  "i2" {


   depends_on = [
    aws_efs_mount_target.mt3,
	aws_cloudfront_distribution.sbc,
  ]
  
  ami           = "ami-005956c5f0f757d37"
  instance_type = "t2.micro"
  key_name	= "awskey"
  security_groups =  [ "sc6" ] 
  availability_zone = "ap-south-1a"
  
  user_data = <<-EOF
		 #!/bin/bash
		 sudo yum install -y amazon-efs-utils
		 sudo yum install -y nfs-utils
		 file_system_id_1="${aws_efs_file_system.efs1.id}"
         mkdir /var/www
		 mkdir /var/www/html
         mount -t efs $file_system_id_1:/ /var/www/html
		 echo $file_system_id_1:/ /var/www/html efs defaults,_netdev 0 0 >> /etc/fstab
	EOF
	
  tags = {
    Name = "Terraos_2"
  }
}



resource "aws_efs_file_system" "efs1" {


  depends_on = [
    aws_security_group.sc6,
  ]
  
  creation_token = "TEFS_1"


  tags = {
    Name = "TEFS_1"
  }
}



resource "aws_efs_mount_target" "mt1" {
 
  depends_on = [
    aws_efs_file_system.efs1,
  ]
  file_system_id = aws_efs_file_system.efs1.id
  subnet_id      = "subnet-1f17a564"
  security_groups = [aws_security_group.sc6.id]
}

resource "aws_efs_mount_target" "mt2" {

  depends_on = [
    aws_efs_mount_target.mt1,
  ]
  file_system_id = aws_efs_file_system.efs1.id
  subnet_id      = "subnet-530c363b"
  security_groups = [aws_security_group.sc6.id]  
}

resource "aws_efs_mount_target" "mt3" {


  depends_on = [
    aws_efs_mount_target.mt2,
  ]
  file_system_id = aws_efs_file_system.efs1.id
  subnet_id      = "subnet-6f1b7023"
  security_groups = [aws_security_group.sc6.id]
}



resource "aws_s3_bucket" "sb4" {
  bucket = "invic7429"
  acl    = "private"


  tags = {
    Name        = "Terra-bucket"
    Environment = "Dev"
  }
}



locals {
  s3_origin_id = aws_s3_bucket.sb4.bucket
}


resource "aws_cloudfront_distribution" "sbc" {
	
	 depends_on = [
   aws_s3_bucket_object.sbo,
  ]
  
  origin {
    domain_name = "${aws_s3_bucket.sb4.bucket}.s3.amazonaws.com"
    origin_id   = aws_s3_bucket.sb4.bucket


    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E1LFGP4FJ1JXZD"
    }
  }


  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = ""
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.sb4.bucket


    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }


  price_class = "PriceClass_All"


  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }


  tags = {
    Environment = "TerraCloud"
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
}



resource "aws_s3_bucket_policy" "sbp" {


  depends_on = [
   aws_s3_bucket_public_access_block.sbb,
  ]
  
  bucket = aws_s3_bucket.sb4.id
  policy = <<EOF
{
  "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1LFGP4FJ1JXZD"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.sb4.bucket}/*"
        }
    ]
}
EOF



resource "aws_s3_bucket_object" "sbo" {


  depends_on = [
   aws_s3_bucket_policy.sbp,
  ]
  
  bucket = aws_s3_bucket.sb4.id
  key    = "family.jpg"
  source = "E:/ABHI/images/family.jpg"
  content_type = "image/jpeg"
  content_disposition = "inline"
}


resource "aws_s3_bucket_public_access_block" "sbb" {


   depends_on = [
    aws_s3_bucket.sb4,
  ]
  
  bucket = aws_s3_bucket.sb4.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}



resource "null_resource" "nullresource"  {


 depends_on = [
   aws_instance.i2,
  ]


    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/KIIT/Desktop/tera/awskey.pem")
    host     = aws_instance.i2.public_ip
  }


provisioner "remote-exec" {


    inline = [
      "sudo yum install httpd  php git -y",
	  "sudo service httpd start",
	  "sudo service httpd enabled",
      "sudo rm -rf /var/www/html",
      "sudo git clone https://github.com/AbhishekNanda7429/mycode.git /var/www/html",
	  "sudo sed -i 's/old_domain/${aws_cloudfront_distribution.sbc.domain_name}/g' /var/www/html/code.html" 
    ]
  }
}



resource "null_resource" "ncl"  {




depends_on = [
    null_resource.nullresource,
  ]


	provisioner "local-exec" {
	    command = "chrome  http://${aws_instance.i2.public_ip}/code.html"
  	}
}

