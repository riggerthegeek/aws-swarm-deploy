############################
############################
###                      ###
###   Output Variables   ###
###                      ###
############################
############################
output "manager_ips" {
  value = [
    "${aws_instance.docker_manager_instance.*.public_ip}"
  ]
}

output "worker_ips" {
  value = [
    "${aws_instance.docker_worker_instance.*.public_ip}"
  ]
}
