#!/usr/bin/bash

si_imgs='luskan fenwick raven baldur ratik'
core_imgs='reg'

si_repo_lookup_url='https://images.opencadc.org/api/v2.0/projects/storage-inventory/repositories/'
core_repo_lookup_url='https://images.opencadc.org/api/v2.0/projects/core/repositories/'
si_repo_download_url='images.opencadc.org/storage-inventory'
core_repo_download_url='images.opencadc.org/core'

latest_versions=''
for img in ${core_imgs};do 
    version=`curl -s ${core_repo_lookup_url}/${img}/artifacts | jq '[.[].tags | select (. != null) | .[].name] | sort' | \
	grep -v "-" | grep -v ] | tail -1 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
    echo "Downloaded ${img}:${version}"
    latest_versions=${latest_versions}"${img}:${version}\n"
    sudo docker pull ${core_repo_download_url}/${img}:${version}
done

for img in ${si_imgs};do 
    version=`curl -s ${si_repo_lookup_url}/${img}/artifacts | jq '[.[].tags | select (. != null) | .[].name] | sort' | \
	grep -v "-" | grep -v ] | tail -1 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
    echo "Downloaded ${img}:${version}"
    latest_versions=${latest_versions}"${img}:${version}\n"
    sudo docker pull ${si_repo_download_url}/${img}:${version}
done

echo "Latest versions:"
echo -e "${latest_versions}"
