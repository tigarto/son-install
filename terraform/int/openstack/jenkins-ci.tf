#
variable "jk_node_count" {
  default = 1
}

resource "openstack_compute_floatingip_v2" "jkfip" {
    region = ""
    pool = "${var.floatipnet}"
    count = "${var.jk_node_count}"
}
 
resource "openstack_compute_instance_v2" "jenkins" {
  count = "${var.jk_node_count}"
  region = ""
  name = "os-${var.vm_name}${format("%02d",count.index)}"
  image_name = "${var.img_name}"
  flavor_name = "${var.flv_name}"
  key_pair = "${var.key_pair}"
  security_groups = ["${var.sec_grp}"]
  #metadata {
  #    demo = "metadata"
  #}
  network {
      uuid = "${var.internal_network_id}"
      name = "${var.internal_network_name}"
      #fixed_ip = ""
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.jkfip.*.address, count.index)}"
  user_data = "${file("bootstrap-${distro}.sh")}"
}

resource "template_file" "jk_host_ipaddr" {
  count = "${var.jk_node_count}"
#  location = "${var.placement}"
  template = "${file("hostname.tpl")}"
  vars {
    index = "${count.index + 1}"
    name  = "sp"
    env   = "int"
    extra = " ansible_host=${element(openstack_compute_floatingip_v2.jkfip.*.address, count.index)}"
  }
}

resource "template_file" "jk_inventory" {
  #count = "${var.jk_node_count}"
  template = "${file("inventory.tpl")}"
  vars {
    env       = "int"
    jenkins_hosts  = "${join("\n",template_file.host_ipaddr.*.rendered)}"
  }
}

