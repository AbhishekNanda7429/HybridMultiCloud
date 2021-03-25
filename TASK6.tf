

provider "aws" {

  region                  = "ap-south-1"
  profile                 = "abhi"
}



provider "kubernetes" {

 config_context_cluster = "minikube"

}



resource "aws_db_instance" "mydb" {




  identifier             = "mydb"
  vpc_security_group_ids = ["sg-044c118da11843913"]
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "mydbos"
  username               = "invictus"
  password               = "sukhoi_su_57"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  publicly_accessible    = true
  
  tags = {


	Name = "mydbos"


	}
	
}



resource "null_resource" "minikube"  {


	provisioner "local-exec" {

	    command = "minikube start"

  	}

}

resource "kubernetes_deployment" "WPD" {


  depends_on = [

    null_resource.minikube,

  ]
  
  metadata {  

    name = "wordpress"	

  }


  spec {

    replicas = 3


    selector {

      match_labels = {

        env = "production"
		region = "IN"
		App = "wordpress"

      }
	  
	  match_expressions {

		key = "env"
		operator = "In"
		values = ["production","webserver"]

	  }

    }


    template {

      metadata {

        labels = {

			env = "production"
			region = "IN"
			App = "wordpress"

        }

      }


      spec {

		container {

			image = "wordpress:4.8-apache"
			name  = "wordpress"

		}

	  }

    }

  }

}


resource "kubernetes_service" "NodePort" {
  
  depends_on = [

    kubernetes_deployment.WPD,

  ]
  
  metadata {

	name = "wordpress"

  }
  
  spec {
  
    selector = {

		App = "wordpress"

    }
	
    port {

		protocol = "TCP"
		port = 80
		target_port = 80

    }


    type = "NodePort"

  }

}


resource "null_resource" "service"  {


	depends_on = [

		kubernetes_service.NodePort,
		aws_db_instance.mydb,

	]

	provisioner "local-exec" {

	    command = "minikube service wordpress"

  	}

}



output "RDS_Instance_IP" {

  value = aws_db_instance.mydb.address

}



provider "kubernetes" {


 config_context_cluster = "minikube"


}


provider "aws" {


  region                  = "ap-south-1"
  profile                 = "abhi"


}


resource "null_resource" "minikube"  {




	provisioner "local-exec" {


	    command = "minikube start"


  	}
}


resource "aws_db_instance" "mydb" {




  identifier             = "mydb"
  vpc_security_group_ids = ["sg-044c118da11843913"]
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "mydbos"
  username               = "invictus"
  password               = "sukhoi_su_57"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  publicly_accessible    = true
  
  tags = {


	Name = "mydbos"


	}
	
}


resource "kubernetes_deployment" "WPD" {




  depends_on = [


    null_resource.minikube,


  ]
  
  metadata {  


    name = "wordpress"	


  }



  spec {


    replicas = 3


    selector {


      match_labels = {


        env = "production"
		region = "IN"
		App = "wordpress"


      }
	  
	  match_expressions {


		key = "env"
		operator = "In"
		values = ["production","webserver"]


	  }


    }


    template {


      metadata {


        labels = {


			env = "production"
			region = "IN"
			App = "wordpress"


        }


      }

      spec {


		container {


			image = "wordpress:4.8-apache"
			name  = "wordpress"

		}
	  }
    }
  }
}


resource "kubernetes_service" "NodePort" {
  
  depends_on = [


    kubernetes_deployment.WPD,


  ]
  
  metadata {


	name = "wordpress"


  }
  
  spec {
  
    selector = {


		App = "wordpress"

    }
	
    port {


		protocol = "TCP"
		port = 80
		target_port = 80


    }

    type = "NodePort"


  }
}

resource "null_resource" "service"  {

	depends_on = [


		kubernetes_service.NodePort,
		aws_db_instance.mydb,


	]


	provisioner "local-exec" {


	    command = "minikube service wordpress"


  	}
}


output "RDS_Instance_IP" {


  value = aws_db_instance.mydb.address


}


