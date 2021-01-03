#!/bin/bash

domain=$1
wordlist=" /root/Downloads/seclist/SecLists/Discovery/DNS/dns-Jhaddix.txt"
resolvers="/root/Downloads/resolvers.txt"

domain_enum(){

mkdir -p $domain $domain/sources $domain/Recon $domain/Recon/nuclei $domain/Recon/wayback $domain/Recon/gf

subfinder -d $domain -o $domain/sources/subfinder.txt
assetfinder -subs-only $domain | tee $domain/sources/assetfinder.txt
amass enum -passive -d $domain -o $domain/sources/passive.txt
shuffledns -d $domain -w $wordlist -r $reslovers -o $domain/sources/shuffledns.txt 
crtsh $domain | tee $domain/sources/crtsh.txt

cat $domain/sources/*.txt > $domain/sources/all.txt
}
domain_enum

resolving_domain(){
shuffledns -d $domain -list $domain/sources/all.txt  -r $resolvers -o $domain/domains.txt
}
resolving_domain

http_prob(){
httpx -l $domain/domains.txt -title -content-length -status-code  -o $domain/Recon/httpx.txt
}
http_prob

nuclei(){
cat  $domain/Recon/httpx.txt | nuclei -t /root/nuclei-templates/ -c 50 -o  $domain/Recon/nuclei/nuclei_domain.txt 
}
nuclei

wayback_data(){
cat $domain/domains.txt | waybackurls | tee $domain/Recon/wayback/way.txt
cat $domain/Recon/wayback/way.txt | egrep -v "\.woff|\.ttf|/.svg|\.eot|\.png|\.jpep|\.jpg|\.svg|\.css|/.ico" | sed 's/:80//g:s/:443//g' | sout -u >> $domain/Recon/wayback/wayback.txt
rm $domain/Recon/wayback/way.txt

} 
wayback_data

ffuf(){

ffuf -c -u "FFUF" -w $domain/Recon/wayback/wayback.txt -of csv -o $domain/Recon/wayback/valid-tmp.txt
cat $domain/Recon/wayback/valid-tmp.txt | grep http | awk -F "," '{print $1}' >>$domain/Recon/wayback/valid.txt
rm $domain/Recon/wayback/valid-tmp.txt
}
ffuf

gf_patterns(){
gf xss $domain/Recon/wayback/valid.txt | tee $domain/Recon/gf/xss.txt
gf idor $domain/Recon/wayback/valid.txt | tee $domain/Recon/gf/idor.txt
}
gf_patternss
