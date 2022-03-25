echo -e "\n"
echo "Skrypt generujacy pod-klucz S/MIME."
#
# zobacz komentarze w pliku generowanie_smime.bat
#


cn="Adam Nowak"
o="Firma sp. z o.o."
email="anowak@edu.pl"
alias="pracownik_1"


client_waznosc_dni="3650"
dlugosc_klucza="2048"
skrot="sha256"

klient_klucz="klient.pem"
klient_klucz_inf="klient.pem.txt"
klient_cnf="klient.cnf"
klient_csr="klient.csr"
klient_csr_inf="klient.csr.txt"
serial1="sn01.srl"
klient_crt="klient.crt"
klient_crt_inf="klient.crt.txt"
root_klucz="root.pem"
root_crt="root.crt"

klucz_publiczny="klucz_publiczny.p7b"
klucz_publiczny_th2="02user.crt"
fingerprint="fingerprint.txt"
checksum="checksum.sha256"
version="version.txt"
klucz_do_uzytku_wewnetrznego="KLUCZ_PRYWATNY"
klucz_do_uzytku_wewnetrznego_nazwa="TWOJ_KLUCZ.p12"
pass="pass.txt"

OPENSSL_CONF="priv/$klient_cnf"

mkdir $alias
mkdir $alias/priv
mkdir $alias/pub
mkdir $alias/tmp

echo -e "\n"
openssl version
openssl version -a > $alias/priv/$version

echo -e "\n"
echo "....::::  Tworzenie klucza e-mail  ::::...."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:$dlugosc_klucza -out $alias/priv/$klient_klucz
openssl pkey -in $alias/priv/$klient_klucz -text -noout > $alias/priv/$klient_klucz_inf

echo -e "\n"
echo "....::::  Generowanie ustawien dla certyfikatu e-mail  ::::...."
echo [ req ]> $alias/priv/$klient_cnf
echo default_md = $skrot>> $alias/priv/$klient_cnf
echo distinguished_name = client_dn>> $alias/priv/$klient_cnf
echo utf8 = yes>> $alias/priv/$klient_cnf
echo prompt = no>> $alias/priv/$klient_cnf
echo [ client_dn ]>> $alias/priv/$klient_cnf
echo commonName=$cn>> $alias/priv/$klient_cnf
echo organizationName=$o>> $alias/priv/$klient_cnf
echo organizationalUnitName=Wiceprezes>> $alias/priv/$klient_cnf
echo emailAddress=$email>> $alias/priv/$klient_cnf
echo [ smime ]>> $alias/priv/$klient_cnf
echo basicConstraints = critical,CA:FALSE>> $alias/priv/$klient_cnf
echo keyUsage = critical,digitalSignature,keyEncipherment>> $alias/priv/$klient_cnf
echo extendedKeyUsage = clientAuth,emailProtection>> $alias/priv/$klient_cnf
echo subjectKeyIdentifier = hash>> $alias/priv/$klient_cnf
echo authorityKeyIdentifier = keyid:always,issuer:always>> $alias/priv/$klient_cnf
# echo subjectAltName = email:$email>> $alias/priv/$klient_cnf
echo subjectAltName = email:$email, email:szkolenia@edu.pl>> $alias/priv/$klient_cnf

echo -e "\n"
echo "....::::  Generowanie wniosku certyfikacyjnego CSR  ::::...."
openssl req -new -config $alias/priv/$klient_cnf -key $alias/priv/$klient_klucz -out $alias/priv/$klient_csr
openssl req -text -noout -verify -in $alias/priv/$klient_csr > $alias/priv/$klient_csr_inf

echo -e "\n"
echo "....::::  Generowanie s/n  ::::...."
openssl rand -hex 15 > $alias/priv/$serial1

echo -e "\n"
echo "....::::  Podpisanie CSR przez certyfikat Root CA  ::::...."
openssl x509 -req -days $client_waznosc_dni -$skrot -in $alias/priv/$klient_csr -CA priv/$root_crt -CAserial $alias/priv/$serial1 -CAkey priv/$root_klucz -out $alias/priv/$klient_crt -extfile $alias/priv/$klient_cnf -extensions smime
openssl x509 -in $alias/priv/$klient_crt -text -noout > $alias/priv/$klient_crt_inf

echo -e "\n"
echo "....::::  Tworzenie kluczy publicznych w folderze $alias/pub/  ::::...."
openssl crl2pkcs7 -nocrl -certfile $alias/priv/$klient_crt -certfile priv/$root_crt -out $alias/pub/$klucz_publiczny
openssl x509 -in $alias/priv/$klient_crt > $alias/pub/$klucz_publiczny_th2

echo -e "\n"
echo "....::::  Zapis skrotow klucza (odciskow) w $alias/pub/$fingerprint  ::::...."
echo Odcisk klucza "$email" [$cn] :>> $alias/pub/$fingerprint
openssl x509 -noout -fingerprint -sha256 -inform pem -in $alias/priv/$klient_crt>> $alias/pub/$fingerprint
openssl x509 -noout -fingerprint -sha1 -inform pem -in $alias/priv/$klient_crt>> $alias/pub/$fingerprint

cd $alias/pub/
openssl dgst -r -sha256 $klucz_publiczny>$checksum
openssl dgst -r -sha256 $fingerprint>>$checksum
openssl dgst -r -sha256 $klucz_publiczny_th2>>$checksum
cd ../..

mkdir $alias/$klucz_do_uzytku_wewnetrznego

echo -e "\n"
echo "....::::  Tworzenie klucza prywatnego TYLKO dla WLASNEGO UZYTKU  ::::...."
echo "...."
echo ".... plik zostanie zapisany w katalogu $alias/$klucz_do_uzytku_wewnetrznego"
echo ".... pod nazwa $klucz_do_uzytku_wewnetrznego_nazwa"
echo "...."
echo ".... NIE UDOSTEPNIAJ GO NIKOMU !"
echo "...."
echo ".... wygeneruje sie haslo (znajdziesz je w $alias/tmp/$pass)"
echo ".... bedzie potrzebne w programie pocztowym przy imporcie klucza."
echo "...."
echo ".... ZAPISZ JE na kartce albo skorzystaj z menadzera"
echo ".... hasel np. KeePassXC itp."
echo "...."
echo ".... po wygenerowaniu klucza usun ten plik! [Shift+Delete]"
echo "...."
echo ".... -------- $alias/tmp/$pass --------"
echo "...."

openssl pkey -in $alias/priv/$klient_klucz>> $alias/tmp/kombajn
openssl x509 -in $alias/priv/$klient_crt>> $alias/tmp/kombajn
openssl x509 -in priv/$root_crt>> $alias/tmp/kombajn

openssl rand -base64 15 > $alias/tmp/$pass
openssl pkcs12 -export -name "$email" -descert -macalg SHA1 -in $alias/tmp/kombajn -out $alias/$klucz_do_uzytku_wewnetrznego/$klucz_do_uzytku_wewnetrznego_nazwa -passout file:$alias/tmp/$pass

echo "...."
echo "....::::  zrobione!  ::::...."
echo "...."











