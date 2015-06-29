labs and stuff

all cli

post-install tasks and checks

check the environment

1. After install login to console with user vagrant and password stack.
2. check service health
	cd /home/vagrant/devstack
	source openrc
	nova service-list
	nova list

3. check horizon
	from outside the vm go to http://192.168.33.2 and login with user demo and password stack as well as user admin and password stack

Heat fundamentals

Step 1 - create 3 vas with floating ip, key pair, and apache

2nd exercise - add load balancing to exercise 3

create load balance pool
create lb vip
create floating ip to lb vip

Test lb vip, watch + wget -O- http://vip-ip

3rd exercise - add autoscaling 

generate load

strip out all unnecessary services - swift, trove, cinder, sahara

line 1 - added to feature/1.4
Line 1 - added to rel/2.2
Line 1 - merged rel/2.2 into feature/1.4
