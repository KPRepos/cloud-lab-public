##Empty
output "k8_api_lb_dns" {

  # value       = var.enable_k8_api_public ? aws_elb.k8_api_lb[0].dns_name : ""
  value       = aws_elb.k8_api_lb.dns_name
  description = "The DNS name of the Kubernetes API Load Balancer"
}

