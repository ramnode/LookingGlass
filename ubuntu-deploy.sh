#!/bin/bash

read -p "User to create for the looking glass (lg): " lg_user
[ -z "$lg_user" ] && lg_user=lg # default
host_name=$(hostname -f)
read -p "Host name for the looking glass ($host_name): " lg_host
[ -z "$lg_host" ] && lg_host=$host_name
read -p "Location short-code (us): " lg_loc_short
[ -z "$lg_loc_short" ] && lg_loc_short=us
read -p "Location long name (United States): " lg_loc_long
[ -z "$lg_loc_long" ] && lg_loc_long="United States"
read -p "Would you like to list additional looking glass links in the sidebar? (n): " add_additional_lg
lg_host_description_list="[]"
add_additional_lg=${add_additional_lg,,}
if [[ $add_additional_lg =~ ^(yes|y)$ ]]
then
    read -p "FQDN for additional Looking Glass? (If no more to add, leave blank) (ex: $lg_host): " new_hostname
    lg_host_description_list="["
    while [ -n "$new_hostname" ]
    do
        read -p "Hyperlink text displayed on the sidebar (ex: $lg_loc_long): " hyperlink_text
        lg_host_description_list+="(\"//$new_hostname/\", \"$hyperlink_text\"), "
        read -p "FQDN for additional Looking Glass (If no more to add, leave blank) (ex: $lg_host): " new_hostname
    done
    lg_host_description_list="${lg_host_description_list:0:-2}]"
fi
read -p "Site Name (My Company - $lg_loc_long): " lg_site_name
[ -z "$lg_site_name" ] && lg_site_name="My Company - $lg_loc_long"
best_guess_ipv4=$(ip -4 addr show | awk '/inet/ {print $2}' | tail -1 | cut -d/ -f1)
best_guess_ipv6=$(ip -6 addr show | awk '/inet/ {print $2}' | tail -1 | cut -d/ -f1)
read -p "Test IPv4 address ($best_guess_ipv4): " lg_test_ipv4
[ -z "$lg_test_ipv4" ] && lg_test_ipv4=$best_guess_ipv4
read -p "Test IPv6 address ($best_guess_ipv6): " lg_test_ipv6
[ -z "$lg_test_ipv6" ] && lg_test_ipv6=$best_guess_ipv6
echo "Important!  These test file names must be valid values for the 'seek' parameter of 'dd'!"
read -p "Space delimited test files (100MB 1000MB): " -a lg_test_files
[ -z "$lg_test_files" ] && lg_test_files=(100MB 1000MB)
lg_test_file_string="[\"$(echo -n ${lg_test_files[*]}| sed 's/ /","/g')\"]"

apt-get update && apt-get install python-pip python-dev virtualenvwrapper git nginx uwsgi mtr traceroute bind9-host uwsgi-plugin-python || (echo "Unable to install requirements" && exit 1)

# we force bash to get virtualenvwrapper easily
useradd -m -s/bin/bash $lg_user || (echo "Unable to add user '$lg_user'" && exit 1)

lg_user_home=$(su - $lg_user -c pwd)
lg_venv_path=$lg_user_home/.virtualenvs/LookingGlass
lg_code_path=$lg_user_home/LookingGlass

su - $lg_user -c "git clone https://github.com/ramnode/LookingGlass.git"
su - $lg_user -c "echo 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh' >> .bashrc"
su - $lg_user -c "mkdir $lg_user_home/.virtualenvs"
su - $lg_user -c "virtualenv $lg_venv_path"
su - $lg_user -c "$lg_venv_path/bin/pip install -r $lg_code_path/requirements.txt"

cp $lg_code_path/example_configs/nginx/lg /etc/nginx/sites-available/lg
sed -i -e "s|server_name .*;|server_name $lg_host;|" -e "s|/home/lg|$lg_user_home|g" /etc/nginx/sites-available/lg
ln -s /etc/nginx/sites-available/lg /etc/nginx/sites-enabled/lg
rm -f /etc/nginx/sites-enabled/default

cp $lg_code_path/example_configs/uwsgi/lg.ini /etc/uwsgi/apps-available/lg.ini
sed -i -e "s|id = lg|id = $lg_user|g" -e "s|/home/lg|$lg_user_home|g" -e "s|instance/my.cfg|instance/${lg_loc_short}.cfg|" /etc/uwsgi/apps-available/lg.ini
ln -s /etc/uwsgi/apps-available/lg.ini /etc/uwsgi/apps-enabled/lg.ini

cp -p $lg_code_path/example_configs/uwsgi/wsgi.py $lg_code_path/wsgi.py
sed -i -e "s|/home/lg/.virtualenvs/LookingGlass|$lg_venv_path|" $lg_code_path/wsgi.py
chmod +x $lg_code_path/wsgi.py

cp -p $lg_code_path/instance/default.cfg $lg_code_path/instance/${lg_loc_short}.cfg
sed -i -e "s|SITE_NAME=.*|SITE_NAME=\"$lg_site_name\"|" \
    -e "s|SITE_LOCATION=.*|SITE_LOCATION=\"$lg_loc_long\"|" \
    -e "s|TEST_IPV4=.*|TEST_IPV4=\"$lg_test_ipv4\"|" \
    -e "s|TEST_IPV6=.*|TEST_IPV6=\"$lg_test_ipv6\"|" \
    -e "s|TEST_FILES=.*|TEST_FILES=$lg_test_file_string|" \
    -e "s|ADDITIONAL_LG_LIST=.*|ADDITIONAL_LG_LIST=$lg_host_description_list|" \
    $lg_code_path/instance/${lg_loc_short}.cfg

for test_file in ${lg_test_files[*]}; do
    dd if=/dev/zero of=$lg_code_path/static/${test_file}.test bs=1 count=0 seek=${test_file}
done

service uwsgi restart
service nginx restart
