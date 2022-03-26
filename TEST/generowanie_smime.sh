echo -e "\n"
echo "v5 26/03/2022"
echo -e "\n"
echo "Skrypt generujacy klucz S/MIME."
echo "Szyfrowanie i podpisywanie e-maili."
#
# [Certyfikat niekwalifikowany]
#
# skrypt pod Linux 5.13.0 i wyżej [Ubuntu 21.10]
# wykorzystuje program openssl - testowano na wersji OpenSSL 1.1.1l
# do sprawdzenia poprawności użyto guiDumpASN-ng, xca.exe 2.4.0
# ustawienia podobne do klucza "Free S/MIME Certificates" od firmy Actalis S.p.A.
# https://www.actalis.it/documenti-it/caact-free-s-mime-certificates-policy.aspx  [strony 11-12]
#
# program wykonuje się w katalogu w którym znajduje się .sh
#
#         Schemat klucza:
#           1. klucz Root CA (certyfikat dla klucza e-mail)
#              2. klucz e-mail (podpisywanie+szyfrowanie)
#
# skrypt oparty na wersji pod Windows
# https://github.com/HPeTBD/smime
# zobacz komentarze w pliku generowanie_smime.bat
#
# jeśli nie możesz uruchomić skryptu, zmień prawa dostępu do pliku :
# chmod +x generowanie_smime.sh
# następnie wykonaj :
# ./generowanie_smime.sh
#
# najlepiej tworzyć klucz w ram-dysku (bezpieczeństwo, nie trzeba robić shred), skopiować foldery priv/ i z kluczem .p12 na pendriva; folder pub/ udostępnić
# RAM dysk - aktywuj na partycji "/mnt/ramdisk" :
#    mkdir /mnt/ramdisk
#    mount -t tmpfs -o size=256m tmpfs /mnt/ramdisk
#    df -h
# RAM dysk - odłącz :
#    sudo reboot now


o="Firma sp. z o.o."
email="jkowalski@edu.pl"
client_waznosc_dni="3650"










dlugosc_klucza="2048"
dlugosc_klucza_root="2048"
skrot="sha256"
cn="Firma sp. z o.o. CA e-mail"
root_waznosc_dni="$(expr $client_waznosc_dni + 1 |bc)"

root_klucz="root.pem"
root_crt="root.crt"
root_klucz_inf="root.pem.txt"
root_crt_inf="root.crt.txt"
root_cnf="root.cnf"

klient_klucz="klient.pem"
klient_klucz_inf="klient.pem.txt"
klient_cnf="klient.cnf"
klient_csr="klient.csr"
klient_csr_inf="klient.csr.txt"
klient_crt="klient.crt"
klient_crt_inf="klient.crt.txt"
serial1="sn01.srl"

klucz_publiczny="klucz_publiczny.p7b"
klucz_publiczny_th1="01root.crt"
klucz_publiczny_th2="02user.crt"
fingerprint="fingerprint.txt"
checksum="checksum.sha256"
pass="pass.txt"
version="version.txt"
klucz_do_uzytku_wewnetrznego="KLUCZ_PRYWATNY"
klucz_do_uzytku_wewnetrznego_nazwa="TWOJ_KLUCZ.p12"

OPENSSL_CONF="priv/$klient_cnf"

echo -e "\n"
openssl version

mkdir priv
mkdir pub
mkdir tmp

openssl version -a > priv/$version

echo -e "\n"
echo "....::::  Tworzenie klucza ROOT  ::::...."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:$dlugosc_klucza_root -out priv/$root_klucz
openssl pkey -in priv/$root_klucz -text -noout > priv/$root_klucz_inf

echo -e "\n"
echo "....::::  Generowanie ustawien dla Root CA  ::::...."
echo [ req ]> priv/$root_cnf
echo default_md = $skrot>> priv/$root_cnf
echo distinguished_name = root_dn>> priv/$root_cnf
echo x509_extensions = root_ext>> priv/$root_cnf
echo req_extensions = root_ext>> priv/$root_cnf
echo utf8 = yes>> priv/$root_cnf
echo prompt = no>> priv/$root_cnf
echo [ root_dn ]>> priv/$root_cnf
echo commonName=$cn>> priv/$root_cnf
echo organizationName=$o>> priv/$root_cnf
echo countryName=PL>> priv/$root_cnf
echo stateOrProvinceName=Mazowieckie>> priv/$root_cnf
echo localityName=Warszawa>> priv/$root_cnf
echo [ root_ext ]>> priv/$root_cnf
echo basicConstraints = critical,CA:TRUE,pathlen:0>> priv/$root_cnf
echo keyUsage = critical,keyCertSign,cRLSign>> priv/$root_cnf
echo extendedKeyUsage = clientAuth,emailProtection>> priv/$root_cnf
echo subjectKeyIdentifier = hash>> priv/$root_cnf
echo authorityKeyIdentifier = keyid>> priv/$root_cnf

echo -e "\n"
echo "....::::  Generowanie certyfikatu Root CA i samopodpis  ::::...."
openssl req -new -x509 -config priv/$root_cnf -days $root_waznosc_dni -key priv/$root_klucz -out priv/$root_crt
openssl x509 -in priv/$root_crt -text -noout > priv/$root_crt_inf

echo -e "\n"
echo "....::::  Tworzenie klucza e-mail  ::::...."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:$dlugosc_klucza -out priv/$klient_klucz
openssl pkey -in priv/$klient_klucz -text -noout > priv/$klient_klucz_inf

echo -e "\n"
echo "....::::  Generowanie ustawien dla certyfikatu e-mail  ::::...."
echo [ req ]> priv/$klient_cnf
echo default_md = $skrot>> priv/$klient_cnf
echo distinguished_name = client_dn>> priv/$klient_cnf
echo utf8 = yes>> priv/$klient_cnf
echo prompt = no>> priv/$klient_cnf
echo [ client_dn ]>> priv/$klient_cnf
echo commonName=Jan Kowalski>> priv/$klient_cnf
echo organizationName=$o>> priv/$klient_cnf
echo organizationalUnitName=Prezes>> priv/$klient_cnf
echo emailAddress=$email>> priv/$klient_cnf
echo [ smime ]>> priv/$klient_cnf
echo basicConstraints = critical,CA:FALSE>> priv/$klient_cnf
echo keyUsage = critical,digitalSignature,keyEncipherment>> priv/$klient_cnf
echo extendedKeyUsage = clientAuth,emailProtection>> priv/$klient_cnf
echo subjectKeyIdentifier = hash>> priv/$klient_cnf
echo authorityKeyIdentifier = keyid:always,issuer:always>> priv/$klient_cnf
echo subjectAltName = @alt_section>> priv/$klient_cnf
echo [alt_section]>> priv/$klient_cnf
echo email.1=$email>> priv/$klient_cnf
# echo email.2=b@edu.pl>> priv/$klient_cnf
# echo email.3=c@edu.pl>> priv/$klient_cnf

echo -e "\n"
echo "....::::  Generowanie wniosku certyfikacyjnego CSR  ::::...."
openssl req -new -config priv/$klient_cnf -key priv/$klient_klucz -out priv/$klient_csr
openssl req -text -noout -verify -in priv/$klient_csr > priv/$klient_csr_inf

echo -e "\n"
echo "....::::  Generowanie s/n  ::::...."
openssl rand -hex 15 > priv/$serial1

echo -e "\n"
echo "....::::  Podpisanie CSR przez certyfikat Root CA  ::::...."
openssl x509 -req -days $client_waznosc_dni -$skrot -in priv/$klient_csr -CA priv/$root_crt -CAserial priv/$serial1 -CAkey priv/$root_klucz -out priv/$klient_crt -extfile priv/$klient_cnf -extensions smime
openssl x509 -in priv/$klient_crt -text -noout > priv/$klient_crt_inf

echo -e "\n"
echo "....::::  Tworzenie kluczy publicznych w folderze pub/  ::::...."
openssl crl2pkcs7 -nocrl -certfile priv/$klient_crt -certfile priv/$root_crt -out pub/$klucz_publiczny
openssl x509 -in priv/$root_crt > pub/$klucz_publiczny_th1
openssl x509 -in priv/$klient_crt > pub/$klucz_publiczny_th2

echo -e "\n"
echo "....::::  Zapis skrotow klucza (odciskow) w pub/$fingerprint"  ::::....
echo Odcisk klucza "$cn" [główny] :> pub/$fingerprint
openssl x509 -noout -fingerprint -sha256 -inform pem -in priv/$root_crt>> pub/$fingerprint
openssl x509 -noout -fingerprint -sha1 -inform pem -in priv/$root_crt>> pub/$fingerprint
echo "">> pub/$fingerprint
echo Odcisk klucza "$email" [podrzędny] :>> pub/$fingerprint
openssl x509 -noout -fingerprint -sha256 -inform pem -in priv/$klient_crt>> pub/$fingerprint
openssl x509 -noout -fingerprint -sha1 -inform pem -in priv/$klient_crt>> pub/$fingerprint

cd pub
openssl dgst -r -sha256 $klucz_publiczny>$checksum
openssl dgst -r -sha256 $fingerprint>>$checksum
openssl dgst -r -sha256 $klucz_publiczny_th1>>$checksum
openssl dgst -r -sha256 $klucz_publiczny_th2>>$checksum
cd ..

mkdir $klucz_do_uzytku_wewnetrznego

echo -e "\n"
echo "....::::  Tworzenie klucza prywatnego TYLKO dla WLASNEGO UZYTKU  ::::...."
echo "...."
echo ".... plik zostanie zapisany w katalogu $klucz_do_uzytku_wewnetrznego"
echo ".... pod nazwa $klucz_do_uzytku_wewnetrznego_nazwa"
echo "...."
echo ".... NIE UDOSTEPNIAJ GO NIKOMU !"
echo "...."
echo ".... wygeneruje sie haslo (znajdziesz je w tmp/$pass)"
echo ".... bedzie potrzebne w programie pocztowym przy imporcie klucza."
echo "...."
echo ".... ZAPISZ JE na kartce albo skorzystaj z menadzera"
echo ".... hasel np. KeePassXC itp."
echo "...."
echo ".... po wygenerowaniu klucza usun ten plik! [Shift+Delete]"
echo "...."
echo ".... -------- tmp/$pass --------"
echo "...."

openssl pkey -in priv/$klient_klucz>> tmp/kombajn
openssl x509 -in priv/$klient_crt>> tmp/kombajn
openssl x509 -in priv/$root_crt>> tmp/kombajn

openssl rand -base64 15 > tmp/$pass
openssl pkcs12 -export -name "$email" -descert -macalg SHA1 -in tmp/kombajn -out $klucz_do_uzytku_wewnetrznego/$klucz_do_uzytku_wewnetrznego_nazwa -passout file:tmp/$pass
echo -e "\n"
openssl pkcs12 -info -nokeys -noout -in $klucz_do_uzytku_wewnetrznego/$klucz_do_uzytku_wewnetrznego_nazwa -passin file:tmp/$pass
echo -e "\n"

echo "...."
echo "....::::  zrobione!  ::::...."
echo "...."
echo "...."
echo "....::::  Ustawienia  ::::...."
echo "...."
echo ".... domyslne ustawienia:"
echo ".... RSA2048/sha256, waznosc klucza: 10 lat"
echo "...."
echo ".... ustawienia UZYTKOWNIKA:"
echo ".... RSA$dlugosc_klucza/$skrot, waznosc klucza: $client_waznosc_dni dni"
echo "...."
echo ".... $email"
echo ".... $o"
echo ".... $cn"
echo "...."
echo "...."
echo "....::::  Informacja  ::::...."
echo "...."
echo "...."
echo "...."
echo "....      $klucz_do_uzytku_wewnetrznego_nazwa"
echo "....      Klucz .p12 -- import w twoich programach pocztowych"
echo "...."
echo ".... import .p12 dziala bezproblemowo w Windows, sprawdzono z Win7, Win10"
echo ".... start -- uruchom -- Certmgr.msc"
echo ".... W Kreatorze importu certyfikatow, w Opcjach importu zaznacz:"
echo ".... * Oznacz ten klucz jako eksportowalny. Pozwoli to..."
echo "...."
echo ".... W Outlook 2007:"
echo ".... Centrum zaufania -- Importuj, plik importu [.p12]. Dodatkowo zaznacz:"
echo ".... * Szyfruj tresc i zalaczniki wysylanych wiadomosci"
echo ".... * Dodaj podpis cyfrowy do wysylanych wiadomosci"
echo "...."
echo ".... w Thunderbird 91, najpierw trzeba dodac .p12 w Menadzerze"
echo ".... certyfikatow -- Uzytkownik -- Importuj, nastepnie trzeba wejsc"
echo ".... w zakladke 'Organy certyfikacji', wybrac swoja nazwe, kliknac"
echo ".... 'Edytuj ustawienia zaufania' i zaznaczyc 'certyfikat identyfikuje"
echo ".... uzytkownikow poczty'; nastepnie wybrac certyfikaty S/MIME w menu"
echo ".... Szyfrowanie 'end-to-end' i zaznaczyc 'Domyslnie dodawaj moj"
echo ".... podpis cyfrowy' i 'Domyslnie wymagaj szyfrowania'"
echo "...."
echo ".... Kleopatra/gpgsm 2.2.27 -- Najlepiej zrobic to przez cmd:"
echo ".... gpgsm -v --import $klucz_do_uzytku_wewnetrznego_nazwa"
echo ".... w Kleopatrze certyfikat wyswietli sie w 'Certyfikaty X509'"
echo "...."
echo "...."
echo "...."
echo "....      pub/$klucz_publiczny"
echo "....      Klucz publiczny -- eksport do innych osob"
echo "....      pub/$klucz_publiczny_th1 -- [Thunderbird]"
echo "....      pub/$klucz_publiczny_th2 -- [Thunderbird]"
echo "...."
echo ".... przeslij go klientom, znajomym. Musza zaimportowac go w swoich"
echo ".... programach. Porownajcie odciski klucza z pliku pub/$fingerprint"
echo ".... kazdy znak w tym odcisku ma znaczenie. Programy wyciagaja skrot"
echo ".... na bazie wygenerowanego klucza. Jesli klucz jest podrobiony,"
echo ".... wyswietlony zostanie INNY odcisk (skrot) od tego z pliku"
echo ".... pub/$fingerprint"
echo "...."
echo ".... MS Outlook/Windows pokazuje skrot SHA-1"
echo ".... Mozilla SHA-1 i SHA-256"
echo ".... Kleopatra SHA-1"
echo "...."
echo ".... W Windows/Office importuj plik pub/$klucz_publiczny. 'Zainstaluj"
echo ".... certyfikat'."
echo "...."
echo ".... W Kleopatra importuj plik pub/$klucz_publiczny."
echo "...."
echo ".... W Thunderbird w 'Menadzerze certyfikatow' wybierz zakladke 'Organy"
echo ".... certyfikacji' i importuj plik pub/$klucz_publiczny_th1. Zaznacz"
echo ".... 'Zaufaj temu CA przy identyfikacji uzytkownikow poczty'. Teraz"
echo ".... wejdz w zakladke 'Osoby' i importuj plik"
echo ".... pub/$klucz_publiczny_th2."
echo "...."
echo "...."
echo "...."
echo ".... Jesli zaimportowales $klucz_do_uzytku_wewnetrznego_nazwa na swoim komputerze,"
echo ".... NIE MUSISZ importowac klucza publicznego!"
echo "...."
echo -e "\n"
